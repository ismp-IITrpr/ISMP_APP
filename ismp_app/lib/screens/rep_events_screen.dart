import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/events.dart';
import '../services/firebase_service.dart';
import '../services/database_service.dart';
import 'live_attendance_screen.dart';
import 'rep_access.dart';

class RepEventsScreen extends StatefulWidget {
  const RepEventsScreen({super.key});

  @override
  State<RepEventsScreen> createState() => _RepEventsScreenState();
}

class _RepEventsScreenState extends State<RepEventsScreen> {
  late int _selectedDay;
  late DateTime _startDate;
  final DateTime _eventStartDate = DateTime(2026, 7, 7);

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
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () async {
              await DatabaseService.clearPersistentEventsCache();
              setState(() {});
            },
            tooltip: 'Refresh Schedule',
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4A3AFF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF4A3AFF).withOpacity(0.5),
              ),
            ),
            child: const Text(
              'REP',
              style: TextStyle(
                color: Color(0xFF8B78FF),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
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
            SizedBox(
              height: 95,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 60,
                itemBuilder: (context, index) {
                  DateTime date = _startDate.add(Duration(days: index));
                  int dayIndex = date.difference(_eventStartDate).inDays + 1;

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
              child: FutureBuilder<List<EventModel>>(
                future: DatabaseService().getPersistentEventsForDay(_selectedDay),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF4A3AFF)));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }
                  final dailyEvents = snapshot.data ?? [];
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
                      final isClubSession = event.type == 'C';
                      final repClub = getRepClubName(FirebaseService.instance.currentUserEmail ?? 'robotics@iitrpr.ac.in') ?? '';
                      final isRepClub = isClubSession &&
                          event.club.toLowerCase() == repClub.toLowerCase();

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
                                      ],
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
                                  color: Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(16),
                                  border: isClubSession
                                      ? Border.all(color: const Color(0xFF4A3AFF).withOpacity(0.3), width: 1.5)
                                      : Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
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
                                              ? 'Target: ${event.targetAudience}'
                                              : 'General Event',
                                          const Color(0xFF3A3A4A),
                                        ),
                                        const Spacer(),
                                        if (isRepClub)
                                          GestureDetector(
                                            onTap: () async {
                                              try {
                                                final sessionId = await FirebaseService.instance.startAttendanceSession(
                                                  eventName: event.title,
                                                  venue: event.venue,
                                                  repEmail: FirebaseService.instance.currentUserEmail ?? '',
                                                  eventId: event.id,
                                                );
                                                if (context.mounted) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => LiveAttendanceScreen(
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
                                            child: Container(
                                              padding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF4A3AFF)
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: const Color(0xFF4A3AFF)
                                                      .withOpacity(0.5),
                                                ),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.qr_code_scanner,
                                                    size: 14,
                                                    color: Color(0xFF8B78FF),
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    'Start Attendance',
                                                    style: TextStyle(
                                                      color: Color(0xFF8B78FF),
                                                      fontSize: 12,
                                                      fontWeight:
                                                      FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
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
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      },
                    );
                }
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