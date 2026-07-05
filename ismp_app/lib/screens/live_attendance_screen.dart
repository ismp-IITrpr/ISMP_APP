import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class LiveAttendanceScreen extends StatefulWidget {
  final String sessionId;
  final String eventName;

  const LiveAttendanceScreen({
    super.key,
    required this.sessionId,
    required this.eventName,
  });

  @override
  State<LiveAttendanceScreen> createState() => _LiveAttendanceScreenState();
}

class _LiveAttendanceScreenState extends State<LiveAttendanceScreen> {
  bool _isExporting = false;
  bool _isEnding = false;

  Future<void> _endSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C23),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('End Session?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'This will invalidate the QR code. Students will no longer be able to scan.',
          style: TextStyle(color: Colors.grey, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End Session',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isEnding = true);
    try {
      await FirebaseService.instance.endSession(widget.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session ended. QR code is now invalid.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isEnding = false);
    }
  }

  Future<void> _exportAndErase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C23),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text('Export & Erase',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This will:\n1. Generate a CSV file with all attendance data.\n2. Share it with you so you can save it.\n3. Permanently delete all session data from the database.\n\nThis action cannot be undone.',
          style: TextStyle(color: Colors.grey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Export & Erase',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isExporting = true);
    try {
      // 1. Fetch all scans
      final scans =
          await FirebaseService.instance.getSessionScans(widget.sessionId);

      // 2. Build CSV
      final csvData = <List<String>>[
        ['S.No', 'Name', 'Email', 'Scanned At'],
        ...scans.asMap().entries.map((entry) {
          final i = entry.key;
          final scan = entry.value;
          final scannedAt = scan['scannedAt'] is Timestamp
              ? (scan['scannedAt'] as Timestamp).toDate().toString()
              : scan['scannedAt']?.toString() ?? 'N/A';
          return [
            '${i + 1}',
            scan['name'] ?? '',
            scan['email'] ?? '',
            scannedAt,
          ];
        }),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);

      // 3. Write to temp file
      final dir = await getTemporaryDirectory();
      final sanitized =
          widget.eventName.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
      final file = File('${dir.path}/attendance_$sanitized.csv');
      await file.writeAsString(csvString);

      // 4. Share file so the rep can save/send it
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Attendance for ${widget.eventName}',
      );

      // 5. Erase data from Firebase
      await FirebaseService.instance.eraseSessionData(widget.sessionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported and erased from database.'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context); // Go back to dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        title: Text(
          widget.eventName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1C1C23),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<String>(
        stream:
            FirebaseService.instance.streamSessionStatus(widget.sessionId),
        builder: (context, statusSnapshot) {
          final status = statusSnapshot.data ?? 'active';
          final isActive = status == 'active';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF4CAF50).withOpacity(0.15)
                        : Colors.redAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF4CAF50)
                          : Colors.redAccent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? Icons.circle : Icons.cancel,
                        size: 10,
                        color: isActive
                            ? const Color(0xFF4CAF50)
                            : Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isActive ? 'LIVE — Accepting Scans' : 'SESSION ENDED',
                        style: TextStyle(
                          color: isActive
                              ? const Color(0xFF4CAF50)
                              : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // QR Code
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B78FF).withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: widget.sessionId,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF1C1C23),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1C1C23),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isActive
                      ? 'Show this QR code to students'
                      : 'This QR code is no longer valid',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 32),

                // Live counter
                StreamBuilder<int>(
                  stream: FirebaseService.instance
                      .streamSessionScanCount(widget.sessionId),
                  builder: (context, countSnapshot) {
                    final count = countSnapshot.data ?? 0;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C23),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$count',
                            style: const TextStyle(
                              color: Color(0xFF8B78FF),
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            count == 1
                                ? 'Student Scanned'
                                : 'Students Scanned',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // Action buttons
                if (isActive)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isEnding ? null : _endSession,
                      icon: _isEnding
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.stop_circle, color: Colors.white),
                      label: Text(
                        _isEnding ? 'Ending...' : 'End Session',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                if (!isActive) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportAndErase,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.download, color: Colors.white),
                      label: Text(
                        _isExporting ? 'Exporting...' : 'Export CSV & Erase Data',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B78FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
