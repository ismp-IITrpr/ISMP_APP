import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

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
  String _selectedDegree = 'All';
  final List<int> _selectedGroups = [];
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(
    hour: (TimeOfDay.now().hour + 1) % 24,
    minute: TimeOfDay.now().minute,
  );
  bool _isPostingEvent = false;

  String get _repEmail =>
      FirebaseService.instance.currentUserEmail ?? 'robotics@iitrpr.ac.in';

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
      firstDate: DateTime(2026, 7, 1),
      lastDate: DateTime(2027, 8, 31),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _postEvent() async {
    if (!_eventFormKey.currentState!.validate()) return;

    setState(() => _isPostingEvent = true);
    try {
      final club = FirebaseService.instance.getClubForEmail(_repEmail);
      
      // Target audience serialization
      final targetAudience = _selectedGroups.isEmpty 
          ? "$_selectedDegree: all" 
          : "$_selectedDegree: ${_selectedGroups.join(', ')}";

      await FirebaseService.instance.postEvent(
        title: _eventNameCtrl.text.trim(),
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        startTime: _startTime.format(context),
        endTime: _endTime.format(context),
        venue: _eventVenueCtrl.text.trim(),
        description: _eventDescCtrl.text.trim(),
        day: _selectedDate.difference(DateTime(2026, 7, 7)).inDays + 1,
        targetAudience: targetAudience,
        type: _repEmail.trim().toLowerCase() == 'ismp@iitrpr.ac.in' ? 'E' : 'C',
        club: club,
      );

      if (mounted) {
        _eventNameCtrl.clear();
        _eventVenueCtrl.clear();
        _eventDescCtrl.clear();
        setState(() {
          _selectedDegree = 'All';
          _selectedGroups.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event posted successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post event: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPostingEvent = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Create Event',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
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
            _buildPickerCard(
              label: 'Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
              icon: Icons.calendar_today,
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildPickerCard(
                    label: 'Start: ${_startTime.format(context)}',
                    icon: Icons.access_time,
                    onTap: _pickStartTime,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPickerCard(
                    label: 'End: ${_endTime.format(context)}',
                    icon: Icons.access_time,
                    onTap: _pickEndTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'Target Degree',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['All', 'B.Tech', 'M.Tech'].map((degree) {
                final isSel = _selectedDegree == degree;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(degree, style: TextStyle(color: isSel ? Colors.white : Colors.grey, fontSize: 13)),
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedDegree = degree);
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            const Text(
              'Target Groups (Optional - leave empty for all)',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(12, (index) {
                final group = index + 1;
                final isSel = _selectedGroups.contains(group);
                return FilterChip(
                  label: Text('Group $group', style: TextStyle(color: isSel ? Colors.white : Colors.grey, fontSize: 12)),
                  selected: isSel,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  checkmarkColor: Colors.white,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGroups.add(group);
                      } else {
                        _selectedGroups.remove(group);
                      }
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),

            // Description
            _buildTextField(
              controller: _eventDescCtrl,
              label: 'Description',
              icon: Icons.description,
              maxLines: 3,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isPostingEvent ? null : _postEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
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
