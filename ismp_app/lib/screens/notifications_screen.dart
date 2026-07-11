import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _initialMarkDone = false;

  @override
  void initState() {
    super.initState();
    _markAllAsReadOnce();
  }

  Future<void> _markAllAsReadOnce() async {
    if (_initialMarkDone) return;
    _initialMarkDone = true;
    final rollNo = FirebaseService.instance.currentStudentRollNo;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userRollNo', isEqualTo: rollNo)
          .where('isRead', isEqualTo: false)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final rollNo = FirebaseService.instance.currentStudentRollNo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userRollNo', isEqualTo: rollNo)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // Sort in-memory descending by timestamp (bypasses composite index requirement)
          final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
          sortedDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['timestamp'] as Timestamp?;
            final bTime = bData['timestamp'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return -1; // New/pending notifications at the top
            if (bTime == null) return 1;
            return bTime.compareTo(aTime);
          });

          // Trigger mark as read whenever new notifications arrive
          // Removed to prevent infinite rebuild loop

          if (sortedDocs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Dynamic Firestore Notifications
              ...sortedDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final title = data['title'] ?? 'Notification';
                final description = data['description'] ?? '';
                final timestamp = data['timestamp'] as Timestamp?;
                final timeStr = timestamp != null
                    ? _formatTimestamp(timestamp.toDate())
                    : 'Just now';
                final iconType = data['iconType'] ?? 'info';

                IconData icon = Icons.info_outline;
                Color iconColor = AppColors.primary;

                if (iconType == 'attendance') {
                  icon = Icons.check_circle_outline;
                  iconColor = AppColors.primary;
                } else if (iconType == 'event') {
                  icon = Icons.event;
                  iconColor = AppColors.warning;
                }

                return _buildNotificationCard(
                  icon: icon,
                  iconColor: iconColor,
                  title: title,
                  description: description,
                  time: timeStr,
                );
              }),

              // // Pre-existing Mock Notifications
              // _buildNotificationCard(
              //   icon: Icons.event,
              //   iconColor: AppColors.warning,
              //   title: 'Upcoming Event: Freshers Meet',
              //   description: 'Don\'t forget! The ISMP Freshers Meet is happening tonight at 6 PM in the main auditorium.',
              //   time: '2 hours ago',
              // ),
              // _buildNotificationCard(
              //   icon: Icons.check_circle_outline,
              //   iconColor: AppColors.primary,
              //   title: 'Attendance Updated',
              //   description: 'Your attendance for the mentoring session on Friday has been marked present.',
              //   time: '1 day ago',
              // ),
              // _buildNotificationCard(
              //   icon: Icons.info_outline,
              //   iconColor: AppColors.primary,
              //   title: 'Welcome to ISMP!',
              //   description: 'We are thrilled to have you here. Check out the app to explore events and your mentor profile.',
              //   time: '2 days ago',
              // ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
