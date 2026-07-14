import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class EventModel {
  final String id;
  final String title; // Represents the club name or event name
  final String date;  // Format: 'yyyy-MM-dd' e.g. '2024-05-21'
  final String time;
  final String venue;
  final String type; // 'E' for Events, 'C' for Club Sessions
  final String club; // Only for type 'C' — which club created this
  final String targetAudience;
  final String description;
  final Color dotColor;
  final String startTime;
  final String endTime;
  final int day;
  final bool isCompleted;

  EventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.venue,
    required this.type,
    this.club = '',
    required this.targetAudience,
    required this.description,
    required this.dotColor,
    this.startTime = '',
    this.endTime = '',
    this.day = 0,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'time': time,
      'venue': venue,
      'type': type,
      'club': club,
      'targetAudience': targetAudience,
      'groupNo': targetAudience, // Saved for backward compatibility
      'description': description,
      'dotColor': dotColor.toARGB32(),
      'startTime': startTime,
      'endTime': endTime,
      'day': day,
      'isCompleted': isCompleted,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final timeVal = map['time'] ?? '';
    String start = map['startTime'] ?? '';
    String end = map['endTime'] ?? '';
    if (start.isEmpty && timeVal.isNotEmpty) {
      final parts = timeVal.split(' - ');
      if (parts.length == 2) {
        start = parts[0];
        end = parts[1];
      } else {
        start = timeVal;
      }
    }

    final groupData = map['groupNo'] ?? map['targetAudience'] ?? '';
    String audience = '';
    if (groupData is List) {
      audience = groupData.join(', ');
    } else {
      audience = groupData.toString();
    }

    final dotColorRaw = map['dotColor'];
    final dotColorValue = (dotColorRaw is int) ? dotColorRaw : AppColors.primary.toARGB32();

    final dayRaw = map['day'];
    final dayValue = (dayRaw is int) ? dayRaw : ((dayRaw is double) ? dayRaw.toInt() : 0);

    final isCompletedRaw = map['isCompleted'];
    final isCompletedValue = (isCompletedRaw is bool) ? isCompletedRaw : false;

    return EventModel(
      id: docId ?? map['id'] ?? '',
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      time: (start.isNotEmpty && end.isNotEmpty) ? '$start - $end' : (timeVal.isNotEmpty ? timeVal : start),
      venue: map['venue'] ?? '',
      type: map['type'] ?? '',
      club: map['club'] ?? '',
      targetAudience: audience,
      description: map['description'] ?? '',
      dotColor: Color(dotColorValue),
      startTime: start,
      endTime: end,
      day: dayValue,
      isCompleted: isCompletedValue,
    );
  }

  // Helper method to convert the string date and time into a Dart DateTime object.
  DateTime getParsedDateTime() {
    try {
      final timeToParse = startTime.isNotEmpty ? startTime : time;
      final actualTimeToParse = timeToParse.contains(' - ') ? timeToParse.split(' - ')[0] : timeToParse;
      final dateTimeString = '$date $actualTimeToParse';
      return DateFormat('yyyy-MM-dd hh:mm a').parse(dateTimeString);
    } catch (e) {
      return DateTime.now();
    }
  }

  // Returns true if a student with the given degree and group number is targeted by this event.
  bool isStudentTargeted(String studentDegree, int studentGroupNo) {
    final raw = targetAudience.trim();
    if (raw.isEmpty) return true;

    String degreeLimit = 'All';
    List<int> targetGroups = [];

    // Parse encoded representation e.g. "B.Tech: 1, 2, 7"
    if (raw.contains(':')) {
      final parts = raw.split(':');
      degreeLimit = parts[0].trim();
      final groupsPart = parts[1].trim().toLowerCase();
      if (groupsPart != 'all' && groupsPart != 'all members' && groupsPart.isNotEmpty) {
        targetGroups = groupsPart
            .split(RegExp(r'[\s,]+'))
            .map((s) => int.tryParse(s))
            .whereType<int>()
            .toList();
      }
    } else {
      // Backward compatibility for old records (e.g. "6 7" or "all members")
      if (raw.toLowerCase() != 'all' && raw.toLowerCase() != 'all members') {
        targetGroups = raw
            .split(RegExp(r'[\s,]+'))
            .map((s) => int.tryParse(s))
            .whereType<int>()
            .toList();
      }
    }

    // Validate Degree
    if (degreeLimit != 'All') {
      // if (degreeLimit.toLowerCase() != studentDegree.toLowerCase()) {
      if (_normalizeDegree(degreeLimit) != _normalizeDegree(studentDegree)) {
      
        return false;
      }
    }

    // Validate Groups
    if (targetGroups.isNotEmpty) {
      if (!targetGroups.contains(studentGroupNo)) {
        return false;
      }
    }

    return true;
  }
  
  // Returns true if an event matches the student's degree. 
  // It ignores group constraints but still filters by degree.
  bool isDegreeTargeted(String studentDegree) {
    final raw = targetAudience.trim();
    if (raw.isEmpty) return true;

    String degreeLimit = 'All';

    // Parse encoded representation e.g. "B.Tech: 1, 2, 7"
    if (raw.contains(':')) {
      final parts = raw.split(':');
      degreeLimit = parts[0].trim();
    }

    if (degreeLimit != 'All') {
      if (_normalizeDegree(degreeLimit) != _normalizeDegree(studentDegree)) {
        return false;
      }
    }

    return true;
  }

  // Helper method to normalize degree strings for robust comparison
  String _normalizeDegree(String degree) {
    return degree.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  // Returns a user-friendly formatted string representing the targeted audience of this event.
  String getFormattedAudience() {
    final raw = targetAudience.trim();
    if (raw.isEmpty) return 'All Members';

    if (raw.contains(':')) {
      final parts = raw.split(':');
      final degreeLimit = parts[0].trim();
      final groupsPart = parts[1].trim();

      final isAllGroups = groupsPart.toLowerCase() == 'all' || 
                           groupsPart.toLowerCase() == 'all members' || 
                           groupsPart.isEmpty;

      if (degreeLimit == 'All') {
        if (isAllGroups) {
          return 'All Members';
        } else {
          return 'Grp $groupsPart';
        }
      } else {
        if (isAllGroups) {
          return '$degreeLimit All';
        } else {
          return '$degreeLimit Grp $groupsPart';
        }
      }
    } else {
      // Backward compatibility (old representation e.g. "6 7" or "all members")
      if (raw.toLowerCase() == 'all' || raw.toLowerCase() == 'all members') {
        return 'All Members';
      } else {
        final formatted = raw.replaceAll(RegExp(r'\s+'), ', ');
        return 'Grp $formatted';
      }
    }
  }
}
