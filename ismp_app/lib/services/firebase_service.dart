import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import '../models/blog.dart';
import '../models/events.dart';
import '../models/attendance.dart';
import '../models/moment.dart';
import '../models/profile_data.dart';
import '../models/mock_data/blog_mock.dart';
import '../models/mock_data/events_mock.dart';
import '../models/mock_data/attendance_mock.dart';
import '../models/mock_data/moments_mock.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  FirebaseService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _mockEmail;
  MentorProfile? _cachedMentor;

  /// The current user's mentor, loaded after sign-in.
  MentorProfile? get mentor => _cachedMentor;

  /// Fetches and caches the mentor for the current student.
  Future<void> loadMentor() async {
    try {
      final rollNo = currentStudentRollNo;
      final userDoc = await _firestore.collection('users').doc(rollNo).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final mentorRollNo = data['mentorRollNo'] ?? '2024MEB1358';
        final mentorDoc = await _firestore.collection('mentors').doc(mentorRollNo).get();
        if (mentorDoc.exists) {
          _cachedMentor = MentorProfile.fromFirestore(mentorDoc);
        }
      }
    } catch (e) {
      debugPrint('Error loading mentor: $e');
    }
  }

  // Get current user email (checks mock email first for testing)
  String? get currentUserEmail => _mockEmail ?? _auth.currentUser?.email;

  // Google Sign-In with Batch 2026/Fresher and Rep restriction
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
        final isRep = isClubRep(email);
        final isStudent = isAllowedStudent(email);

        if (isRep || isStudent) {
          _mockEmail = null; // Clear mock on successful Google Sign-in
          
          if (isStudent && email != null) {
            // Extract roll number (e.g. 2026CSB1123)
            final rollNo = email.split('@')[0].toUpperCase();
            final userDoc = await _firestore.collection('users').doc(rollNo).get();
            if (!userDoc.exists) {
              debugPrint('Auto-creating student profile document for $rollNo in Firestore...');
              await _firestore.collection('users').doc(rollNo).set({
                'name': user.displayName ?? 'Rohan Sharma',
                'degree': 'B.Tech',
                'branch': 'Computer Science & Engineering',
                'groupNo': 7,
                'stickersCollected': 12,
                'profileUrl': user.photoURL ?? '',
                'mentorRollNo': '2024MEB1358', // Default mentor Kanika
              });
            }
            // Cache the mentor for quick access across screens
            await loadMentor();
          }
          
          return user;
        } else {
          // If domain doesn't match or unauthorized, sign out immediately and throw an error
          await signOut();
          throw FirebaseAuthException(
            code: 'invalid-email-domain',
            message: 'Access Denied: You are not authorized to access this app.',
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error during Google Sign-in: $e');
      rethrow;
    }
  }

  // Email and password login helper with fallback for dummy tester account
  Future<User?> signInWithEmail(String email, String password) async {
    final lowerEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    try {
      // First try standard Firebase Auth sign-in
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: lowerEmail,
        password: cleanPassword,
      );
      _mockEmail = null;
      return userCredential.user;
    } catch (e) {
      debugPrint('Firebase email login failed: $e');
      
      // Fallback bypass for the dummy testing account
      if (lowerEmail == 'repaccess@gmail.com' && cleanPassword == '12345678') {
        debugPrint('Using mock bypass for tester account repaccess@gmail.com');
        _mockEmail = 'repaccess@gmail.com';
        
        // If not authenticated in firebase, sign in anonymously to obtain a valid Firebase session
        if (_auth.currentUser == null) {
          try {
            await _auth.signInAnonymously();
          } catch (anonError) {
            debugPrint('Failed anonymous fallback sign-in: $anonError');
          }
        }
        return _auth.currentUser;
      }
      rethrow;
    }
  }

  // Sign out helper
  Future<void> signOut() async {
    _mockEmail = null;
    _cachedMentor = null;
    await _auth.signOut();
    try {
      await GoogleSignIn(
        clientId: '231730406983-ivqk4ir349scpola2l866t9t4pth22kl.apps.googleusercontent.com',
      ).signOut();
    } catch (_) {}
  }

  // Get current user helper
  User? get currentUser => _auth.currentUser;

  // Get current student's roll number
  String get currentStudentRollNo {
    final email = currentUserEmail;
    if (email != null && email.contains('@')) {
      return email.split('@')[0].toUpperCase();
    }
    return '24CS1001';
  }


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

      // 4. Seed Moments if empty
      final momentsSnapshot = await _firestore.collection('moments').limit(1).get();
      if (momentsSnapshot.docs.isEmpty) {
        debugPrint('Seeding moments collection...');
        for (var moment in mockMoments) {
          await _firestore.collection('moments').doc(moment.id).set(moment.toMap());
        }
      }

      // 5. Seed default mentor if not exists
      final mentorDoc = await _firestore.collection('mentors').doc('2024MEB1358').get();
      if (!mentorDoc.exists) {
        debugPrint('Seeding default mentor Kanika into Firestore...');
        await _firestore.collection('mentors').doc('2024MEB1358').set({
          'name': 'Kanika',
          'contactNo': '+91 8817929545',
          'profileUrl': 'img/2026/Kanika.jpg',
        });
      }

      debugPrint('Database seeding checked successfully.');
    } catch (e) {
      debugPrint('Error seeding database: $e');
    }
  }

  // Allowed batch of 2025 emails for fresher access
  static const Set<String> _allowed2025Emails = {
    '2025csb1191@iitrpr.ac.in',
    '2025csb1196@iitrpr.ac.in',
    '2025csb1199@iitrpr.ac.in',
    '2025icb1449@iitrpr.ac.in',
    '2025chb1137@iitrpr.ac.in',
    '2025eeb1319@iitrpr.ac.in',
    '2025csb1251@iitrpr.ac.in',
    '2025csb1215@iitrpr.ac.in',
    '2025csb1188@iitrpr.ac.in',
    '2025aib1078@iitrpr.ac.in',
  };

  /// Returns true if the email matches the fresher constraints
  bool isAllowedStudent(String? email) {
    if (email == null) return false;
    final lower = email.trim().toLowerCase();
    if (lower.startsWith('2026') && lower.endsWith('@iitrpr.ac.in')) {
      return true;
    }
    return _allowed2025Emails.contains(lower);
  }

  /// Maps authorized club rep emails to their club name.
  static const Map<String, String> _repEmailToClub = {
    'act-sports-athletics1@iitrpr.ac.in': 'Athletics Club',
    'undekha@iitrpr.ac.in': 'UNDEKHA',
    'act-sports-chess1@iitrpr.ac.in': 'Chess Club',
    'enarrators@iitrpr.ac.in': 'The Enarrators',
    'fincom@iitrpr.ac.in': 'FINCOM',
    'act-sports-cricket1@iitrpr.ac.in': 'Cricket Club',
    'cimclub@iitrpr.ac.in': 'Cim',
    'act-sports-basketball1@iitrpr.ac.in': 'Basketball Club',
    'automotiveclub@iitrpr.ac.in': 'Automotive Club',
    'codingclub@iitrpr.ac.in': 'Coding Club',
    'act-sports-badminton1@iitrpr.ac.in': 'Badminton Club',
    'club.iotacluster@iitrpr.ac.in': 'iota Cluster',
    'danceclub@iitrpr.ac.in': "The D'Cypher",
    'act-sports-volley1@iitrpr.ac.in': 'Volley Club',
    'alpha@iitrpr.ac.in': 'Alpha Production',
    'monochromeclub@iitrpr.ac.in': 'Monochrome',
    'aeromodelling@iitrpr.ac.in': 'Aeromodelling Club',
    'movie.club@iitrpr.ac.in': 'Filmski',
    'sa.esportz@iitrpr.ac.in': 'ESportZ Club',
    'alfaaz@iitrpr.ac.in': 'Alfaaz',
    'act-sports-hockey1@iitrpr.ac.in': 'Hockey Club',
    'robotics@iitrpr.ac.in': 'Robotics Club',
    'act-sports-tabletennis1@iitrpr.ac.in': 'Tabletennis Club',
    'act-sports-lawntennis1@iitrpr.ac.in': 'Lawntennis Club',
    'act-cultural-epicure@iitrpr.ac.in': 'Culinary Club',
    'zenithclub@iitrpr.ac.in': 'Zenith',
    'softcom@iitrpr.ac.in': 'SoftCom',
    'act-sports-weightlifting1@iitrpr.ac.in': 'Weightlifting Club',
    'act-sports-football1@iitrpr.ac.in': 'Football Club',
    'panache@iitrpr.ac.in': 'Panache',
    'enigma@iitrpr.ac.in': 'Enigma',
    'repaccess@gmail.com': 'Test Club',
    'alankar@iitrpr.ac.in': 'Alankar',
    'arturo@iitrpr.ac.in': 'Arturo',
    'debsoc@iitrpr.ac.in': 'Debsoc',
    'mun@iitrpr.ac.in': 'MuN',
    'fineartsclub@iitrpr.ac.in': 'Vibgyor',
  };

  /// Returns true if the given email belongs to an authorized club rep.
  bool isClubRep(String? email) {
    if (email == null) return false;
    return _repEmailToClub.containsKey(email.trim().toLowerCase());
  }

  /// Returns the club name for a given rep email.
  String getClubForEmail(String? email) {
    if (email == null || email.isEmpty) return 'Robotics';
    return _repEmailToClub[email.trim().toLowerCase()] ?? 'Robotics';
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

  /// Streams the session document.
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamSession(String sessionId) {
    return _firestore.collection('attendance_sessions').doc(sessionId).snapshots();
  }

  /// Streams the list of scans (marked present students) for a session.
  Stream<List<Map<String, dynamic>>> streamSessionScansList(String sessionId) {
    return _firestore
        .collection('attendance_sessions')
        .doc(sessionId)
        .collection('scans')
        .orderBy('scannedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['studentUid'] = doc.id;
              return data;
            }).toList());
  }

  /// Manually marks a student as present in the database session.
  Future<void> addManualMark({
    required String sessionId,
    required String name,
    required String rollNo,
  }) async {
    final scanRef = _firestore
        .collection('attendance_sessions')
        .doc(sessionId)
        .collection('scans')
        .doc(rollNo);
    await scanRef.set({
      'name': name,
      'email': '$rollNo@iitrpr.ac.in',
      'scannedAt': FieldValue.serverTimestamp(),
    });
    // Increment the scanCount
    await _firestore.collection('attendance_sessions').doc(sessionId).update({
      'scanCount': FieldValue.increment(1),
    });
  }

  /// Removes a student scan from the session.
  Future<void> removeScan(String sessionId, String studentUid) async {
    await _firestore
        .collection('attendance_sessions')
        .doc(sessionId)
        .collection('scans')
        .doc(studentUid)
        .delete();
    // Decrement the scanCount
    await _firestore.collection('attendance_sessions').doc(sessionId).update({
      'scanCount': FieldValue.increment(-1),
    });
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
    required String startTime,
    required String endTime,
    required String venue,
    required String description,
    required int day,
    required String targetAudience,
    String type = 'E',
    String club = '',
  }) async {
    final color = type == 'C' ? const Color(0xFF8B78FF) : const Color(0xFFB0C4DE);
    await _firestore.collection('events').add({
      'title': title,
      'date': date,
      'time': '$startTime - $endTime',
      'startTime': startTime,
      'endTime': endTime,
      'venue': venue,
      'description': description,
      'type': type,
      'club': club,
      'day': day,
      'targetAudience': targetAudience,
      'groupNo': targetAudience,
      'dotColor': color.toARGB32(),
    });
  }

  /// Updates an existing event in the events collection.
  Future<void> updateEvent({
    required String eventId,
    required String title,
    required String date,
    required String startTime,
    required String endTime,
    required String venue,
    required String description,
    required int day,
    required String targetAudience,
  }) async {
    await _firestore.collection('events').doc(eventId).update({
      'title': title,
      'date': date,
      'time': '$startTime - $endTime',
      'startTime': startTime,
      'endTime': endTime,
      'venue': venue,
      'description': description,
      'day': day,
      'targetAudience': targetAudience,
      'groupNo': targetAudience,
    });
  }

  /// Deletes an event from the events collection.
  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
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

  /// Streams all club sessions (type 'C') for all clubs.
  Stream<List<EventModel>> streamAllClubSessions() {
    return _firestore
        .collection('events')
        .where('type', isEqualTo: 'C')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return EventModel.fromMap(doc.data(), doc.id);
            }).toList());
  }

  /// Deletes old test events created in previous testing runs.
  Future<void> deleteOldEvents() async {
    try {
      final snapshot = await _firestore.collection('events').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final club = (data['club'] ?? '').toString().toLowerCase();
        final title = (data['title'] ?? '').toString().toLowerCase();
        if (club.contains('test') || 
            club.contains('gupta') || 
            club.contains('unknown') || 
            title.contains('test') || 
            club.isEmpty) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      // Ignore errors silently in prod
    }
  }

  /// Streams moments from backend.
  Stream<List<MomentModel>> streamMoments() {
    return _firestore.collection('moments').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => MomentModel.fromMap(doc.data(), doc.id)).toList());
  }

  /// Combined stream of target events and user's marked attendance (to compute Present/Absent status)
  Stream<List<AttendanceRecord>> streamCombinedStudentAttendance(String studentRollNo, int studentGroupNo) {
    StreamController<List<AttendanceRecord>> controller = StreamController();
    
    StreamSubscription? sub1;
    StreamSubscription? sub2;
    
    List<EventModel> latestEvents = [];
    List<AttendanceRecord> latestRecords = [];
    
    void update() {
      if (controller.isClosed) return;
      List<AttendanceRecord> combined = [];
      
      for (var event in latestEvents) {
        // Only show club sessions (type 'C') that match student's group
        if (event.type == 'C') {
          final target = event.targetAudience.toLowerCase();
          final containsAll = target.contains('all') || target.contains('general') || target.isEmpty;
          final containsGroup = target.contains(studentGroupNo.toString());
          if (!containsAll && !containsGroup) {
            continue;
          }
        }
        
        final matchingRecord = latestRecords.firstWhere(
          (r) => r.eventId == event.id,
          orElse: () => AttendanceRecord(
            eventId: event.id,
            eventType: event.type,
            title: event.title,
            date: event.date,
            time: event.time,
            venue: event.venue,
            isPresent: false, // Default status if not marked
            iconColor: event.dotColor,
          ),
        );
        combined.add(matchingRecord);
      }
      
      controller.add(combined);
    }
    
    sub1 = _firestore.collection('events').snapshots().listen((snapshot) {
      latestEvents = snapshot.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList();
      update();
    }, onError: controller.addError);
    
    sub2 = _firestore
        .collection('users')
        .doc(studentRollNo)
        .collection('attendance')
        .snapshots()
        .listen((snapshot) {
      latestRecords = snapshot.docs.map((doc) => AttendanceRecord.fromFirestore(doc)).toList();
      update();
    }, onError: controller.addError);
    
    controller.onCancel = () {
      sub1?.cancel();
      sub2?.cancel();
    };
    
    return controller.stream;
  }
}

