import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import 'live_attendance_screen.dart';

class RepDashboard extends StatefulWidget {
  const RepDashboard({super.key});

  @override
  State<RepDashboard> createState() => _RepDashboardState();
}

class _RepDashboardState extends State<RepDashboard> {
  // Event Creator form
  final _eventFormKey = GlobalKey<FormState>();
  final _eventNameCtrl = TextEditingController();
  final _eventVenueCtrl = TextEditingController();
  final _eventDescCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isPostingEvent = false;

  String get _repEmail =>
      FirebaseService.instance.currentUser?.email ?? 'testclub@iitrpr.ac.in';

  @override
  void dispose() {
    _eventNameCtrl.dispose();
    _eventVenueCtrl.dispose();
    _eventDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _postEvent() async {
    if (!_eventFormKey.currentState!.validate()) return;

    setState(() => _isPostingEvent = true);
    try {
      final club = FirebaseService.instance.getClubForEmail(_repEmail);
      await FirebaseService.instance.postEvent(
        title: _eventNameCtrl.text.trim(),
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        time: _selectedTime.format(context),
        venue: _eventVenueCtrl.text.trim(),
        description: _eventDescCtrl.text.trim(),
        day: _selectedDate.day,
        type: 'C',
        club: club,
      );

      if (mounted) {
        _eventNameCtrl.clear();
        _eventVenueCtrl.clear();
        _eventDescCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event posted successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post event: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPostingEvent = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubName = FirebaseService.instance.getClubForEmail(_repEmail);
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        title: const Text(
          'Create Event',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1C1C23),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF4A3AFF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4A3AFF).withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                clubName.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF8B78FF),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () async {
              await FirebaseService.instance.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: _buildEventCreatorTab(),
    );
  }

  // ─── EVENT CREATOR TAB ───────────────────────────────────────────

  Widget _buildEventCreatorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _eventFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create New Event',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This event will appear on the student timeline.',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Event Name
            _buildTextField(
              controller: _eventNameCtrl,
              label: 'Event Name',
              icon: Icons.celebration,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Venue
            _buildTextField(
              controller: _eventVenueCtrl,
              label: 'Venue',
              icon: Icons.location_on,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Date & Time pickers
            Row(
              children: [
                Expanded(
                  child: _buildPickerCard(
                    label: DateFormat('dd MMM yyyy').format(_selectedDate),
                    icon: Icons.calendar_today,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPickerCard(
                    label: _selectedTime.format(context),
                    icon: Icons.access_time,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            _buildTextField(
              controller: _eventDescCtrl,
              label: 'Description (optional)',
              icon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isPostingEvent ? null : _postEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B78FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isPostingEvent
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Post Event',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500]),
        prefixIcon: Icon(icon, color: const Color(0xFF8B78FF)),
        filled: true,
        fillColor: const Color(0xFF1C1C23),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF8B78FF)),
        ),
      ),
    );
  }

  Widget _buildPickerCard({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C23),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF8B78FF), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
