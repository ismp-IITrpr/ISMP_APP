import 'package:cloud_firestore/cloud_firestore.dart';

// Finalized Attendance Record (Stored in student's subcollection)
class AttendanceRecord {
  final String eventId;
  final String eventType;
  final bool isPresent;
  final DateTime? markedAt;

  AttendanceRecord({
    required this.eventId,
    required this.eventType,
    required this.isPresent,
    this.markedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventType': eventType,
      'isPresent': isPresent,
      'markedAt': markedAt != null ? Timestamp.fromDate(markedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceRecord(
      eventId: data['eventId'] ?? '',
      eventType: data['eventType'] ?? '',
      isPresent: data['isPresent'] ?? false,
      markedAt: (data['markedAt'] as Timestamp?)?.toDate(),
    );
  }
}

// Model representing a live attendance scan from a student
class AttendanceScan {
  final String rollNo;
  final String name;
  final DateTime scannedAt;
  final String status; // 'scanned' or 'removed'

  AttendanceScan({
    required this.rollNo,
    required this.name,
    required this.scannedAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'rollNo': rollNo,
      'name': name,
      'scannedAt': Timestamp.fromDate(scannedAt),
      'status': status,
    };
  }

  factory AttendanceScan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceScan(
      rollNo: data['rollNo'] ?? doc.id,
      name: data['name'] ?? '',
      scannedAt: (data['scannedAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'scanned',
    );
  }
}

// Model for the active attendance session started by a Representative
class AttendanceSession {
  final String sessionId;
  final String eventId;
  final String representativeRollNo;
  final String status; // 'active' or 'submitted'
  final DateTime createdAt;

  AttendanceSession({
    required this.sessionId,
    required this.eventId,
    required this.representativeRollNo,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'representativeRollNo': representativeRollNo,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AttendanceSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceSession(
      sessionId: doc.id,
      eventId: data['eventId'] ?? '',
      representativeRollNo: data['representativeRollNo'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
