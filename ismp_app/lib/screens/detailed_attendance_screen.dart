import 'package:flutter/material.dart';

class DetailedAttendanceScreen extends StatelessWidget {
  const DetailedAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        title: const Text('Detailed Attendance'),
        backgroundColor: const Color(0xFF0F0F13),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Club Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track your attendance for each club. More sessions will unlock as the semester progresses!',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              // Placeholder for the future "Trophy Collection" UI
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 80,
                        color: const Color(0xFF4A3AFF).withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Trophy boards coming soon...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
