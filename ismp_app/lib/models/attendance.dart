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

final List<AttendanceRecord> recentSessions = [
  AttendanceRecord(
    title: 'Maths Club Meeting',
    date: '21 May 2024',
    time: '11:00 AM',
    isPresent: true,
    iconColor: const Color(0xFF8B78FF), // Purple
  ),
  AttendanceRecord(
    title: 'Arduino Workshop',
    date: '21 May 2024',
    time: '02:00 PM',
    isPresent: true,
    iconColor: const Color(0xFF2196F3), // Blue
  ),
  AttendanceRecord(
    title: 'Football Practice',
    date: '21 May 2024',
    time: '04:30 PM',
    isPresent: false,
    iconColor: const Color(0xFFFF9800), // Orange
  ),
  AttendanceRecord(
    title: 'Music Club Jamming',
    date: '21 May 2024',
    time: '07:00 PM',
    isPresent: true,
    iconColor: const Color(0xFFE91E63), // Pink
  ),
];