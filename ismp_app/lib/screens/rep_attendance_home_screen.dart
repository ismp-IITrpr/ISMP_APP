import 'package:flutter/material.dart';
import '../models/events.dart';
import 'rep_attendance_screen.dart';
import 'rep_access.dart';

class RepAttendanceHomeScreen extends StatelessWidget {
  const RepAttendanceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Rep ka club dhundho
    final repClub = getRepClubName('robotics@iitrpr.ac.in') ?? '';

    // Sirf rep ke club ke sessions
    final clubSessions = eventsData.values
        .expand((e) => e)
        .where((e) =>
    e.type == 'C' &&
        e.title.toLowerCase().contains(repClub.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F13),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Take Attendance',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
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
            child: Text(
              repClub.toUpperCase(),
              style: const TextStyle(
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
        child: clubSessions.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy_outlined,
                size: 64,
                color: Colors.grey.shade700,
              ),
              const SizedBox(height: 16),
              Text(
                'No sessions scheduled yet',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: clubSessions.length,
          itemBuilder: (context, index) {
            final event = clubSessions[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C23),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF4A3AFF).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A3AFF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.groups_outlined,
                      color: Color(0xFF8B78FF),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${event.date} • ${event.time}',
                          style: const TextStyle(
                            color: Color(0xFF8B8B9B),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          event.venue,
                          style: const TextStyle(
                            color: Color(0xFF8B8B9B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Take Attendance button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RepAttendanceScreen(event: event),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A3AFF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF4A3AFF).withOpacity(0.5),
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
                            'Start',
                            style: TextStyle(
                              color: Color(0xFF8B78FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }
}