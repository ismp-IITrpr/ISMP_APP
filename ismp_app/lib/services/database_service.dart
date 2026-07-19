import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile_data.dart';
import '../models/events.dart';
import '../models/attendance.dart';
import '../models/blog.dart';
import '../models/moment.dart';
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
    _cachedProfile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_attendance_$rollNo');
    await prefs.remove('attendance_last_fetch_time_$rollNo');
    await prefs.remove('cached_profile');
    await prefs.remove('cached_profile_rollno');
  }

  // 1. Fetch Mentor by their Roll Number
  Future<MentorProfile?> getMentor(String mentorRollNo) async {
    try {
      DocumentSnapshot doc = await _db.collection('mentors').doc(mentorRollNo.trim()).get();
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

  /// Real-time stream of User Profile.
  /// Updates SharedPreferences and memory cache in the background whenever Firestore updates.
  Stream<UserProfile?> streamUserProfile(String userRollNo) {
    return _db.collection('users').doc(userRollNo).snapshots().asyncMap((doc) async {
      if (doc.exists) {
        UserProfile user = UserProfile.fromFirestore(doc);
        final String mRollNo = user.mentorRollNo ?? '2024MEB1358';
        user.mentor = await getMentor(mRollNo);

        // Update in-memory and persistent cache
        _cachedProfile = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_profile_rollno', userRollNo);
        await prefs.setString('cached_profile', jsonEncode(user.toMap()));

        return user;
      }
      return null;
    });
  }

  // ─── PERSISTENT EVENTS CACHING (SharedPreferences) ─────────────────
  
  /// Force-clears the persistent cache
  static Future<void> clearPersistentEventsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_events');
    await prefs.remove('events_last_fetch_time');
    await prefs.remove('events_last_metadata_check');
  }

  /// Fetches events. Uses SharedPreferences if the cache is still valid.
  /// Checks metadata timestamp at most once per day after 12:00 Noon.
  Future<List<EventModel>> getPersistentAllEvents() async {
    final prefs = await SharedPreferences.getInstance();

    final int? lastFetchTime = prefs.getInt('events_last_fetch_time');
    final String? savedEventsJson = prefs.getString('cached_events');
    final int? lastMetadataCheck = prefs.getInt('events_last_metadata_check');

    final DateTime now = DateTime.now();
    final DateTime todayNoon = DateTime(now.year, now.month, now.day, 12, 0, 0);

    // "Last noon" = today's noon if we're past it, otherwise yesterday's noon.
    final DateTime lastNoon = now.isAfter(todayNoon)
        ? todayNoon
        : todayNoon.subtract(const Duration(days: 1));

    bool needsCheck = false;
    
    // Check if we need to query metadata (only once per day after 12:00 Noon)
    if (lastMetadataCheck == null) {
      needsCheck = true;
    } else {
      final DateTime checkTime = DateTime.fromMillisecondsSinceEpoch(lastMetadataCheck);
      if (!checkTime.isAfter(lastNoon)) {
        needsCheck = true;
      }
    }

    if (savedEventsJson != null && lastFetchTime != null) {
      if (!needsCheck) {
        // No metadata check needed yet today (already checked after 12:00 Noon)
        // Instant load from SharedPreferences (0 reads!)
        try {
          List<dynamic> decodedList = jsonDecode(savedEventsJson);
          final decodedEvents = decodedList.map((item) => EventModel.fromMap(item, item['id'] ?? '')).toList();
          NotificationService.instance.scheduleEventReminders(decodedEvents);
          return decodedEvents;
        } catch (e) {
          print("Error parsing cached events: $e");
        }
      } else {
        // We are after 12:00 Noon and haven't checked metadata yet today.
        // Let's do a single metadata read to see if there were changes.
        try {
          final doc = await _db.collection('metadata').doc('events_state').get();
          if (doc.exists) {
            final Timestamp? remoteLastUpdated = doc.data()?['lastUpdated'] as Timestamp?;
            final int remoteTimeMs = remoteLastUpdated?.millisecondsSinceEpoch ?? 0;

            // Mark that we performed the metadata check today
            await prefs.setInt('events_last_metadata_check', now.millisecondsSinceEpoch);

            if (remoteTimeMs <= lastFetchTime) {
              // Database did not change! Serve from local SharedPreferences cache.
              List<dynamic> decodedList = jsonDecode(savedEventsJson);
              final decodedEvents = decodedList.map((item) => EventModel.fromMap(item, item['id'] ?? '')).toList();
              NotificationService.instance.scheduleEventReminders(decodedEvents);
              return decodedEvents;
            }
          }
        } catch (e) {
          print("Error checking events metadata: $e");
        }
      }
    }

    // Cache miss (expired, first time, or database changed) — fetch from Firestore.
    try {
      // Query ONLY upcoming events (where date is greater than or equal to today)
      final String todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      final snapshot = await _db.collection('events')
          .where('date', isGreaterThanOrEqualTo: todayStr)
          .get();
      
      List<EventModel> freshEvents = snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data(), doc.id))
          .toList();

      List<Map<String, dynamic>> jsonList = freshEvents.map((e) {
        var map = e.toMap();
        map['id'] = e.id; 
        return map;
      }).toList();
      
      final currentTimeMs = now.millisecondsSinceEpoch;
      await prefs.setString('cached_events', jsonEncode(jsonList));
      await prefs.setInt('events_last_fetch_time', currentTimeMs);
      await prefs.setInt('events_last_metadata_check', currentTimeMs);

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
          'club': e.club,
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

  /// Real-time stream of student's personal attendance records.
  /// Updates SharedPreferences cache in the background whenever Firestore updates,
  /// so that offline/cached loads also get the latest scanned records.
  Stream<List<AttendanceRecord>> streamPersistentStudentAttendanceRecords(String studentRollNo) {
    return _db
        .collection('users')
        .doc(studentRollNo)
        .collection('attendance')
        .snapshots()
        .asyncMap((snapshot) async {
      List<AttendanceRecord> freshRecords = snapshot.docs
          .map((doc) => AttendanceRecord.fromFirestore(doc))
          .toList();

      List<Map<String, dynamic>> jsonList = freshRecords.map((e) {
        return {
          'eventId': e.eventId,
          'eventType': e.eventType,
          'title': e.title,
          'club': e.club,
          'date': e.date,
          'time': e.time,
          'venue': e.venue,
          'isPresent': e.isPresent,
          'iconColor': e.iconColor.toARGB32(),
          'markedAt': e.markedAt?.toIso8601String(),
        };
      }).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_attendance_$studentRollNo', jsonEncode(jsonList));
      await prefs.setInt('attendance_last_fetch_time_$studentRollNo', DateTime.now().millisecondsSinceEpoch);

      return freshRecords;
    });
  }

  /// Combines persistent events and persistent student records (showing full schedule to everyone).
  Future<List<AttendanceRecord>> getPersistentCombinedStudentAttendance(String studentRollNo, int studentGroupNo) async {
    final allEvents = await getPersistentAllEvents();
    final studentRecords = await getPersistentStudentAttendanceRecords(studentRollNo);

    List<AttendanceRecord> combined = List.from(studentRecords);
    for (var event in allEvents) {
      final alreadyAdded = combined.any((r) => r.eventId == event.id);
      if (!alreadyAdded && event.isCompleted) {
        combined.add(AttendanceRecord(
          eventId: event.id,
          eventType: event.type,
          title: event.title,
          club: event.club,
          date: event.date,
          time: event.time,
          venue: event.venue,
          isPresent: false,
          iconColor: event.dotColor,
        ));
      }
    }
    
    return combined;
  }

  // ─── PERSISTENT BLOGS & MOMENTS CACHING (7 Days) ───────────────────

  /// Fetches blogs. Uses SharedPreferences if the 7-day cache is valid.
  Future<List<BlogPost>> getPersistentBlogs() async {
    final prefs = await SharedPreferences.getInstance();
    final int? lastFetchTime = prefs.getInt('blogs_last_fetch_time');
    final String? savedBlogsJson = prefs.getString('cached_blogs');

    final int currentTime = DateTime.now().millisecondsSinceEpoch;
    const int cacheDuration = 7 * 24 * 60 * 60 * 1000; // 7 days

    if (lastFetchTime != null && 
        savedBlogsJson != null && 
        (currentTime - lastFetchTime) < cacheDuration) {
      try {
        List<dynamic> decodedList = jsonDecode(savedBlogsJson);
        return decodedList.map((item) => BlogPost.fromMap(item, item['id'] ?? '')).toList();
      } catch (e) {
        print("Error parsing cached blogs: $e");
      }
    }

    try {
      final snapshot = await _db.collection('blogs').orderBy('date', descending: true).get();
      List<BlogPost> freshBlogs = snapshot.docs
          .map((doc) => BlogPost.fromMap(doc.data(), doc.id))
          .toList();

      List<Map<String, dynamic>> jsonList = freshBlogs.map((e) => e.toMap()).toList();
      await prefs.setString('cached_blogs', jsonEncode(jsonList));
      await prefs.setInt('blogs_last_fetch_time', currentTime);

      return freshBlogs;
    } catch (e) {
      print("Error fetching blogs: $e");
      return [];
    }
  }

  /// Fetches moments. Uses SharedPreferences if the 7-day cache is valid.
  Future<List<MomentModel>> getPersistentMoments() async {
    final prefs = await SharedPreferences.getInstance();
    final int? lastFetchTime = prefs.getInt('moments_last_fetch_time');
    final String? savedMomentsJson = prefs.getString('cached_moments');

    final int currentTime = DateTime.now().millisecondsSinceEpoch;
    const int cacheDuration = 7 * 24 * 60 * 60 * 1000; // 7 days

    if (lastFetchTime != null && 
        savedMomentsJson != null && 
        (currentTime - lastFetchTime) < cacheDuration) {
      try {
        List<dynamic> decodedList = jsonDecode(savedMomentsJson);
        return decodedList.map((item) => MomentModel.fromMap(item, item['id'] ?? '')).toList();
      } catch (e) {
        print("Error parsing cached moments: $e");
      }
    }

    try {
      final snapshot = await _db.collection('moments').get();
      List<MomentModel> freshMoments = snapshot.docs
          .map((doc) => MomentModel.fromMap(doc.data(), doc.id))
          .toList();

      List<Map<String, dynamic>> jsonList = freshMoments.map((e) {
        var map = e.toMap();
        map['id'] = e.id;
        return map;
      }).toList();
      await prefs.setString('cached_moments', jsonEncode(jsonList));
      await prefs.setInt('moments_last_fetch_time', currentTime);

      return freshMoments;
    } catch (e) {
      print("Error fetching moments: $e");
      return [];
    }
  }

  /// Force-clears persistent blogs and moments cache
  static Future<void> clearBlogsAndMomentsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_blogs');
    await prefs.remove('blogs_last_fetch_time');
    await prefs.remove('cached_moments');
    await prefs.remove('moments_last_fetch_time');
  }
}
