import 'package:flutter/material.dart';

class AttendanceRecord {
  final String title;
  final String date;
  final String time;
  final String venue;
  final bool isPresent;
  final Color iconColor;

  AttendanceRecord({
    required this.title,
    required this.date,
    required this.time,
    this.venue = '',
    required this.isPresent,
    required this.iconColor,
  });

  Map<String, dynamic> toMap() {
    return {
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
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      venue: map['venue'] ?? '',
      isPresent: map['isPresent'] ?? false,
      iconColor: Color(map['iconColor'] ?? 0xFF4A3AFF),
    );
  }
}
