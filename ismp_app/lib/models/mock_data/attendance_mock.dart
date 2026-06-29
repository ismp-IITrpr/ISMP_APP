import 'package:flutter/material.dart';
import '../attendance.dart';

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
