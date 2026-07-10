import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/events.dart';
import '../models/profile_data.dart';
import '../services/firebase_service.dart';
import '../services/database_service.dart';
import '../services/rep_access.dart';
import 'reps/rep_attendance_screen.dart';
import 'reps/live_attendance_screen.dart';

class EventsScreen extends StatefulWidget {
  final bool isRep;
  final String repClub;

  const EventsScreen({
    super.key,
    this.isRep = false,
    this.repClub = '',
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late int _selectedDay;
  late DateTime _startDate;
  final DateTime _eventStartDate = DateTime(2026, 7, 7);
  bool _showAllEvents = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
  
    // Hide past dates by starting the scrollbar at today's date
    if (today.isBefore(_eventStartDate)) {
      _startDate = _eventStartDate;
    } else {
      _startDate = today;
    }
    
    // Automatically set default selected day to the real date (or day 1 if event hasn't started)
    _selectedDay = _startDate.difference(_eventStartDate).inDays + 1;
  }

  String _getWeekdayString(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }

  String _getMonthString(int month) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {

    // Same login for everyone — no manual role picker. Whether the
    // "Start Attendance" button shows up is decided purely by this check.
    final bool isRep = widget.isRep;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (widget.isRep)
            Container(
              margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF4A3AFF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF4A3AFF).withValues(alpha: 0.3)),
              ),
              child: const Center(
                child: Text(
                  'REP',
                  style: TextStyle(
                    color: Color(0xFF8B78FF),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            if (!widget.isRep) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _showAllEvents ? 'All Events' : 'Relevant Events',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: _showAllEvents,
                      onChanged: (value) {
                        setState(() {
                          _showAllEvents = value;
                        });
                      },
                      activeColor: const Color(0xFF8B78FF),
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 95,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 60, // Shows a scrollable buffer of 60 days
                itemBuilder: (context, index) {
                  DateTime date = _startDate.add(Duration(days: index));
                  int dayIndex = date.difference(_eventStartDate).inDays + 1; // Backend maps this strictly to Day 1, Day 2, etc.
                  
                  String weekday = _getWeekdayString(date.weekday);
                  String monthName = _getMonthString(date.month);
                  bool isSelected = _selectedDay == dayIndex;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = dayIndex;
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
                            color: const Color(0xFF4A3AFF).withValues(alpha: 0.5),
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
                            date.day.toString(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            monthName,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.9)
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
              child: FutureBuilder<UserProfile?>(
                future: widget.isRep
                    ? Future.value(null)
                    : DatabaseService().getUserProfile(FirebaseService.instance.currentStudentRollNo),
                builder: (context, profileSnapshot) {
                  final profile = profileSnapshot.data;
                  final studentDegree = profile?.degree ?? 'B.Tech';
                  final studentGroupNo = profile?.groupNo ?? 7;

                  return FutureBuilder<List<EventModel>>(
                    future: DatabaseService().getPersistentEventsForDay(_selectedDay),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF4A3AFF)));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                      }

                      final allDailyEvents = snapshot.data ?? [];
                      final dailyEvents = widget.isRep
                          ? allDailyEvents
                          // : allDailyEvents.where((e) => e.isStudentTargeted(studentDegree, studentGroupNo)).toList();
                        : allDailyEvents.where((e) {
                              if (_showAllEvents) {
                                return e.isDegreeTargeted(studentDegree);
                              } else {
                                return e.isStudentTargeted(studentDegree, studentGroupNo);
                              }
                            }).toList();

                      if (dailyEvents.isEmpty) {
                        return const Center(
                          child: Text(
                            'No events scheduled for this day.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    itemCount: dailyEvents.length,
                    itemBuilder: (context, index) {
                        final event = dailyEvents[index];
                        final isLast = index == dailyEvents.length - 1;

                      final bool showStartAttendance = isRep && event.type == 'C'
                          && event.getFormattedAudience() != 'All Members'
                          && (widget.repClub.isEmpty || event.club == widget.repClub);

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
                                            color: event.dotColor.withValues(alpha: 0.4),
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
                                        color: event.dotColor.withValues(alpha: 0.4),
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
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
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
                                        _buildBadge(
                                          event.type == 'C'
                                              ? event.getFormattedAudience()
                                              : 'General Event',
                                          const Color(0xFF3A3A4A),
                                        ),
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
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            try {
                                              final sessionId = await FirebaseService.instance.startAttendanceSession(
                                                eventId: event.id,
                                                eventName: event.title,
                                                venue: event.venue,
                                                repEmail: FirebaseService.instance.currentUserEmail ?? '',
                                              );
                                              if (context.mounted) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => LiveAttendanceScreen(
                                                      sessionId: sessionId,
                                                      eventName: event.title,
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Failed to start session: $e')),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(Icons.qr_code_scanner, size: 16, color: Color(0xFF8B78FF)),
                                          label: const Text(
                                            'Start Attendance',
                                            style: TextStyle(
                                              color: Color(0xFF8B78FF),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF4A3AFF).withValues(alpha: 0.15),
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              side: BorderSide(color: const Color(0xFF4A3AFF).withValues(alpha: 0.3)),
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
                      ).animate().fadeIn(duration: 500.ms, delay: (index * 50).ms).slideY(begin: 0.1, curve: Curves.easeOutQuad);
                      },
                  );
                },
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
