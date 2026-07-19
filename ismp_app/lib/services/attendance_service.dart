import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance.dart';
import '../models/events.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. REPRESENTATIVE: Create a live attendance session
  Future<String> startAttendanceSession(String eventId, String repRollNo) async {
    final sessionId = 'session_${eventId}_$repRollNo';
    final session = AttendanceSession(
      sessionId: sessionId,
      eventId: eventId,
      representativeRollNo: repRollNo,
      status: 'active',
      createdAt: DateTime.now(),
    );

    // Save active session document
    await _db.collection('attendance_sessions').doc(sessionId).set(session.toMap());
    
    // Clear any previous scans in case of a retry
    final scansRef = _db.collection('attendance_sessions').doc(sessionId).collection('scans');
    final querySnapshot = await scansRef.get();
    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }

    return sessionId;
  }

  // 2. STUDENT: Scan QR and send attendance to representative session
  Future<void> scanQR(String sessionId, String studentRollNo, String studentName) async {
    final sessionDoc = await _db.collection('attendance_sessions').doc(sessionId).get();
    if (!sessionDoc.exists) {
      throw Exception("Invalid Session QR code.");
    }
    
    final session = AttendanceSession.fromFirestore(sessionDoc);
    if (session.status != 'active') {
      throw Exception("Attendance session is no longer active.");
    }

    // 1. Verify if they already scanned in this active session
    final scanDoc = await _db
        .collection('attendance_sessions')
        .doc(sessionId)
        .collection('scans')
        .doc(studentRollNo)
        .get();
    if (scanDoc.exists) {
      throw Exception("You have already scanned for this session.");
    }

    // 2. Verify if they already have a persistent attendance marked present for this event
    final eventId = session.eventId.isNotEmpty ? session.eventId : sessionId;
    final persistentDoc = await _db
        .collection('users')
        .doc(studentRollNo)
        .collection('attendance')
        .doc(eventId)
        .get();
    if (persistentDoc.exists) {
      final data = persistentDoc.data();
      if (data != null && data['isPresent'] == true) {
        throw Exception("You have already marked attendance for this event.");
      }
    }

    // Write scan document under this active session's subcollection
    final scan = AttendanceScan(
      rollNo: studentRollNo,
      name: studentName,
      scannedAt: DateTime.now(),
      status: 'scanned',
    );

    await _db
        .collection('attendance_sessions')
        .doc(sessionId)
        .collection('scans')
        .doc(studentRollNo)
        .set(scan.toMap());
  }

  // 3. REPRESENTATIVE: Real-time stream of student scans
  Stream<List<AttendanceScan>> streamScannedStudents(String sessionId) {
    return _db
        .collection('attendance_sessions')
        .doc(sessionId)
        .collection('scans')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendanceScan.fromFirestore(doc))
          // Filter out students who were removed by representative
          .where((scan) => scan.status == 'scanned')
          .toList();
    });
  }

  // 4. REPRESENTATIVE: Manually add student (e.g. if camera/QR scan failed)
  Future<void> manuallyAddStudent(String sessionId, String studentRollNo, String studentName) async {
    final scan = AttendanceScan(
      rollNo: studentRollNo,
      name: studentName,
      scannedAt: DateTime.now(),
      status: 'scanned',
    );

    await _db
        .collection('attendance_sessions')
        .doc(sessionId)
        .collection('scans')
        .doc(studentRollNo)
        .set(scan.toMap());
  }

  // 5. REPRESENTATIVE: Manually remove student (soft delete or status update)
  Future<void> removeStudentFromSession(String sessionId, String studentRollNo) async {
    // We update status to 'removed' so they vanish from the stream
    await _db
        .collection('attendance_sessions')
        .doc(sessionId)
        .collection('scans')
        .doc(studentRollNo)
        .update({'status': 'removed'});
  }

  // 6. REPRESENTATIVE: Submit final list of roll numbers to Backend & Mark Present
  Future<void> submitFinalAttendance({
    required String sessionId,
    required String eventId,
    required String eventType,
    required List<String> presentRollNos,
  }) async {
    // Fetch event details to populate title, date, time, venue, iconColor in the student's record
    EventModel? event;
    try {
      final eventDoc = await _db.collection('events').doc(eventId).get();
      if (eventDoc.exists) {
        event = EventModel.fromMap(eventDoc.data()!, eventDoc.id);
      }
    } catch (e) {
      debugPrint("Error fetching event details: $e");
    }

    final batch = _db.batch();

    // Loop through each present roll number and mark present in users/{rollNo}/attendance/{eventId}
    for (String rollNo in presentRollNos) {
      final docRef = _db
          .collection('users')
          .doc(rollNo)
          .collection('attendance')
          .doc(eventId);
      
      final record = AttendanceRecord(
        eventId: eventId,
        eventType: eventType,
        title: event?.title ?? '',
        club: event?.club ?? '',
        date: event?.date ?? '',
        time: event?.time ?? '',
        venue: event?.venue ?? '',
        isPresent: true,
        iconColor: event?.dotColor ?? const Color(0xFFD9278D),
        markedAt: DateTime.now(),
      );

      batch.set(docRef, record.toMap());

      // Generate a notification document for the student
      final notifRef = _db.collection('notifications').doc();
      final notificationData = {
        'userRollNo': rollNo,
        'title': 'Attendance Marked',
        'description': 'Your attendance for the session "${event?.title ?? 'Mentoring'}" has been marked present.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'iconType': 'attendance',
      };
      batch.set(notifRef, notificationData);
    }

    // Set the status of the session to 'submitted'
    final sessionRef = _db.collection('attendance_sessions').doc(sessionId);
    batch.update(sessionRef, {'status': 'submitted'});

    await batch.commit();
  }

  // 7. STUDENT: Stream single student's attendance records to display on their screens
  Stream<List<AttendanceRecord>> streamStudentAttendance(String studentRollNo) {
    return _db
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
}
