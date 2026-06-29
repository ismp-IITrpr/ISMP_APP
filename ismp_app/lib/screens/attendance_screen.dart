import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../services/firebase_service.dart';
import '../widgets/scanner_viewfinder.dart';
import 'dart:math';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {

  void _openMockScanner() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ScannerViewfinder(
        onCancel: () {
          Navigator.pop(dialogContext);
        },
        onScanComplete: () {
          if (!mounted) return;
          Navigator.pop(dialogContext); // Close scanner viewfinder

          bool isSuccess = Random().nextBool();
          if (isSuccess) {
            final titles = [
              'Coding Contest',
              'AI Seminar Meeting',
              'Robotics Lab Session',
              'IIT Ropar Hackathon'
            ];
            final venues = ['Online', 'LH-307', 'Workshop Room', 'Main Auditorium'];
            final randomIndex = Random().nextInt(4);
            final record = AttendanceRecord(
              title: titles[randomIndex],
              date: '29 Jun 2026',
              time: '02:00 PM',
              venue: venues[randomIndex],
              isPresent: true,
              iconColor: [
                const Color(0xFF8B78FF),
                const Color(0xFF8BC34A),
                const Color(0xFF2196F3),
                const Color(0xFFFF9800)
              ][randomIndex],
            );

            FirebaseService.instance.addAttendanceRecord(record).then((_) {
              if (mounted) _showSuccessDialog();
            }).catchError((e) {
              if (mounted) _showFailedDialog();
            });
          } else {
            if (mounted) _showFailedDialog();
          }
        },
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildResultDialog(
        isSuccess: true,
        icon: Icons.check_circle_outline,
        iconColor: const Color(0xFF4CAF50),
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
        iconColor: const Color(0xFFF44336),
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
      backgroundColor: const Color(0xFF1C1C23),
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
                  backgroundColor: const Color(0xFF4A3AFF),
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
                    fontWeight: FontWeight.w600,
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: const Color(0xFF0F0F13),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: _openMockScanner,
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<AttendanceRecord>>(
          stream: FirebaseService.instance.streamRecentAttendance(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF4A3AFF)));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }

            final records = snapshot.data ?? [];
            final totalCount = records.length;
            final presentCount = records.where((r) => r.isPresent).length;
            final absentCount = totalCount - presentCount;
            final attendancePercentage = totalCount == 0 ? 0.0 : (presentCount / totalCount);
            final attendancePercentageString = '${(attendancePercentage * 100).toStringAsFixed(0)}%';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Stats Card
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14141A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF23232D)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A3AFF).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.bar_chart,
                                color: Color(0xFF8B78FF),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Attendance Overview',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Total', totalCount.toString(), Colors.white),
                            _buildStatItem('Present', presentCount.toString(), const Color(0xFF4CAF50)),
                            _buildStatItem('Absent', absentCount.toString(), const Color(0xFFF44336)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: attendancePercentage,
                            backgroundColor: const Color(0xFF23232D),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B78FF)),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Overall attendance',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            Text(
                              attendancePercentageString,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Recent Sessions Header
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
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: Color(0xFF8B78FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Recent Sessions List
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
                                color: const Color(0xFF1C1C23),
                                borderRadius: BorderRadius.circular(16),
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
                                                  ? const Color(0xFF4CAF50)
                                                  : const Color(0xFFF44336),
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
                                                ? const Color(0xFF4CAF50)
                                                : const Color(0xFFF44336),
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}