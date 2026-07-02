import 'package:flutter/material.dart';
import '../models/events.dart';
import '../models/profile_data.dart'; // for dummyUser.rollNo — used for the rep check
import '../screens/rep_access.dart';
import 'rep_attendance_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  int _selectedDay = 1;

  String _getWeekdayString(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final dailyEvents = eventsData[_selectedDay] ?? [];

    // Same login for everyone — no manual role picker. Whether the
    // "Start Attendance" button shows up is decided purely by this check.
    final bool isRep = isCurrentUserRep(dummyUser.rollNo);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        title: const Text(
          'Events',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFF090A0F),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            SizedBox(
              height: 95,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 31,
                itemBuilder: (context, index) {
                  int day = index + 1;
                  DateTime date = DateTime(2026, 8, day);
                  String weekday = _getWeekdayString(date.weekday);
                  bool isSelected = _selectedDay == day;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = day;
                      });
                    },
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF7A6BFF),
                            Color(0xFF4A3AFF),
                            Color(0xFF3320D6),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        )
                            : null,
                        color: isSelected ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: const Color(0xFF4A3AFF).withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            weekday,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            day.toString(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AUG',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.grey.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: dailyEvents.isEmpty
                  ? const Center(
                child: Text(
                  'No events scheduled for this day.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                itemCount: dailyEvents.length,
                itemBuilder: (context, index) {
                  final event = dailyEvents[index];
                  final isLast = index == dailyEvents.length - 1;

                  // Only club sessions ('C') get a "Start Attendance" action.
                  final bool showStartAttendance = isRep && event.type == 'C';

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 24,
                          child: Column(
                            children: [
                              const SizedBox(height: 24),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                    color: event.dotColor,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: event.dotColor.withOpacity(0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: event.dotColor.withOpacity(0.4),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C23),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.time,
                                  style: TextStyle(
                                    color: event.dotColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  event.venue,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildBadge(event.type,
                                        const Color(0xFF3A3A4A)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  event.description,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                if (showStartAttendance) ...[
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                RepAttendanceScreen(event: event),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                                      label: const Text(
                                        'Start Attendance',
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4A3AFF),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}