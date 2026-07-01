import 'package:flutter/material.dart';

class AttendanceRecord {
  final String eventId;
  final String eventType;
  final String title;
  final String date;
  final String time;
  final String venue;
  final bool isPresent;
  final Color iconColor;

  AttendanceRecord({
    this.eventId = '',
    this.eventType = '',
    required this.title,
    required this.date,
    required this.time,
    this.venue = '',
    required this.isPresent,
    required this.iconColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventType': eventType,
      'title': title,
      'date': date,
      'time': time,
      'venue': venue,
      'isPresent': isPresent,
      'iconColor': iconColor.toARGB32(),
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      eventId: map['eventId'] ?? '',
      eventType: map['eventType'] ?? '',
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      venue: map['venue'] ?? '',
      isPresent: map['isPresent'] ?? false,
      iconColor: Color(map['iconColor'] ?? 0xFF4A3AFF),
    );
  }
}
