import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/blog.dart';
import '../models/events.dart';
import '../models/attendance.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  FirebaseService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream blog posts from Firestore in real-time
  Stream<List<BlogPost>> streamBlogPosts() {
    return _firestore.collection('blogs').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BlogPost.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Stream events for a specific day from Firestore
  Stream<List<EventModel>> streamEventsForDay(int day) {
    return _firestore
        .collection('events')
        .where('day', isEqualTo: day)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromMap(doc.data())).toList();
    });
  }

  // Stream recent attendance records
  Stream<List<AttendanceRecord>> streamRecentAttendance() {
    return _firestore.collection('attendance').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AttendanceRecord.fromMap(doc.data())).toList();
    });
  }

  // Add a new attendance record
  Future<void> addAttendanceRecord(AttendanceRecord record) async {
    await _firestore.collection('attendance').add(record.toMap());
  }

  // Seeds database with default mock data if empty
  Future<void> seedDatabaseIfNeeded() async {
    try {
      // 1. Seed Blogs if empty
      final blogsSnapshot = await _firestore.collection('blogs').limit(1).get();
      if (blogsSnapshot.docs.isEmpty) {
        debugPrint('Seeding blogs collection...');
        for (var post in blogPosts) {
          await _firestore.collection('blogs').doc(post.id).set(post.toMap());
        }
      }

      // 2. Seed Events if empty
      final eventsSnapshot = await _firestore.collection('events').limit(1).get();
      if (eventsSnapshot.docs.isEmpty) {
        debugPrint('Seeding events collection...');
        for (var entry in eventsData.entries) {
          final day = entry.key;
          final list = entry.value;
          for (var event in list) {
            final map = event.toMap();
            map['day'] = day; // Add the day field to group events
            await _firestore.collection('events').add(map);
          }
        }
      }

      // 3. Seed Attendance if empty
      final attendanceSnapshot = await _firestore.collection('attendance').limit(1).get();
      if (attendanceSnapshot.docs.isEmpty) {
        debugPrint('Seeding attendance collection...');
        for (var record in recentSessions) {
          await _firestore.collection('attendance').add(record.toMap());
        }
      }
      debugPrint('Database seeding checked successfully.');
    } catch (e) {
      debugPrint('Error seeding database: $e');
    }
  }
}
