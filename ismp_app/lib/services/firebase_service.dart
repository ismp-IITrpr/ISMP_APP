import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/blog.dart';
import '../models/events.dart';
import '../models/attendance.dart';
import '../models/moment.dart';
import '../models/profile_data.dart';
import '../models/mock_data/blog_mock.dart';
import 'database_service.dart';
import '../models/mock_data/moments_mock.dart';
import '../theme/app_theme.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  static const String imgbbApiKey = 'fe76419dd65f668bc2043f4aeec2e26b';
  FirebaseService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
        final mentorDoc = await _firestore
            .collection('mentors')
            .doc(mentorRollNo)
            .get();
        if (mentorDoc.exists) {
          _cachedMentor = MentorProfile.fromFirestore(mentorDoc);
        }
      }
    } catch (e) {
      debugPrint('Error loading mentor: $e');
    }
  }

  // Get current user email
  String? get currentUserEmail => _auth.currentUser?.email;

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();

      if (googleUser == null) {
        return null;
      }

      return await signInWithGoogleAccount(googleUser);
    } catch (e) {
      debugPrint('Error during Google Sign-in: $e');
      rethrow;
    }
  }

  Future<User?> signInWithGoogleAccount(GoogleSignInAccount googleUser) async {
    try {
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        final email = user.email;
        final isRep = isClubRep(email);
        final isStudent = isAllowedStudent(email);

        if (isRep || isStudent) {
          if (isStudent && email != null) {
            // Extract roll number (e.g. 2026CSB1123)
            final rollNo = email.split('@')[0].toUpperCase();
            final userDoc = await _firestore
                .collection('users')
                .doc(rollNo)
                .get();
            final userData = userDoc.data();
            if (!userDoc.exists || userData == null || !userData.containsKey('name')) {
              debugPrint(
                'Auto-creating student profile document for $rollNo in Firestore...',
              );
              await _firestore.collection('users').doc(rollNo).set({
                'name': user.displayName ?? 'Rohan Sharma',
                'degree': 'B.Tech',
                'branch': 'Computer Science & Engineering',
                'groupNo': 7,
                'stickersCollected': 0,
                'profileUrl': user.photoURL ?? '',
                'mentorRollNo': '2024MEB1358', // Default mentor Kanika
              }, SetOptions(merge: true));
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
            message:
                'Access Denied: You are not authorized to access this app.',
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error during Google Sign-in with account: $e');
      rethrow;
    }
  }

  // Email and password login helper with fallback for dummy tester account
  Future<User?> signInWithEmail(String email, String password) async {
    final lowerEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    try {
      // First try standard Firebase Auth sign-in
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(
            email: lowerEmail,
            password: cleanPassword,
          );
      return userCredential.user;
    } catch (e) {
      debugPrint('Firebase email login failed: $e');
      rethrow;
    }
  }

  // Sign out helper
  Future<void> signOut() async {
    _cachedMentor = null;
    DatabaseService.clearCache();
    await DatabaseService.clearBlogsAndMomentsCache();
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
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
    return 'UNAUTHENTICATED';
  }

  // Stream blog posts from Firestore in real-time
  Stream<List<BlogPost>> streamBlogPosts() {
    return _firestore.collection('blogs').limit(50).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BlogPost.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Stream events for a specific day from Firestore
  Stream<List<EventModel>> streamEventsForDay(int day) {
    return _firestore
        .collection('events')
        .where('day', isEqualTo: day)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => EventModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Stream recent attendance records (legacy, used sparingly)
  Stream<List<AttendanceRecord>> streamRecentAttendance() {
    return _firestore.collection('attendance').limit(100).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendanceRecord.fromMap(doc.data()))
          .toList();
    });
  }

  // Add a new attendance record
  Future<void> addAttendanceRecord(AttendanceRecord record) async {
    await _firestore.collection('attendance').add(record.toMap());
  }

  // Seeds database with default mock data if empty
  Future<void> seedDatabaseIfNeeded() async {
    try {
      // 1. Seed & Sync Blogs
      debugPrint('Syncing blogs collection with local mock data...');
      for (var post in blogPosts) {
        await _firestore.collection('blogs').doc(post.id).set(post.toMap());
      }

      // 2. Events are now managed through Firebase console only
      // No seeding from mock data

      // 3. Attendance is now managed through Firebase Firestore only
      // No seeding from mock data

      // 4. Seed Moments if empty
      final momentsSnapshot = await _firestore
          .collection('moments')
          .limit(1)
          .get();
      if (momentsSnapshot.docs.isEmpty) {
        debugPrint('Seeding moments collection...');
        for (var moment in mockMoments) {
          await _firestore
              .collection('moments')
              .doc(moment.id)
              .set(moment.toMap());
        }
      }

      // 5. Seed default mentor if not exists
      final mentorDoc = await _firestore
          .collection('mentors')
          .doc('2024MEB1358')
          .get();
      if (!mentorDoc.exists) {
        debugPrint('Seeding default mentor Kanika into Firestore...');
        await _firestore.collection('mentors').doc('2024MEB1358').set({
          'name': 'Kanika',
          'contactNo': '+91 8817929545',
          'profileUrl': 'img/2026/Kanika.jpg',
        });
      }

      // 6. Seed Clubs if empty
      final clubsSnapshot = await _firestore.collection('clubs').limit(1).get();
      if (clubsSnapshot.docs.isEmpty) {
        debugPrint('Seeding clubs collection...');
        final Map<String, List<Map<String, dynamic>>> boardClubs = {
          'BOLA': [
            {'name': 'Alfaaz', 'image': 'alfaaz.png'},
            {'name': 'Alpha', 'image': 'alpha.png'},
            {'name': 'DebSoc', 'image': 'debsoc.png'},
            {'name': 'Ennarators', 'image': 'enn.png'},
            {'name': 'Enigma', 'image': 'enigma.png'},
            {'name': 'Filmski', 'image': 'filmski.png'},
            {'name': 'MUN', 'image': 'mun.png'},
          ],
          'BOCA': [
            {'name': 'Alankar', 'image': 'alankar.png'},
            {'name': 'Arturo', 'image': 'arturo.png'},
            {'name': "D'Cypher", 'image': 'dcypher.png'},
            {'name': 'Epicure', 'image': 'epicure.png'},
            {'name': 'Panache', 'image': 'panache.png'},
            {'name': 'Undekha', 'image': 'undekha.png'},
            {'name': 'Vibgyor', 'image': 'vibgyor.png'},
          ],
          'BOST': [
            {'name': 'Zenith', 'image': 'zenith.png'},
            {'name': 'E-Sportz', 'image': 'esportz.png'},
            {'name': 'Monochrome', 'image': 'monochrome.png'},
            {'name': 'Robotics', 'image': 'robotics.png'},
            {'name': 'Softcom', 'image': 'softcom.png'},
            {'name': 'Coding Club', 'image': 'coding.png'},
            {'name': 'FinCom', 'image': 'fincom.png'},
            {'name': 'CIM', 'image': 'cim.png'},
            {'name': 'Iota Cluster', 'image': 'iota.png'},
            {'name': 'Automotive', 'image': 'auto.png'},
            {'name': 'Aeromodelling', 'image': 'aero.png'},
          ],
          'BOSA': [
            {'name': 'Athletic', 'image': 'athletics.png'},
            {'name': 'Badminton', 'image': 'badminton.png'},
            {'name': 'Basketball', 'image': 'basketball.png'},
            {'name': 'Chess', 'image': 'chess.png'},
            {'name': 'Cricket', 'image': 'cricket.png'},
            {'name': 'Football', 'image': 'football.png'},
            {'name': 'Hockey', 'image': 'hockey.png'},
            {'name': 'Tennis', 'image': 'tennis.png'},
            {'name': 'Table Tennis', 'image': 'tt.png'},
            {'name': 'Volleyball', 'image': 'volleyball.png'},
            {'name': 'Weightlifting', 'image': 'wieght.png'},
          ],
        };

        final Map<String, String> boardFullNames = {
          'BOSA': 'Board of Sports Activities',
          'BOLA': 'Board of Literary Activities',
          'BOCA': 'Board of Cultural Activities',
          'BOST': 'Board of Science & Technology',
        };

        final batch = _firestore.batch();
        boardClubs.forEach((board, clubsList) {
          final boardName = boardFullNames[board] ?? '';
          for (var club in clubsList) {
            final name = club['name'] as String;
            final image = club['image'] as String;
            final docRef = _firestore.collection('clubs').doc(name);
            batch.set(docRef, {
              'name': name,
              'image': image,
              'board': board,
              'boardName': boardName,
            });
          }
        });
        await batch.commit();
        debugPrint('Seeding clubs collection complete.');
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
    'act-sports-athletics1@iitrpr.ac.in': 'Athletic',
    'undekha@iitrpr.ac.in': 'Undekha',
    'act-sports-chess1@iitrpr.ac.in': 'Chess',
    'enarrators@iitrpr.ac.in': 'Ennarators',
    'fincom@iitrpr.ac.in': 'FinCom',
    'act-sports-cricket1@iitrpr.ac.in': 'Cricket',
    'cimclub@iitrpr.ac.in': 'CIM',
    'act-sports-basketball1@iitrpr.ac.in': 'Basketball',
    'automotiveclub@iitrpr.ac.in': 'Automotive',
    'codingclub@iitrpr.ac.in': 'Coding Club',
    'act-sports-badminton1@iitrpr.ac.in': 'Badminton',
    'club.iotacluster@iitrpr.ac.in': 'Iota Cluster',
    'danceclub@iitrpr.ac.in': "D'Cypher",
    'act-sports-volley1@iitrpr.ac.in': 'Volleyball',
    'alpha@iitrpr.ac.in': 'Alpha',
    'monochromeclub@iitrpr.ac.in': 'Monochrome',
    'aeromodelling@iitrpr.ac.in': 'Aeromodelling',
    'movie.club@iitrpr.ac.in': 'Filmski',
    'sa.esportz@iitrpr.ac.in': 'E-Sportz',
    'alfaaz@iitrpr.ac.in': 'Alfaaz',
    'act-sports-hockey1@iitrpr.ac.in': 'Hockey',
    'robotics@iitrpr.ac.in': 'Robotics',
    'act-sports-tabletennis1@iitrpr.ac.in': 'Table Tennis',
    'act-sports-lawntennis1@iitrpr.ac.in': 'Tennis',
    'act-cultural-epicure@iitrpr.ac.in': 'Epicure',
    'zenithclub@iitrpr.ac.in': 'Zenith',
    'softcom@iitrpr.ac.in': 'Softcom',
    'act-sports-weightlifting1@iitrpr.ac.in': 'Weightlifting',
    'act-sports-football1@iitrpr.ac.in': 'Football',
    'panache@iitrpr.ac.in': 'Panache',
    'enigma@iitrpr.ac.in': 'Enigma',
    'alankar@iitrpr.ac.in': 'Alankar',
    'arturo@iitrpr.ac.in': 'Arturo',
    'debsoc@iitrpr.ac.in': 'DebSoc',
    'mun@iitrpr.ac.in': 'MUN',
    'fineartsclub@iitrpr.ac.in': 'Vibgyor',
    'ismp@iitrpr.ac.in': 'ISMP',
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
  Stream<QuerySnapshot<Map<String, dynamic>>> getActiveSessionForEvent(String eventId, String repEmail) {
    return _firestore.collection('attendance_sessions')
        .where('eventId', isEqualTo: eventId)
        .where('repEmail', isEqualTo: repEmail)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .snapshots();
  }

  /// Creates a new attendance session and returns the generated sessionId.
  Future<String> startAttendanceSession({
    required String eventName,
    required String venue,
    required String repEmail,
    String eventId = '',
  }) async {
    final docRef = await _firestore.collection('attendance_sessions').add({
      'eventName': eventName,
      'venue': venue,
      'repEmail': repEmail,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'scanCount': 0,
      'eventId': eventId,
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
    final sessionDoc = await _firestore
        .collection('attendance_sessions')
        .doc(sessionId)
        .get();
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
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamSession(
    String sessionId,
  ) {
    return _firestore
        .collection('attendance_sessions')
        .doc(sessionId)
        .snapshots();
  }

  /// Streams the list of scans (marked present students) for a session.
  Stream<List<Map<String, dynamic>>> streamSessionScansList(String sessionId) {
    return _firestore
        .collection('attendance_sessions')
        .doc(sessionId)
        .collection('scans')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            data['studentUid'] = doc.id;
            return data;
          }).toList();

          // Sort locally by scannedAt descending, handling null values safely
          list.sort((a, b) {
            final aTime = a['scannedAt'] as Timestamp?;
            final bTime = b['scannedAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return -1; // Local/pending writes first
            if (bTime == null) return 1;
            return bTime.compareTo(aTime);
          });

          return list;
        });
  }

  /// Manually marks a student as present in the database session.
  /// First checks if the student exists in the database.
  Future<void> addManualMark({
    required String sessionId,
    required String name,
    required String rollNo,
  }) async {
    final formattedRollNo = rollNo.trim().toUpperCase();
    final userDoc = await _firestore
        .collection('users')
        .doc(formattedRollNo)
        .get();
    if (!userDoc.exists) {
      throw Exception(
        'Student with Roll No. $formattedRollNo not found in database.',
      );
    }

    // Use student's real name from the DB if available
    final dbName = userDoc.data()?['name'] ?? name;

    // 1. Check if student already has a scan record in the session
    final scanRef = _firestore
        .collection('attendance_sessions')
        .doc(sessionId)
        .collection('scans')
        .doc(formattedRollNo);

    final scanDoc = await scanRef.get();
    if (scanDoc.exists) {
      throw Exception(
        'Student $formattedRollNo is already added to this session.',
      );
    }

    // 2. Fetch session details to check persistent status
    final sessionDoc = await _firestore
        .collection('attendance_sessions')
        .doc(sessionId)
        .get();
    if (!sessionDoc.exists) {
      throw Exception('Attendance session no longer exists.');
    }
    final eventId = sessionDoc.data()?['eventId'] ?? sessionId;

    // 3. Verify if they already have a persistent attendance marked present for this event
    final persistentDoc = await _firestore
        .collection('users')
        .doc(formattedRollNo)
        .collection('attendance')
        .doc(eventId)
        .get();
    if (persistentDoc.exists) {
      final pData = persistentDoc.data();
      if (pData != null && pData['isPresent'] == true) {
        throw Exception(
          'Student $formattedRollNo has already marked attendance for this event.',
        );
      }
    }

    await scanRef.set({
      'name': dbName,
      'email': '$formattedRollNo@iitrpr.ac.in',
      'scannedAt': FieldValue.serverTimestamp(),
    });
    // Increment the scanCount
    await _firestore.collection('attendance_sessions').doc(sessionId).update({
      'scanCount': FieldValue.increment(1),
    });
  }

  /// Submits the final attendance for all scanned students in a session to their persistent records.
  Future<void> submitSessionAttendance(String sessionId) async {
    final sessionDoc = await _firestore
        .collection('attendance_sessions')
        .doc(sessionId)
        .get();
    if (!sessionDoc.exists) return;

    final sessionData = sessionDoc.data()!;
    final eventId = sessionData['eventId'] ?? '';
    final eventName = sessionData['eventName'] ?? '';
    final venue = sessionData['venue'] ?? '';

    EventModel? event;
    if (eventId.isNotEmpty) {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (eventDoc.exists) {
        event = EventModel.fromMap(eventDoc.data()!, eventDoc.id);
      }
    }

    final eventType = event?.type ?? 'E';
    final clubName = event?.club ?? '';
    final date = event?.date ?? '';
    final time = event?.time ?? '';
    final dotColor = event?.dotColor ?? AppColors.primary;

    final scansSnapshot = await _firestore
        .collection('attendance_sessions')
        .doc(sessionId)
        .collection('scans')
        .get();

    final presentRollNos = scansSnapshot.docs
        .map((doc) => doc.id.toUpperCase().trim())
        .toSet();

    // Get targeted students list efficiently instead of fetching the whole users collection
    List<DocumentSnapshot> targetStudents = [];
    final rawAudience = event?.targetAudience.trim() ?? '';
    if (rawAudience.isEmpty || rawAudience.toLowerCase() == 'all' || rawAudience.toLowerCase() == 'all members') {
      final snap = await _firestore.collection('users').get();
      targetStudents = snap.docs;
    } else {
      String degreeLimit = 'All';
      List<int> targetGroups = [];
      if (rawAudience.contains(':')) {
        final parts = rawAudience.split(':');
        degreeLimit = parts[0].trim();
        final groupsPart = parts[1].trim().toLowerCase();
        if (groupsPart != 'all' && groupsPart != 'all members' && groupsPart.isNotEmpty) {
          targetGroups = groupsPart
              .split(RegExp(r'[\s,]+'))
              .map((s) => int.tryParse(s))
              .whereType<int>()
              .toList();
        }
      } else {
        targetGroups = rawAudience
            .split(RegExp(r'[\s,]+'))
            .map((s) => int.tryParse(s))
            .whereType<int>()
            .toList();
      }

      Query q = _firestore.collection('users');
      if (degreeLimit != 'All') {
        q = q.where('degree', isEqualTo: degreeLimit);
      }
      
      if (targetGroups.isNotEmpty) {
        if (targetGroups.length <= 10) {
          q = q.where('groupNo', whereIn: targetGroups);
          final snap = await q.get();
          targetStudents = snap.docs;
        } else {
          final snap = await q.get();
          targetStudents = snap.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return false;
            final gNo = data['groupNo'] is int
                ? data['groupNo'] as int
                : (int.tryParse(data['groupNo']?.toString() ?? '') ?? 7);
            return targetGroups.contains(gNo);
          }).toList();
        }
      } else {
        final snap = await q.get();
        targetStudents = snap.docs;
      }
    }

    WriteBatch batch = _firestore.batch();
    int opCount = 0;

    Future<void> commitBatchIfNeeded() async {
      opCount++;
      if (opCount >= 400) {
        await batch.commit();
        batch = _firestore.batch();
        opCount = 0;
      }
    }

    // 1. Mark present for all scanned students
    for (var doc in scansSnapshot.docs) {
      final rollNo = doc.id.toUpperCase().trim();

      final attendanceRef = _firestore
          .collection('users')
          .doc(rollNo)
          .collection('attendance')
          .doc(eventId.isNotEmpty ? eventId : sessionId);

      final record = AttendanceRecord(
        eventId: eventId.isNotEmpty ? eventId : sessionId,
        eventType: eventType,
        title: eventName,
        club: clubName,
        date: date,
        time: time,
        venue: venue,
        isPresent: true,
        iconColor: dotColor,
        markedAt: DateTime.now(),
      );

      batch.set(attendanceRef, record.toMap());
      await commitBatchIfNeeded();

      // Update stickersCollected if first time attending this club
      if (eventType == 'C' && clubName.isNotEmpty) {
        try {
          final existing = await _firestore
              .collection('users')
              .doc(rollNo)
              .collection('attendance')
              .where('club', isEqualTo: clubName)
              .where('isPresent', isEqualTo: true)
              .limit(1)
              .get();
          if (existing.docs.isEmpty) {
            batch.update(_firestore.collection('users').doc(rollNo), {
              'stickersCollected': FieldValue.increment(1),
            });
            await commitBatchIfNeeded();
          }
        } catch (e) {
          debugPrint('Error updating stickersCollected for $rollNo: $e');
        }
      }

      // Generate notification for present student
      final notifRef = _firestore.collection('notifications').doc();
      batch.set(notifRef, {
        'userRollNo': rollNo,
        'title': 'Attendance Marked',
        'description':
            'Your attendance for the session "$eventName" has been marked present.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'iconType': 'attendance',
      });
      await commitBatchIfNeeded();
    }

    // 2. Mark absent for target audience students who did not scan
    for (var doc in targetStudents) {
      final rollNo = doc.id.toUpperCase().trim();
      if (presentRollNos.contains(rollNo)) continue;

      final attendanceRef = _firestore
          .collection('users')
          .doc(rollNo)
          .collection('attendance')
          .doc(eventId.isNotEmpty ? eventId : sessionId);

      final record = AttendanceRecord(
        eventId: eventId.isNotEmpty ? eventId : sessionId,
        eventType: eventType,
        title: eventName,
        club: clubName,
        date: date,
        time: time,
        venue: venue,
        isPresent: false, // Absent
        iconColor: dotColor,
        markedAt: DateTime.now(),
      );

      batch.set(attendanceRef, record.toMap());
      await commitBatchIfNeeded();

      // Generate notification for absent student
      final notifRef = _firestore.collection('notifications').doc();
      batch.set(notifRef, {
        'userRollNo': rollNo,
        'title': 'Attendance Marked Absent',
        'description': 'You were marked absent for the session "$eventName".',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'iconType': 'attendance',
      });
      await commitBatchIfNeeded();
    }

    if (opCount > 0) {
      await batch.commit();
    }

    // Send push notifications for all affected students (batched via Promise-like pattern)
    try {
      final functions = FirebaseFunctions.instance;
      final allRollNos = presentRollNos.toList();
      for (var doc in targetStudents) {
        final rollNo = doc.id.toUpperCase().trim();
        if (presentRollNos.contains(rollNo)) continue;
        allRollNos.add(rollNo);
      }
      // Send notifications in batches of 10 to avoid timeout
      final batches = <List<String>>[];
      for (var i = 0; i < allRollNos.length; i += 10) {
        batches.add(allRollNos.sublist(i, i + 10 > allRollNos.length ? allRollNos.length : i + 10));
      }
      for (final batch in batches) {
        await Future.wait(batch.map((rollNo) async {
          try {
            await functions.httpsCallable('sendAttendancePush').call({
              'rollNo': rollNo,
              'title': 'Attendance Marked',
              'description': 'Your attendance for "$eventName" has been recorded.',
              'iconType': 'attendance',
              'notificationType': 'attendance',
            });
          } catch (_) {}
        }));
      }
    } catch (e) {
      debugPrint('Push notification error: $e');
    }

    // Mark the event as completed in Firestore
    if (eventId.isNotEmpty) {
      try {
        await _firestore.collection('events').doc(eventId).update({
          'isCompleted': true,
        });
        await _updateEventsMetadata();
      } catch (e) {
        debugPrint('Error marking event $eventId as completed: $e');
      }
    }
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
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['sessionId'] = doc.id;
            return data;
          }).toList(),
        );
  }

  // ─── EVENT POSTING ─────────────────────────────────────────────────

  /// Posts a new event to the events collection.
  Future<void> _updateEventsMetadata() async {
    try {
      await _firestore.collection('metadata').doc('events_state').set({
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating events metadata: $e');
    }
  }

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
    final color = AppTheme.eventDotColor(type);
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
    await _updateEventsMetadata();
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
    await _updateEventsMetadata();
  }

  /// Deletes an event from the events collection.
  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
    await _updateEventsMetadata();
  }

  /// Streams events specifically for a given club (type 'C').
  Stream<List<EventModel>> streamEventsForClub(String clubName) {
    if (clubName.isEmpty) return Stream.value([]);
    return _firestore
        .collection('events')
        .where('type', isEqualTo: 'C')
        .where('club', isEqualTo: clubName)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return EventModel.fromMap(doc.data(), doc.id);
          }).toList(),
        );
  }

  /// Streams all club sessions (type 'C') for all clubs.
  Stream<List<EventModel>> streamAllClubSessions() {
    return _firestore
        .collection('events')
        .where('type', isEqualTo: 'C')
        .limit(500)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            return EventModel.fromMap(doc.data(), doc.id);
          }).toList(),
        );
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
    return _firestore
        .collection('moments')
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MomentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Adds a new moment to the Firestore database.
  Future<void> addMoment(String title, String imageUrl) async {
    try {
      await _firestore.collection('moments').add({
        'title': title,
        'imageUrl': imageUrl,
      });
      await DatabaseService.clearBlogsAndMomentsCache();
    } catch (e) {
      debugPrint('Error adding moment: $e');
      rethrow;
    }
  }

  /// Deletes a moment from the Firestore database.
  Future<void> deleteMoment(String docId) async {
    try {
      await _firestore.collection('moments').doc(docId).delete();
      await DatabaseService.clearBlogsAndMomentsCache();
    } catch (e) {
      debugPrint('Error deleting moment: $e');
      rethrow;
    }
  }

  /// Streams a student's personal attendance records.
  Stream<List<AttendanceRecord>> streamStudentAttendance(String studentRollNo) {
    return _firestore
        .collection('users')
        .doc(studentRollNo)
        .collection('attendance')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AttendanceRecord.fromFirestore(doc))
              .toList();
        });
  }

  /// Fetches student profile suggestions from the users collection matching a roll number prefix.
  Future<List<UserProfile>> getStudentSuggestions(String query) async {
    if (query.trim().isEmpty) return [];
    final upperQuery = query.trim().toUpperCase();
    try {
      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: upperQuery)
          .where(
            FieldPath.documentId,
            isLessThanOrEqualTo: '$upperQuery\uf8ff',
          )
          .limit(5)
          .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching student suggestions: $e');
      return [];
    }
  }

  /// Combined stream of target events and user's marked attendance (to compute Present/Absent status)
  Stream<List<AttendanceRecord>> streamCombinedStudentAttendance(
    String studentRollNo,
    int studentGroupNo,
  ) {
    StreamController<List<AttendanceRecord>> controller = StreamController();

    StreamSubscription? sub1;
    StreamSubscription? sub2;

    List<EventModel> latestEvents = [];
    List<AttendanceRecord> latestRecords = [];

    void update() {
      if (controller.isClosed) return;
      List<AttendanceRecord> combined = [];

      for (var event in latestEvents) {
        final matchingRecord = latestRecords.firstWhere(
          (r) => r.eventId == event.id,
          orElse: () => AttendanceRecord(
            eventId: event.id,
            eventType: event.type,
            title: event.title,
            club: event.club,
            date: event.date,
            time: event.time,
            venue: event.venue,
            isPresent: false,
            iconColor: event.dotColor,
          ),
        );
        combined.add(matchingRecord);
      }

      controller.add(combined);
    }

    sub1 = _firestore.collection('events').limit(500).snapshots().listen((snapshot) {
      latestEvents = snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data(), doc.id))
          .toList();
      update();
    }, onError: controller.addError);

    sub2 = _firestore
        .collection('users')
        .doc(studentRollNo)
        .collection('attendance')
        .snapshots()
        .listen((snapshot) {
          latestRecords = snapshot.docs
              .map((doc) => AttendanceRecord.fromFirestore(doc))
              .toList();
          update();
        }, onError: controller.addError);

    controller.onCancel = () {
      sub1?.cancel();
      sub2?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  /// Resets all testing and attendance data across Firestore and clears local caches
  Future<void> resetTestingData() async {
    if (!kDebugMode) {
      throw UnsupportedError('resetTestingData is disabled in production.');
    }
    debugPrint('Resetting testing data...');

    // 1. Delete all users and their attendance subcollections
    final usersSnapshot = await _firestore.collection('users').get();
    for (var userDoc in usersSnapshot.docs) {
      final rollNo = userDoc.id;
      final attendanceSnapshot = await _firestore
          .collection('users')
          .doc(rollNo)
          .collection('attendance')
          .get();
      for (var doc in attendanceSnapshot.docs) {
        await doc.reference.delete();
      }
      await userDoc.reference.delete();
    }

    // 2. Clear general attendance collection
    final attendanceSnapshot = await _firestore.collection('attendance').get();
    for (var doc in attendanceSnapshot.docs) {
      await doc.reference.delete();
    }

    // 3. Clear attendance sessions and their scans subcollections
    final sessionsSnapshot = await _firestore
        .collection('attendance_sessions')
        .get();
    for (var sessionDoc in sessionsSnapshot.docs) {
      final scansSnapshot = await sessionDoc.reference
          .collection('scans')
          .get();
      for (var doc in scansSnapshot.docs) {
        await doc.reference.delete();
      }
      await sessionDoc.reference.delete();
    }

    // 4. Clear all notifications
    final notificationsSnapshot = await _firestore
        .collection('notifications')
        .get();
    for (var doc in notificationsSnapshot.docs) {
      await doc.reference.delete();
    }

    // 5. Clear events, blogs, moments, clubs, mentors collections completely so they can be re-seeded
    final eventsSnapshot = await _firestore.collection('events').get();
    for (var doc in eventsSnapshot.docs) {
      await doc.reference.delete();
    }

    final blogsSnapshot = await _firestore.collection('blogs').get();
    for (var doc in blogsSnapshot.docs) {
      await doc.reference.delete();
    }

    final momentsSnapshot = await _firestore.collection('moments').get();
    for (var doc in momentsSnapshot.docs) {
      await doc.reference.delete();
    }

    final clubsSnapshot = await _firestore.collection('clubs').get();
    for (var doc in clubsSnapshot.docs) {
      await doc.reference.delete();
    }

    final mentorsSnapshot = await _firestore.collection('mentors').get();
    for (var doc in mentorsSnapshot.docs) {
      await doc.reference.delete();
    }

    // 6. Re-seed default collections
    await seedDatabaseIfNeeded();

    // 7. Clear all local caches
    await DatabaseService.clearPersistentEventsCache();
    await DatabaseService.clearCache();
    await DatabaseService.clearPersistentAttendanceCache(currentStudentRollNo);
    debugPrint('Testing data reset complete.');
  }
}
