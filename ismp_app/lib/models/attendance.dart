class AttendanceRecord {
  final String eventId;
  final String eventType;
  final bool isPresent;

  AttendanceRecord({
    required this.eventId,
    required this.eventType,
    required this.isPresent,
  });
}

// Dummy historical data linked strictly to Club Session IDs in events.dart
final List<AttendanceRecord> recentSessions = [
  AttendanceRecord(
    eventId: 'C_math_1',
    eventType: 'C',
    isPresent: true,
  ),
  AttendanceRecord(
    eventId: 'C_ard_1',
    eventType: 'C',
    isPresent: true,
  ),
  AttendanceRecord(
    eventId: 'C_fb_1',
    eventType: 'C',
    isPresent: false,
  ),
  AttendanceRecord(
    eventId: 'C_music_1',
    eventType: 'C',
    isPresent: true,
  ),
];