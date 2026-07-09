import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/events.dart';

/// Rep-facing Attendance screen — brand-new file (per Gorish's note, this
/// stays separate from the student attendance file since the club-id
/// batching logic will live here).
/// TODO (logic owner / Gorish):
///  - Wire real QR payload generation (session token + club id + expiry).
///  - Wire live scan stream to populate `_presentStudents` instead of the
///    mocked add-flow below.
///  - Wire `_submitAttendance` to the actual batch API call.
///  - Add club-id to whatever request the manual-add search uses.
class RepAttendanceScreen extends StatefulWidget {
  final EventModel event;
  final Duration qrDuration;

  const RepAttendanceScreen({
    super.key,
    required this.event,
    this.qrDuration = const Duration(minutes: 10),
  });

  @override
  State<RepAttendanceScreen> createState() => _RepAttendanceScreenState();
}

class _PresentStudent {
  final String name;
  final String rollNo;
  final bool manuallyAdded;

  _PresentStudent({
    required this.name,
    required this.rollNo,
    this.manuallyAdded = false,
  });
}

class _RepAttendanceScreenState extends State<RepAttendanceScreen> {
  static const Color bg = Color(0xFF0F0F13);
  static const Color appBarBg = Color(0xFF090A0F);
  static const Color surface = Color(0xFF12131A);
  static const Color card = Color(0xFF1C1C23);
  static const Color primary = Color(0xFF4A3AFF);
  static const Color primaryLight = Color(0xFF8B78FF);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color textGray = Color(0xFF8B8B9B);

  late Duration _remaining;
  Timer? _timer;
  bool _qrActive = true;
  bool _submitting = false;

  final List<_PresentStudent> _presentStudents = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rollController = TextEditingController();

  // TODO (logic owner): replace with the actual rotating QR payload
  // (e.g. session token signed with club id + timestamp).
  String get _qrPayload =>
      'session:${widget.event.id}:${DateTime.now().millisecondsSinceEpoch ~/ 30000}';

  @override
  void initState() {
    super.initState();
    _remaining = widget.qrDuration;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remaining.inSeconds <= 1 || !_qrActive) {
        setState(() {
          _remaining = Duration.zero;
          _qrActive = false;
        });
        t.cancel();
      } else {
        setState(() {
          _remaining -= const Duration(seconds: 1);
        });
      }
    });
  }

  void _stopQrManually() {
    setState(() => _qrActive = false);
    _timer?.cancel();
  }

  void _restartQr() {
    setState(() {
      _remaining = widget.qrDuration;
      _qrActive = true;
    });
    _startTimer();
  }

  void _addManualStudent() {
    final name = _nameController.text.trim();
    final roll = _rollController.text.trim();
    if (name.isEmpty || roll.isEmpty) return;

    setState(() {
      _presentStudents.add(
        _PresentStudent(name: name, rollNo: roll, manuallyAdded: true),
      );
      _nameController.clear();
      _rollController.clear();
    });
  }

  void _removeStudent(_PresentStudent s) {
    setState(() => _presentStudents.remove(s));
  }

  Future<void> _submitAttendance() async {
    if (_presentStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mark at least one student present first.')),
      );
      return;
    }

    setState(() => _submitting = true);

    // TODO (logic owner): replace with real batch submit API call.
    // e.g. await attendanceRepo.submitBatch(eventId: widget.event.id, students: _presentStudents);
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_presentStudents.length} students submitted for ${widget.event.title}.'),
        backgroundColor: success,
      ),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _nameController.dispose();
    _rollController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
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
            _buildEventHeader(),
            const SizedBox(height: 20),
            _buildQrCard(),
            const SizedBox(height: 20),
            _buildManualAddCard(),
            const SizedBox(height: 20),
            _buildPresentList(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventHeader() {
    return Container(
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
                  widget.event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.event.time} • ${widget.event.venue}',
                  style: const TextStyle(color: textGray, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _qrActive ? primary.withOpacity(0.3) : Colors.white.withOpacity(0.05),
        ),
        boxShadow: _qrActive
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
                _qrActive ? 'QR ACTIVE' : 'QR STOPPED',
                style: TextStyle(
                  color: _qrActive ? success : error,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              if (_qrActive)
                Text(
                  _formatDuration(_remaining),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // QR placeholder box.
          // TODO (logic owner): swap this Container for an actual QR render,
          // e.g. QrImageView(data: _qrPayload, size: 200) from qr_flutter.
          AnimatedOpacity(
            opacity: _qrActive ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: _qrActive
                    ? Icon(Icons.qr_code_2_rounded, size: 140, color: Colors.black.withOpacity(0.85))
                    : const Icon(Icons.qr_code_2_rounded, size: 140, color: Colors.black26),
              ),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            _qrActive
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
                  onPressed: _qrActive ? _stopQrManually : _restartQr,
                  icon: Icon(
                    _qrActive ? Icons.stop_circle_outlined : Icons.refresh_rounded,
                    size: 18,
                    color: _qrActive ? error : primaryLight,
                  ),
                  label: Text(
                    _qrActive ? 'Stop QR now' : 'Restart QR',
                    style: TextStyle(
                      color: _qrActive ? error : primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: (_qrActive ? error : primaryLight).withOpacity(0.4),
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
            children: [
              Expanded(
                flex: 3,
                child: _buildTextField(_nameController, 'Name'),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _buildTextField(_rollController, 'Roll No.'),
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

  Widget _buildPresentList() {
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
                  '${_presentStudents.length}',
                  style: const TextStyle(color: primaryLight, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_presentStudents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No one marked yet — scans and manual adds will show up here.',
                style: TextStyle(color: textGray.withOpacity(0.8), fontSize: 12),
              ),
            )
          else
            ..._presentStudents.map((s) => _buildStudentRow(s)),
        ],
      ),
    );
  }

  Widget _buildStudentRow(_PresentStudent s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: surface,
            child: Text(
              s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
              style: const TextStyle(color: primaryLight, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(s.rollNo, style: const TextStyle(color: textGray, fontSize: 11)),
              ],
            ),
          ),
          if (s.manuallyAdded)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Manual', style: TextStyle(color: textGray, fontSize: 10)),
            ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: error),
            splashRadius: 18,
            onPressed: () => _removeStudent(s),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _submitting ? null : _submitAttendance,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _submitting
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
        )
            : const Text(
          'Submit Attendance',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}