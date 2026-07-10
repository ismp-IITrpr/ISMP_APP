import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/events.dart';
import '../services/firebase_service.dart';
import '../screens/reps/live_attendance_screen.dart';

class ActiveSessionButton extends StatefulWidget {
  final EventModel event;
  final String defaultText;
  final IconData defaultIcon;

  const ActiveSessionButton({
    super.key,
    required this.event,
    this.defaultText = 'Start',
    this.defaultIcon = Icons.play_circle_outline,
  });

  @override
  State<ActiveSessionButton> createState() => _ActiveSessionButtonState();
}

class _ActiveSessionButtonState extends State<ActiveSessionButton> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repEmail = FirebaseService.instance.currentUserEmail ?? '';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.instance.getActiveSessionForEvent(widget.event.id, repEmail),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // No active session, show standard START button
          return GestureDetector(
            onTap: () async {
              try {
                final sessionId = await FirebaseService.instance.startAttendanceSession(
                  eventId: widget.event.id,
                  eventName: widget.event.title,
                  venue: widget.event.venue,
                  repEmail: repEmail,
                );
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LiveAttendanceScreen(
                        sessionId: sessionId,
                        eventName: widget.event.title,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4A3AFF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF4A3AFF).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.defaultIcon, size: 14, color: const Color(0xFF8B78FF)),
                  const SizedBox(width: 6),
                  Text(
                    widget.defaultText,
                    style: const TextStyle(
                      color: Color(0xFF8B78FF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Active session exists
        final doc = snapshot.data!.docs.first;
        final sessionId = doc.id;
        final createdAt = doc.data()['createdAt'] as Timestamp?;

        Duration remaining = Duration.zero;
        if (createdAt != null) {
          final elapsed = DateTime.now().difference(createdAt.toDate());
          remaining = const Duration(minutes: 5) - elapsed;
          if (remaining.inSeconds <= 0) {
            remaining = Duration.zero;
          }
        }

        final String timeString =
            "${remaining.inMinutes.toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}";

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveAttendanceScreen(
                  sessionId: sessionId,
                  eventName: widget.event.title,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sensor_door_outlined, size: 14, color: Color(0xFF4CAF50)),
                const SizedBox(width: 6),
                Text(
                  'Enter $timeString',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
