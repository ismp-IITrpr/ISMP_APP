import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      dotColor: Color(map['dotColor'] ?? 0xFF4A3AFF),
      startTime: start,
      endTime: end,
      day: map['day'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
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
      if (degreeLimit.toLowerCase() != studentDegree.toLowerCase()) {
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
}
