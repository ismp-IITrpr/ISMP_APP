import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import '../models/blog.dart';
import '../models/events.dart';
import '../models/attendance.dart';
import '../models/mock_data/blog_mock.dart';
import '../models/mock_data/events_mock.dart';
import '../models/mock_data/attendance_mock.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  FirebaseService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Google Sign-In with @iitrpr.ac.in domain restriction
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '231730406983-ivqk4ir349scpola2l866t9t4pth22kl.apps.googleusercontent.com',
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final email = user.email;
        if (email != null && email.endsWith('@iitrpr.ac.in')) {
          return user;
        } else {
          // If domain doesn't match, sign out immediately and throw an error
          await signOut();
          throw FirebaseAuthException(
            code: 'invalid-email-domain',
            message: 'Access Denied: Only IIT Ropar email addresses (@iitrpr.ac.in) are allowed.',
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error during Google Sign-in: $e');
      rethrow;
    }
  }

  // Sign out helper
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await GoogleSignIn(
        clientId: '231730406983-ivqk4ir349scpola2l866t9t4pth22kl.apps.googleusercontent.com',
      ).signOut();
    } catch (_) {}
  }

  // Get current user helper
  User? get currentUser => _auth.currentUser;


  // Stream blog posts from Firestore in real-time
  Stream<List<BlogPost>> streamBlogPosts() {
    return _firestore.collection('blogs').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BlogPost.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Stream events for a specific day from Firestore
  Stream<List<EventModel>> streamEventsForDay(int day) {
    return _firestore
        .collection('events')
        .where('day', isEqualTo: day)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromMap(doc.data())).toList();
    });
  }

  // Stream recent attendance records
  Stream<List<AttendanceRecord>> streamRecentAttendance() {
    return _firestore.collection('attendance').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AttendanceRecord.fromMap(doc.data())).toList();
    });
  }

  // Add a new attendance record
  Future<void> addAttendanceRecord(AttendanceRecord record) async {
    await _firestore.collection('attendance').add(record.toMap());
  }

  // Seeds database with default mock data if empty
  Future<void> seedDatabaseIfNeeded() async {
    try {
      // 1. Seed Blogs if empty
      final blogsSnapshot = await _firestore.collection('blogs').limit(1).get();
      if (blogsSnapshot.docs.isEmpty) {
        debugPrint('Seeding blogs collection...');
        for (var post in blogPosts) {
          await _firestore.collection('blogs').doc(post.id).set(post.toMap());
        }
      }

      // 2. Seed Events if empty
      final eventsSnapshot = await _firestore.collection('events').limit(1).get();
      if (eventsSnapshot.docs.isEmpty) {
        debugPrint('Seeding events collection...');
        for (var entry in eventsData.entries) {
          final day = entry.key;
          final list = entry.value;
          for (var event in list) {
            final map = event.toMap();
            map['day'] = day; // Add the day field to group events
            await _firestore.collection('events').add(map);
          }
        }
      }

      // 3. Seed Attendance if empty
      final attendanceSnapshot = await _firestore.collection('attendance').limit(1).get();
      if (attendanceSnapshot.docs.isEmpty) {
        debugPrint('Seeding attendance collection...');
        for (var record in recentSessions) {
          await _firestore.collection('attendance').add(record.toMap());
        }
      }
      debugPrint('Database seeding checked successfully.');
    } catch (e) {
      debugPrint('Error seeding database: $e');
    }
  }

  // ─── CLUB REP LOGIC ────────────────────────────────────────────────

  /// Maps authorized club rep emails to their club name.
  /// Replace these with the real club emails when provided.
  static const Map<String, String> _repEmailToClub = {
    'testclub@iitrpr.ac.in': 'Test Club',
    'codingclub@iitrpr.ac.in': 'Coding Club',
    'roboticsclub@iitrpr.ac.in': 'Robotics Club',
    // Add more club rep emails here
  };

  /// Returns true if the given email belongs to an authorized club rep.
  bool isClubRep(String? email) {
    if (email == null) return false;
    return _repEmailToClub.containsKey(email.toLowerCase());
  }

  /// Returns the club name for a given rep email, or 'Unknown Club' if not found.
  String getClubForEmail(String? email) {
    if (email == null) return 'Unknown Club';
    return _repEmailToClub[email.toLowerCase()] ?? 'Unknown Club';
  }

  // ─── ATTENDANCE SESSION MANAGEMENT ─────────────────────────────────

  /// Creates a new attendance session and returns the generated sessionId.
  Future<String> startAttendanceSession({
    required String eventName,
    required String venue,
    required String repEmail,
  }) async {
    final docRef = await _firestore.collection('attendance_sessions').add({
      'eventName': eventName,
      'venue': venue,
      'repEmail': repEmail,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'scanCount': 0,
    });
    return docRef.id;
  }

  /// Ends (deactivates) a session so the QR code becomes invalid.
  Future<void> endSession(String sessionId) async {
    await _firestore.collection('attendance_sessions').doc(sessionId).update({
      'status': 'ended',
    });
  }

  /// Marks a student as present. Returns true if successful, false if duplicate.
  Future<bool> markStudentAttendance({
    required String sessionId,
    required String studentUid,
    required String studentName,
    required String studentEmail,
  }) async {
    // First check if the session is still active
    final sessionDoc = await _firestore.collection('attendance_sessions').doc(sessionId).get();
    if (!sessionDoc.exists || sessionDoc.data()?['status'] != 'active') {
      return false; // Session expired or doesn't exist
    }

    // Use studentUid as doc ID to prevent duplicates
    final scanRef = _firestore
        .collection('attendance_sessions')
        .doc(sessionId)
        .collection('scans')
        .doc(studentUid);

    final existing = await scanRef.get();
    if (existing.exists) {
      return false; // Already scanned — duplicate prevented
    }

    await scanRef.set({
      'name': studentName,
      'email': studentEmail,
      'scannedAt': FieldValue.serverTimestamp(),
    });

    // Increment the live counter
    await _firestore.collection('attendance_sessions').doc(sessionId).update({
      'scanCount': FieldValue.increment(1),
    });

    return true;
  }

  /// Streams the live scan count for a session.
  Stream<int> streamSessionScanCount(String sessionId) {
    return _firestore
        .collection('attendance_sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) => (doc.data()?['scanCount'] ?? 0) as int);
  }

  /// Streams the session status (active/ended).
  Stream<String> streamSessionStatus(String sessionId) {
    return _firestore
        .collection('attendance_sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) => (doc.data()?['status'] ?? 'ended') as String);
  }

  /// Fetches all scans for a session (for CSV export).
  Future<List<Map<String, dynamic>>> getSessionScans(String sessionId) async {
    final snapshot = await _firestore
        .collection('attendance_sessions')
        .doc(sessionId)
        .collection('scans')
        .orderBy('scannedAt')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['uid'] = doc.id;
      return data;
    }).toList();
  }

  /// Deletes all scan data and the session document itself.
  Future<void> eraseSessionData(String sessionId) async {
    // Delete all scans in the subcollection
    final scans = await _firestore
        .collection('attendance_sessions')
        .doc(sessionId)
        .collection('scans')
        .get();

    final batch = _firestore.batch();
    for (var doc in scans.docs) {
      batch.delete(doc.reference);
    }
    // Delete the session document
    batch.delete(_firestore.collection('attendance_sessions').doc(sessionId));
    await batch.commit();
  }

  /// Streams all sessions created by a specific rep email.
  Stream<List<Map<String, dynamic>>> streamRepSessions(String repEmail) {
    return _firestore
        .collection('attendance_sessions')
        .where('repEmail', isEqualTo: repEmail)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['sessionId'] = doc.id;
              return data;
            }).toList());
  }

  // ─── EVENT POSTING ─────────────────────────────────────────────────

  /// Posts a new event to the events collection.
  Future<void> postEvent({
    required String title,
    required String date,
    required String time,
    required String venue,
    required String description,
    required int day,
    String type = 'E',
    String club = '',
  }) async {
    await _firestore.collection('events').add({
      'title': title,
      'date': date,
      'time': time,
      'venue': venue,
      'description': description,
      'type': type,
      'club': club,
      'day': day,
      'groupNo': <int>[],
      'dotColor': const Color(0xFFB0C4DE).toARGB32(),
    });
  }

  /// Streams events specifically for a given club (type 'C').
  Stream<List<EventModel>> streamEventsForClub(String clubName) {
    if (clubName.isEmpty) return Stream.value([]);
    return _firestore
        .collection('events')
        .where('type', isEqualTo: 'C')
        .where('club', isEqualTo: clubName)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return EventModel.fromMap(doc.data(), doc.id);
            }).toList());
  }
}

