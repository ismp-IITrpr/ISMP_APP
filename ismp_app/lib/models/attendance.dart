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
    required this.venue,
    required this.isPresent,
    required this.iconColor,
  });
}

final List<AttendanceRecord> recentSessions = [
  AttendanceRecord(
    title: 'Maths Club Meeting',
    date: '21 May 2024',
    time: '11:00 AM',
    venue: 'LH-307',
    isPresent: true,
    iconColor: const Color(0xFF8B78FF), // Purple
  ),
  AttendanceRecord(
    title: 'Arduino Workshop',
    date: '21 May 2024',
    time: '02:00 PM',
    venue: 'Workshop Room',
    isPresent: true,
    iconColor: const Color(0xFF2196F3), // Blue
  ),
  AttendanceRecord(
    title: 'Football Practice',
    date: '21 May 2024',
    time: '04:30 PM',
    venue: 'Sports Complex',
    isPresent: false,
    iconColor: const Color(0xFFFF9800), // Orange
  ),
  AttendanceRecord(
    title: 'Music Club Jamming',
    date: '21 May 2024',
    time: '07:00 PM',
    venue: 'Music Room',
    isPresent: true,
    iconColor: const Color(0xFFE91E63), // Pink
  ),
];