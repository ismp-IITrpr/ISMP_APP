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
}
