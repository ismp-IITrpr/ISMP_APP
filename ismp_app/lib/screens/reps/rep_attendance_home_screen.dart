import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/events.dart';
import '../../services/firebase_service.dart';
import '../reps/live_attendance_screen.dart';
import '../../widgets/active_session_button.dart';
import '../../services/rep_access.dart';

class RepAttendanceHomeScreen extends StatefulWidget {
  const RepAttendanceHomeScreen({super.key});

  @override
  State<RepAttendanceHomeScreen> createState() => _RepAttendanceHomeScreenState();
}

class _RepAttendanceHomeScreenState extends State<RepAttendanceHomeScreen> {
  // Parse time string e.g. "09:30 AM" into TimeOfDay
  TimeOfDay _parseTimeString(String timeStr) {
    try {
      final format = DateFormat("hh:mm a");
      final dt = format.parse(timeStr.trim());
      return TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  // Delete event confirmation dialog
  Future<void> _confirmDelete(BuildContext context, EventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C23),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Event?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${event.title}"? This will permanently remove the event and cannot be undone.',
          style: const TextStyle(color: Colors.grey, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseService.instance.deleteEvent(event.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event deleted successfully!'),
              backgroundColor: Color(0xFFF44336),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Edit event modal sheet
  void _showEditSheet(BuildContext context, EventModel event) {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: event.title);
    final venueCtrl = TextEditingController(text: event.venue);
    final descCtrl = TextEditingController(text: event.description);

    // Parse targetAudience
    String initialDegree = 'All';
    List<int> initialGroups = [];
    final raw = event.targetAudience.trim();
    if (raw.isNotEmpty) {
      if (raw.contains(':')) {
        final parts = raw.split(':');
        initialDegree = parts[0].trim();
        final groupsPart = parts[1].trim().toLowerCase();
        if (groupsPart != 'all' && groupsPart != 'all members' && groupsPart.isNotEmpty) {
          initialGroups = groupsPart
              .split(RegExp(r'[\s,]+'))
              .map((s) => int.tryParse(s))
              .whereType<int>()
              .toList();
        }
      } else {
        if (raw.toLowerCase() != 'all' && raw.toLowerCase() != 'all members') {
          initialGroups = raw
              .split(RegExp(r'[\s,]+'))
              .map((s) => int.tryParse(s))
              .whereType<int>()
              .toList();
        }
      }
    }

    DateTime selectedDate = DateTime.tryParse(event.date) ?? DateTime(2026, 8, 1);
    TimeOfDay startTime = _parseTimeString(event.startTime);
    TimeOfDay endTime = _parseTimeString(event.endTime);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bctx) {
        String selectedDegree = initialDegree;
        List<int> selectedGroups = List.from(initialGroups);
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2026, 7, 1),
                lastDate: DateTime(2027, 8, 31),
              );
              if (picked != null) setModalState(() => selectedDate = picked);
            }

            Future<void> pickStartTime() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: startTime,
              );
              if (picked != null) setModalState(() => startTime = picked);
            }

            Future<void> pickEndTime() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: endTime,
              );
              if (picked != null) setModalState(() => endTime = picked);
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Edit Session Event',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Event Title
                      _buildModalField(
                        controller: titleCtrl,
                        label: 'Event / Club Name',
                        icon: Icons.celebration,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Venue
                      _buildModalField(
                        controller: venueCtrl,
                        label: 'Venue',
                        icon: Icons.location_on,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Date selector
                      _buildModalPickerCard(
                        label: 'Date: ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                        icon: Icons.calendar_today,
                        onTap: pickDate,
                      ),
                      const SizedBox(height: 16),

                      // Start and End times
                      Row(
                        children: [
                          Expanded(
                            child: _buildModalPickerCard(
                              label: 'Start: ${startTime.format(context)}',
                              icon: Icons.access_time,
                              onTap: pickStartTime,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildModalPickerCard(
                              label: 'End: ${endTime.format(context)}',
                              icon: Icons.access_time,
                              onTap: pickEndTime,
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
                          final isSel = selectedDegree == degree;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(degree, style: TextStyle(color: isSel ? Colors.white : Colors.grey, fontSize: 13)),
                              selected: isSel,
                              selectedColor: const Color(0xFF8B78FF),
                              backgroundColor: const Color(0xFF1C1C23),
                              onSelected: (selected) {
                                if (selected) setModalState(() => selectedDegree = degree);
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
                          final isSel = selectedGroups.contains(group);
                          return FilterChip(
                            label: Text('Group $group', style: TextStyle(color: isSel ? Colors.white : Colors.grey, fontSize: 12)),
                            selected: isSel,
                            selectedColor: const Color(0xFF8B78FF),
                            backgroundColor: const Color(0xFF1C1C23),
                            checkmarkColor: Colors.white,
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  selectedGroups.add(group);
                                } else {
                                  selectedGroups.remove(group);
                                }
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      _buildModalField(
                        controller: descCtrl,
                        label: 'Description',
                        icon: Icons.description,
                        maxLines: 3,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),

                      // Update and Cancel buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;

                                try {
                                  await FirebaseService.instance.updateEvent(
                                    eventId: event.id,
                                    title: titleCtrl.text.trim(),
                                    date: DateFormat('yyyy-MM-dd').format(selectedDate),
                                    startTime: startTime.format(context),
                                    endTime: endTime.format(context),
                                    venue: venueCtrl.text.trim(),
                                    description: descCtrl.text.trim(),
                                    day: selectedDate.difference(DateTime(2026, 7, 7)).inDays + 1,
                                    targetAudience: selectedGroups.isEmpty 
                                        ? "$selectedDegree: all" 
                                        : "$selectedDegree: ${selectedGroups.join(', ')}",
                                  );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Event updated successfully!'),
                                        backgroundColor: Color(0xFF4CAF50),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to update event: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B78FF),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text(
                                'Save Changes',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalField({
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
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF8B78FF)),
        filled: true,
        fillColor: const Color(0xFF0F0F13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B78FF)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildModalPickerCard({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF8B78FF), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String email = FirebaseService.instance.currentUserEmail ?? 'robotics@iitrpr.ac.in';
    final String repClub = getRepClubName(email) ?? 'Robotics';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F13),
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
        child: StreamBuilder<List<EventModel>>(
          stream: FirebaseService.instance.streamEventsForClub(repClub),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF4A3AFF)));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }
            final clubSessions = snapshot.data ?? [];
            if (clubSessions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      size: 64,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No sessions scheduled yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: clubSessions.length,
              itemBuilder: (context, index) {
                final event = clubSessions[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C23),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF4A3AFF).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A3AFF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.groups_outlined,
                          color: Color(0xFF8B78FF),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${event.date} • ${event.time}',
                              style: const TextStyle(
                                color: Color(0xFF8B8B9B),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              event.venue,
                              style: const TextStyle(
                                color: Color(0xFF8B8B9B),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Edit & Delete row
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => _showEditSheet(context, event),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 14, color: Colors.grey.shade400),
                                        const SizedBox(width: 4),
                                        Text('Edit', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () => _confirmDelete(context, event),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 14, color: Colors.red.shade400),
                                        const SizedBox(width: 4),
                                        Text('Delete', style: TextStyle(color: Colors.red.shade400, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Take Attendance button / Completed status
                      event.isCompleted
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 14,
                                    color: Color(0xFF4CAF50),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Completed',
                                    style: TextStyle(
                                      color: Color(0xFF4CAF50),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : (event.getFormattedAudience() == 'All Members'
                              ? const SizedBox()
                              : ActiveSessionButton(
                                  event: event,
                                  defaultText: 'Start',
                                  defaultIcon: Icons.qr_code_scanner,
                                )),
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
}