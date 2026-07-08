import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/profile_data.dart';

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
  static const Color bg = Color(0xFF0F0F13);
  static const Color appBarBg = Color(0xFF090A0F);
  static const Color surface = Color(0xFF12131A);
  static const Color card = Color(0xFF1C1C23);
  static const Color primary = Color(0xFF4A3AFF);
  static const Color primaryLight = Color(0xFF8B78FF);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color textGray = Color(0xFF8B8B9B);

  bool _isExporting = false;
  bool _isEnding = false;
  Timer? _uiTimer;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rollController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _nameController.dispose();
    _rollController.dispose();
    super.dispose();
  }

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
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
            Icon(Icons.help_outline_rounded, color: Color(0xFF8B78FF)),
            SizedBox(width: 8),
            Text('Submit Attendance',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to mark attendance for this session?',
          style: TextStyle(color: Colors.grey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit',
                style: TextStyle(color: Color(0xFF8B78FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isExporting = true);
    try {
      // Mark attendance persistently for all scanned students
      await FirebaseService.instance.submitSessionAttendance(widget.sessionId);

      final scans = await FirebaseService.instance.getSessionScans(widget.sessionId);

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

      final dir = await getTemporaryDirectory();
      final sanitized = widget.eventName.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
      final file = File('${dir.path}/attendance_$sanitized.csv');
      await file.writeAsString(csvString);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Attendance for ${widget.eventName}',
      );

      await FirebaseService.instance.eraseSessionData(widget.sessionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported and erased from database.'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context);
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

  TextEditingController? _autocompleteRollController;

  void _addManualStudent() async {
    final name = _nameController.text.trim();
    final roll = (_autocompleteRollController?.text ?? _rollController.text).trim();
    if (name.isEmpty || roll.isEmpty) return;

    try {
      await FirebaseService.instance.addManualMark(
        sessionId: widget.sessionId,
        name: name,
        rollNo: roll,
      );
      _nameController.clear();
      _autocompleteRollController?.clear();
      _rollController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add: $e')),
      );
    }
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: textGray, fontSize: 13),
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.instance.streamSession(widget.sessionId),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final status = data?['status'] ?? 'ended';
        final isActive = status == 'active';
        final Timestamp? createdAt = data?['createdAt'] as Timestamp?;

        Duration remaining = Duration.zero;
        if (isActive && createdAt != null) {
          final elapsed = DateTime.now().difference(createdAt.toDate());
          remaining = const Duration(minutes: 5) - elapsed;
          if (remaining.inSeconds <= 0) {
            remaining = Duration.zero;
            FirebaseService.instance.endSession(widget.sessionId);
          }
        }

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: appBarBg,
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
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // Event Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.groups_outlined, color: primaryLight, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.eventName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Live scanning session',
                              style: TextStyle(color: textGray, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // QR Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isActive ? primary.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: primary.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isActive ? 'LIVE — Accepting Scans' : 'SESSION ENDED',
                            style: TextStyle(
                              color: isActive ? success : error,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (isActive && remaining > Duration.zero)
                            Text(
                              '${remaining.inMinutes.remainder(60).toString().padLeft(2, "0")}:${remaining.inSeconds.remainder(60).toString().padLeft(2, "0")}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // QR Box
                      AnimatedOpacity(
                        opacity: isActive ? 1.0 : 0.3,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: QrImageView(
                            data: widget.sessionId,
                            version: QrVersions.auto,
                            size: 200,
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
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isActive
                            ? 'Ask students to scan this to mark themselves present'
                            : 'QR has stopped accepting new scans',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: textGray, fontSize: 12),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isActive ? _endSession : null,
                              icon: Icon(
                                Icons.stop_circle_outlined,
                                size: 18,
                                color: isActive ? error : Colors.grey,
                              ),
                              label: Text(
                                isActive ? 'Stop QR now' : 'QR Stopped',
                                style: TextStyle(
                                  color: isActive ? error : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: (isActive ? error : Colors.grey).withOpacity(0.4),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Manual Add Card
                _buildManualAddCard(),
                const SizedBox(height: 20),

                // Running List of Marked Present Students
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirebaseService.instance.streamSessionScansList(widget.sessionId),
                  builder: (context, scansSnapshot) {
                    final scannedStudents = scansSnapshot.data ?? [];

                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Marked present',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${scannedStudents.length}',
                                  style: const TextStyle(color: primaryLight, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (scannedStudents.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'No one marked yet — scans and manual adds will show up here.',
                                style: TextStyle(color: textGray.withOpacity(0.8), fontSize: 12),
                              ),
                            )
                          else
                            ...scannedStudents.map((s) {
                              final String name = s['name'] ?? '';
                              final String rollNo = s['studentUid'] ?? '';
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: surface,
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: const TextStyle(color: primaryLight, fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                          Text(rollNo, style: const TextStyle(color: textGray, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18, color: error),
                                      splashRadius: 18,
                                      onPressed: () async {
                                        await FirebaseService.instance.removeScan(widget.sessionId, rollNo);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Submit Attendance / Export CSV button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isExporting
                        ? null
                        : (isActive ? _endSession : _exportAndErase),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? primary : success,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primary.withOpacity(0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isExporting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                          )
                        : Text(
                            isActive ? 'End QR Session' : 'Mark Attendance',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildManualAddCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add manually',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            "For students who couldn't scan the QR",
            style: TextStyle(color: textGray, fontSize: 11),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildTextField(_nameController, 'Name'),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Autocomplete<UserProfile>(
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<UserProfile>.empty();
                    }
                    return await FirebaseService.instance.getStudentSuggestions(textEditingValue.text);
                  },
                  displayStringForOption: (UserProfile option) => option.rollNo,
                  onSelected: (UserProfile selection) {
                    _rollController.text = selection.rollNo;
                    _nameController.text = selection.name;
                  },
                  fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                    _autocompleteRollController = textEditingController;
                    return TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Roll No.',
                        hintStyle: const TextStyle(color: textGray, fontSize: 13),
                        filled: true,
                        fillColor: surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    );
                  },
                  optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<UserProfile> onSelected, Iterable<UserProfile> options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        color: const Color(0xFF1C1C23),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 160,
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final UserProfile option = options.elementAt(index);
                              return ListTile(
                                title: Text(
                                  option.rollNo,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                subtitle: Text(
                                  option.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Color(0xFF8B8B9B), fontSize: 11),
                                ),
                                onTap: () {
                                  onSelected(option);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addManualStudent,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: primaryLight),
              label: const Text('Add student', style: TextStyle(color: primaryLight, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryLight.withOpacity(0.35)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
