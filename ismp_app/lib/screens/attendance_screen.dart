import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance.dart';
import '../models/events.dart';
import '../services/firebase_service.dart';
import '../services/database_service.dart';
import '../models/profile_data.dart';
import 'student_scanner_screen.dart';
import 'detailed_attendance_screen.dart';
import 'reps/live_attendance_screen.dart';
import '../theme/app_theme.dart';

class AttendanceScreen extends StatefulWidget {
  final bool isRep;
  final String repClub;

  const AttendanceScreen({
    super.key,
    this.isRep = false,
    this.repClub = '',
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final String currentStudentId = "student_123"; // Mock student ID

  @override
  void initState() {
    super.initState();
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StudentScannerScreen(studentId: currentStudentId)),
    ).then((_) {
      // Refresh the screen when returning from the scanner
      setState(() {}); 
    });
  }



  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildResultDialog(
        isSuccess: true,
        icon: Icons.check_circle_outline,
        iconColor: AppColors.primary,
        title: 'Success!',
        message: 'Your attendance has been\nmarked successfully.',
        buttonText: 'Great!',
      ),
    );
  }

  void _showFailedDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildResultDialog(
        isSuccess: false,
        icon: Icons.cancel_outlined,
        iconColor: AppColors.error,
        title: 'Failed!',
        message: 'Unable to mark attendance.\nPlease try again.',
        buttonText: 'Try Again',
      ),
    );
  }

  Widget _buildResultDialog({
    required bool isSuccess,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String buttonText,
  }) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Icon(
              icon,
              size: 80,
              color: iconColor,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.isRep ? _buildRepView(context) : _buildStudentView(context);
  }

  Widget _buildRepView(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Take Attendance',
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
          if (widget.repClub.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  widget.repClub.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
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
        child: StreamBuilder<List<EventModel>>(
          stream: FirebaseService.instance.streamEventsForClub(widget.repClub),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error)));
            }

            final events = snapshot.data ?? [];
            if (events.isEmpty) {
              return const Center(
                child: Text(
                  'No upcoming club sessions to take attendance for.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(24.0),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                              '${event.date} • ${event.time}\n${event.venue}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // 1. Show loading or just start session
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
                        icon: const Icon(Icons.qr_code_scanner, size: 16, color: AppColors.primary),
                        label: const Text(
                          'Start',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },

            );
          },
        ),
      ),
    );
  }

  Widget _buildStudentView(BuildContext context) {
    final String rollNo = FirebaseService.instance.currentStudentRollNo;
    return FutureBuilder<UserProfile?>(
      future: DatabaseService().getUserProfile(rollNo),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;
        final int groupNo = profile?.groupNo ?? 7;

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'Attendance',
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
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                onPressed: _openScanner,
                tooltip: 'Scan QR Code',
              ),
            ],
          ),
          body: SafeArea(
            child: FutureBuilder<List<EventModel>>(
              future: DatabaseService().getPersistentAllEvents(),
              builder: (context, eventsSnapshot) {
                if (eventsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (eventsSnapshot.hasError) {
                  return Center(child: Text('Error: ${eventsSnapshot.error}', style: const TextStyle(color: AppColors.error)));
                }

                final allEvents = eventsSnapshot.data ?? [];

                return StreamBuilder<List<AttendanceRecord>>(
                  stream: FirebaseService.instance.streamStudentAttendance(rollNo),
                  builder: (context, attendanceSnapshot) {
                    if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }
                    if (attendanceSnapshot.hasError) {
                      return Center(child: Text('Error: ${attendanceSnapshot.error}', style: const TextStyle(color: AppColors.error)));
                    }

                    final studentRecords = attendanceSnapshot.data ?? [];

                    // Combine persistent events list with live marked student records (filtered by student's target group)
                    List<AttendanceRecord> records = [];
                    final studentDegree = profile?.degree ?? 'B.Tech';
                    for (var event in allEvents) {
                      if (event.isStudentTargeted(studentDegree, groupNo)) {
                        final hasRecord = studentRecords.any((r) => r.eventId == event.id);
                        if (hasRecord) {
                          final matchingRecord = studentRecords.firstWhere((r) => r.eventId == event.id);
                          records.add(matchingRecord);
                        } else {
                          if (event.isCompleted) {
                            records.add(AttendanceRecord(
                              eventId: event.id,
                              eventType: event.type,
                              title: event.title,
                              club: event.club,
                              date: event.date,
                              time: event.time,
                              venue: event.venue,
                              isPresent: false,
                              iconColor: event.dotColor,
                            ));
                          }
                        }
                      }
                    }

                    final totalCount = records.length;
                    final presentCount = records.where((r) => r.isPresent).length;
                    final absentCount = totalCount - presentCount;
                    final attendancePercentage = totalCount == 0 ? 0.0 : (presentCount / totalCount);
                    final attendancePercentageString = '${(attendancePercentage * 100).toInt()}%';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // Top Stats Card
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: AppTheme.statCardGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.bar_chart,
                                        color: AppColors.secondaryAccent,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text(
                                      'Attendance Overview',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem('Total', totalCount.toString(), Colors.white),
                                _buildStatItem('Present', presentCount.toString(), Colors.white),
                                _buildStatItem('Absent', absentCount.toString(), Colors.white),
                              ],
                            ),
                            const SizedBox(height: 32),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: LinearProgressIndicator(
                                value: attendancePercentage,
                                backgroundColor: AppColors.background,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                minHeight: 10,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Overall attendance',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    attendancePercentageString,
                                    style: const TextStyle(
                                      color: AppColors.secondaryAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const DetailedAttendanceScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.dashboard_customize_outlined, size: 18, color: AppColors.secondaryAccent),
                                label: const Text(
                                  'View Club Trophy Boards',
                                  style: TextStyle(
                                    color: AppColors.secondaryAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Sessions',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                            onPressed: () async {
                              await DatabaseService.clearPersistentAttendanceCache(rollNo);
                              setState(() {}); // Re-builds FutureBuilder
                            },
                            tooltip: 'Refresh Attendance',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: records.isEmpty
                          ? const Center(
                              child: Text(
                                'No attendance records found.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                              itemCount: records.length,
                              itemBuilder: (context, index) {
                                final record = records[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
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
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: record.iconColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.calendar_today,
                                          color: record.iconColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              record.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${record.date} • ${record.time}\n${record.venue}',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                record.isPresent ? 'Present' : 'Absent',
                                                style: TextStyle(
                                                  color: record.isPresent
                                                      ? AppColors.primary
                                                      : AppColors.error,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                record.isPresent
                                                    ? Icons.check_circle_outline
                                                    : Icons.cancel_outlined,
                                                color: record.isPresent
                                                    ? AppColors.primary
                                                    : AppColors.error,
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(duration: 500.ms, delay: (index * 50).ms).slideY(begin: 0.1, curve: Curves.easeOutQuad);
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        ),
          ),
        );
      },
    );
  }
}