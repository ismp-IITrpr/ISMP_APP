import 'package:flutter/material.dart';
import '../attendance.dart';

final List<AttendanceRecord> recentSessions = [
  AttendanceRecord(
    eventId: 'C_math_1',
    eventType: 'C',
    title: 'Coding Club',
    date: '21 May 2024',
    time: '11:00 AM',
    isPresent: true,
    iconColor: const Color(0xFF8B78FF), // Purple
  ),
  AttendanceRecord(
    eventId: 'C_ard_1',
    eventType: 'C',
    title: 'Robotics',
    date: '21 May 2024',
    time: '02:00 PM',
    isPresent: true,
    iconColor: const Color(0xFF2196F3), // Blue
  ),
  AttendanceRecord(
    eventId: 'C_fb_1',
    eventType: 'C',
    title: 'Football',
    date: '21 May 2024',
    time: '04:30 PM',
    isPresent: false,
    iconColor: const Color(0xFFFF9800), // Orange
  ),
  AttendanceRecord(
    eventId: 'C_music_1',
    eventType: 'C',
    title: 'Alankar',
    date: '21 May 2024',
    time: '07:00 PM',
    isPresent: true,
    iconColor: const Color(0xFFE91E63), // Pink
  ),
];
