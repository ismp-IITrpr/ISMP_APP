import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile_data.dart';
import '../models/events.dart';
import '../models/attendance.dart';
import 'notification_service.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // In-memory cache fallback
  static UserProfile? _cachedProfile;

  /// Clears all cached data (call this on logout)
  static Future<void> clearCache() async {
    _cachedProfile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_profile');
    await prefs.remove('cached_profile_rollno');
    
    // Clear events cache too
    await prefs.remove('cached_events');
    await prefs.remove('events_fetch_date');
    await prefs.remove('events_last_fetch_time');
  }

  /// Force-clears the persistent attendance cache
  static Future<void> clearPersistentAttendanceCache(String rollNo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_attendance_$rollNo');
    await prefs.remove('attendance_last_fetch_time_$rollNo');
  }

  // 1. Fetch Mentor by their Roll Number
  Future<MentorProfile?> getMentor(String mentorRollNo) async {
    try {
      DocumentSnapshot doc = await _db.collection('mentors').doc(mentorRollNo).get();
      if (doc.exists) {
        return MentorProfile.fromFirestore(doc);
      }
    } catch (e) {
      print("Error fetching mentor: $e");
    }
    return null; // Returns null if the mentor isn't found
  }

  // 2. Fetch User and automatically attach their Mentor (with SharedPreferences caching)
  Future<UserProfile?> getUserProfile(String userRollNo) async {
    // 1. Try memory cache first
    if (_cachedProfile != null && _cachedProfile!.rollNo == userRollNo) {
      return _cachedProfile;
    }

    // 2. Try SharedPreferences cache
    final prefs = await SharedPreferences.getInstance();
    final savedRollNo = prefs.getString('cached_profile_rollno');
    if (savedRollNo == userRollNo) {
      final savedJson = prefs.getString('cached_profile');
      if (savedJson != null) {
        try {
          final profile = UserProfile.fromMap(jsonDecode(savedJson));
          _cachedProfile = profile;
          return profile;
        } catch (e) {
          print("Error parsing cached profile: $e");
        }
      }
    }

    // 3. If no cache, fetch from Firestore
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(userRollNo).get();

      if (doc.exists) {
        UserProfile user = UserProfile.fromFirestore(doc);

        final String mRollNo = user.mentorRollNo ?? '2024MEB1358';
        user.mentor = await getMentor(mRollNo);

        // stickersCollected is maintained by FieldValue.increment during session submission.
        // No need to recompute it here — trust the stored counter.
        user = UserProfile(
          name: user.name,
          rollNo: user.rollNo,
          degree: user.degree,
          branch: user.branch,
          groupNo: user.groupNo,
          stickersCollected: user.stickersCollected,
          profileUrl: user.profileUrl,
          mentorRollNo: user.mentorRollNo,
          mentor: user.mentor,
          clubName: user.clubName,
          clubId: user.clubId,
        );

        // Store in both memory and persistent cache
        _cachedProfile = user;
        await prefs.setString('cached_profile_rollno', userRollNo);
        await prefs.setString('cached_profile', jsonEncode(user.toMap()));

        return user;
      }
    } catch (e) {
      print("Error fetching user: $e");
    }
    return null;
  }

  // ─── PERSISTENT EVENTS CACHING (SharedPreferences) ─────────────────
  
  /// Force-clears the persistent cache
  static Future<void> clearPersistentEventsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_events');
    await prefs.remove('events_last_fetch_time');
  }

  /// Fetches events. Uses SharedPreferences if the cache is still valid.
  ///
  /// Cache strategy: keyed to the daily 12:00 noon cutoff.
  /// - Before noon  → cache is valid if last fetch was after *yesterday's* noon.
  /// - After noon   → cache is valid only if last fetch was after *today's* noon.
  /// This guarantees events refresh once per day at noon, picking up any new
  /// sessions added by admins in the morning.
  Future<List<EventModel>> getPersistentAllEvents() async {
    final prefs = await SharedPreferences.getInstance();

    final int? lastFetchTime = prefs.getInt('events_last_fetch_time');
    final String? savedEventsJson = prefs.getString('cached_events');

    final DateTime now = DateTime.now();
    final DateTime todayNoon = DateTime(now.year, now.month, now.day, 12, 0, 0);

    // "Last noon" = today's noon if we're past it, otherwise yesterday's noon.
    final DateTime lastNoon = now.isAfter(todayNoon)
        ? todayNoon
        : todayNoon.subtract(const Duration(days: 1));

    // 1. Cache hit: saved data exists AND was fetched after the most recent noon.
      if (lastFetchTime != null &&
          savedEventsJson != null &&
          DateTime.fromMillisecondsSinceEpoch(lastFetchTime).isAfter(lastNoon)) {
        try {
          List<dynamic> decodedList = jsonDecode(savedEventsJson);
          final decodedEvents = decodedList.map((item) => EventModel.fromMap(item, item['id'] ?? '')).toList();
          
          // Reschedule alarms on boot
          NotificationService.instance.scheduleEventReminders(decodedEvents);
          return decodedEvents;
        } catch(e) {
          print("Error parsing cached events: $e");
        }
      }

      // 2. Cache miss (expired or first time) — fetch from Firestore.
      try {
        final snapshot = await _db.collection('events').limit(500).get();
        
        List<EventModel> freshEvents = snapshot.docs
            .map((doc) => EventModel.fromMap(doc.data(), doc.id))
            .toList();

        List<Map<String, dynamic>> jsonList = freshEvents.map((e) {
          var map = e.toMap();
          map['id'] = e.id; 
          return map;
        }).toList();
        
        await prefs.setString('cached_events', jsonEncode(jsonList));
        await prefs.setInt('events_last_fetch_time', now.millisecondsSinceEpoch);

        // Schedule new alarms
        NotificationService.instance.scheduleEventReminders(freshEvents);

        return freshEvents;
      } catch (e) {
        print("Error fetching events: $e");
        return [];
      }
  }


  /// Returns events for a specific day index using the persistent cache.
  Future<List<EventModel>> getPersistentEventsForDay(int day) async {
    final allEvents = await getPersistentAllEvents();
    return allEvents.where((e) {
      final map = e.toMap();
      return map['day'] == day;
    }).toList();
  }

  /// Returns club-type events for a specific club using the persistent cache.
  /// Used by the rep's Attendance tab — avoids a live Firestore stream.
  Future<List<EventModel>> getEventsForClub(String clubName) async {
    if (clubName.isEmpty) return [];
    final allEvents = await getPersistentAllEvents();
    return allEvents
        .where((e) => e.type == 'C' && e.club == clubName)
        .toList();
  }

  // ─── PERSISTENT ATTENDANCE CACHING (SharedPreferences) ───────────

  /// Fetches a student's personal attendance records using a 24-hour cache.
  Future<List<AttendanceRecord>> getPersistentStudentAttendanceRecords(String studentRollNo) async {
    final prefs = await SharedPreferences.getInstance();
    
    final int? lastFetchTime = prefs.getInt('attendance_last_fetch_time_$studentRollNo');
    final String? savedJson = prefs.getString('cached_attendance_$studentRollNo');

    final int currentTime = DateTime.now().millisecondsSinceEpoch;
    // 24 hours — attendance records only update when a rep submits a session.
    const int cacheDuration = 24 * 60 * 60 * 1000;

    if (lastFetchTime != null && 
        savedJson != null && 
        (currentTime - lastFetchTime) < cacheDuration) {
      try {
        List<dynamic> decodedList = jsonDecode(savedJson);
        return decodedList.map((item) => AttendanceRecord.fromMap(item)).toList();
      } catch(e) {
        print("Error parsing cached attendance: $e");
      }
    }

    try {
      final snapshot = await _db.collection('users').doc(studentRollNo).collection('attendance').get();
      
      List<AttendanceRecord> freshRecords = snapshot.docs
          .map((doc) => AttendanceRecord.fromFirestore(doc))
          .toList();

      List<Map<String, dynamic>> jsonList = freshRecords.map((e) {
        return {
          'eventId': e.eventId,
          'eventType': e.eventType,
          'title': e.title,
          'date': e.date,
          'time': e.time,
          'venue': e.venue,
          'isPresent': e.isPresent,
          'iconColor': e.iconColor.toARGB32(),
          'markedAt': e.markedAt?.toIso8601String(),
        };
      }).toList();
      
      await prefs.setString('cached_attendance_$studentRollNo', jsonEncode(jsonList));
      await prefs.setInt('attendance_last_fetch_time_$studentRollNo', currentTime);

      return freshRecords;
    } catch (e) {
      print("Error fetching attendance: $e");
      return [];
    }
  }

  /// Combines persistent events and persistent student records (showing full schedule to everyone).
  Future<List<AttendanceRecord>> getPersistentCombinedStudentAttendance(String studentRollNo, int studentGroupNo) async {
    final allEvents = await getPersistentAllEvents();
    final studentRecords = await getPersistentStudentAttendanceRecords(studentRollNo);

    List<AttendanceRecord> combined = [];
    for (var event in allEvents) {
      final matchingRecord = studentRecords.firstWhere(
        (r) => r.eventId == event.id,
        orElse: () => AttendanceRecord(
          eventId: event.id,
          eventType: event.type,
          title: event.title,
          club: event.club,
          date: event.date,
          time: event.time,
          venue: event.venue,
          isPresent: false,
          iconColor: event.dotColor,
        ),
      );
      combined.add(matchingRecord);
    }
    
    return combined;
  }
}
