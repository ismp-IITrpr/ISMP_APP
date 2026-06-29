import 'package:flutter/material.dart';
import '../models/events.dart';
import '../models/attendance.dart';
import '../services/mock_attendance_service.dart';
import 'student_scanner_screen.dart';
import 'detailed_attendance_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final String currentStudentId = "student_123"; // Mock student ID
  List<EventModel> clubSessions = [];

  @override
  void initState() {
    super.initState();
    _loadClubSessions();
  }

  void _loadClubSessions() {
    // Flatten all events across all days and filter for Club Sessions ('C')
    final allEvents = eventsData.values.expand((events) => events).toList();
    setState(() {
      clubSessions = allEvents.where((e) => e.type == 'C').toList();
    });
  }

  bool _isStudentPresent(String eventId, MockAttendanceService service) {
    // 1. Check live scanner data
    if (service.isPresent(eventId, currentStudentId)) return true;
    
    // 2. Check historical dummy data
    try {
      final record = recentSessions.firstWhere((r) => r.eventId == eventId);
      return record.isPresent;
    } catch (e) {
      return false;
    }
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
    final attendanceService = MockAttendanceService();
    int presentCount = 0;
    
    for (var session in clubSessions) {
      if (_isStudentPresent(session.id, attendanceService)) {
        presentCount++;
      }
    }
    
    final totalCount = clubSessions.length;
    final absentCount = totalCount - presentCount;
    final attendancePercentage = totalCount == 0 ? 0.0 : presentCount / totalCount;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
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
        backgroundColor: const Color(0xFF090A0F),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: _openScanner,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Stats Card
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2A2A3D),
                      const Color(0xFF14141A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A3AFF).withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFF4A3AFF).withOpacity(0.3)),
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
                                color: const Color(0xFF4A3AFF).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.bar_chart,
                                color: Color(0xFF8B78FF),
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
                    const SizedBox(height: 16),
                    // View in Detail Text Button
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
                        icon: const Icon(Icons.dashboard_customize_outlined, size: 18, color: Color(0xFF8B78FF)),
                        label: const Text(
                          'View Club Trophy Boards',
                          style: TextStyle(
                            color: Color(0xFF8B78FF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
                    'Club Sessions History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Recent Sessions List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                itemCount: clubSessions.length,
                itemBuilder: (context, index) {
                  final session = clubSessions[index];
                  final isPresent = _isStudentPresent(session.id, attendanceService);
                  
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
                            color: session.dotColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            color: session.dotColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                session.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${session.date} • ${session.time}\n',
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
                                  isPresent ? 'Present' : 'Absent',
                                  style: TextStyle(
                                    color: isPresent
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFF44336),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  isPresent
                                      ? Icons.check_circle_outline
                                      : Icons.cancel_outlined,
                                  color: isPresent
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
        ),
      ),
    );
  }
}