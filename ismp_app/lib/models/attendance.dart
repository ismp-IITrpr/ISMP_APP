import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Finalized Attendance Record (Stored in student's subcollection)
class AttendanceRecord {
  final String eventId;
  final String eventType;
  final String title;
  final String club;
  final String date;
  final String time;
  final String venue;
  final bool isPresent;
  final Color iconColor;
  final DateTime? markedAt;

  AttendanceRecord({
    this.eventId = '',
    this.eventType = '',
    this.title = '',
    this.club = '',
    this.date = '',
    this.time = '',
    this.venue = '',
    required this.isPresent,
    this.iconColor = const Color(0xFFD9278D),
    this.markedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventType': eventType,
      'title': title,
      'club': club,
      'date': date,
      'time': time,
      'venue': venue,
      'isPresent': isPresent,
      'iconColor': iconColor.toARGB32(),
      'markedAt': markedAt != null ? Timestamp.fromDate(markedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    final iconColorRaw = map['iconColor'];
    final iconColorValue = (iconColorRaw is int) ? iconColorRaw : 0xFFD9278D;

    final isPresentRaw = map['isPresent'];
    final isPresentValue = (isPresentRaw is bool) ? isPresentRaw : false;

    DateTime? parsedMarkedAt;
    if (map['markedAt'] is Timestamp) {
      parsedMarkedAt = (map['markedAt'] as Timestamp).toDate();
    } else if (map['markedAt'] != null) {
      parsedMarkedAt = DateTime.tryParse(map['markedAt'].toString());
    }

    return AttendanceRecord(
      eventId: map['eventId'] ?? '',
      eventType: map['eventType'] ?? '',
      title: map['title'] ?? '',
      club: map['club'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      venue: map['venue'] ?? '',
      isPresent: isPresentValue,
      iconColor: Color(iconColorValue),
      markedAt: parsedMarkedAt,
    );
  }

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceRecord.fromMap(data);
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
    final scannedAtRaw = data['scannedAt'];
    final scannedAtValue = (scannedAtRaw is Timestamp)
        ? scannedAtRaw.toDate()
        : DateTime.now();
    return AttendanceScan(
      rollNo: data['rollNo'] ?? doc.id,
      name: data['name'] ?? '',
      scannedAt: scannedAtValue,
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
    final createdAtRaw = data['createdAt'];
    final createdAtValue = (createdAtRaw is Timestamp)
        ? createdAtRaw.toDate()
        : DateTime.now();
    return AttendanceSession(
      sessionId: doc.id,
      eventId: data['eventId'] ?? '',
      representativeRollNo: data['representativeRollNo'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: createdAtValue,
    );
  }
}
