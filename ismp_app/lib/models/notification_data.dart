import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  final String id;
  final String userRollNo;
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isRead;
  final String iconType; // 'attendance', 'event', 'info'

  NotificationItem({
    required this.id,
    required this.userRollNo,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isRead = false,
    this.iconType = 'info',
  });

  factory NotificationItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationItem(
      id: doc.id,
      userRollNo: data['userRollNo'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
      iconType: data['iconType'] ?? 'info',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userRollNo': userRollNo,
      'title': title,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'iconType': iconType,
    };
  }
}
