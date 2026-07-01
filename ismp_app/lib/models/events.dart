import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventModel {
  final String id;
  final String title; // Represents the club name or event name
  final String date;  // Format: 'yyyy-MM-dd' e.g. '2024-05-21'
  final String time;
  final String venue;
  final String type; // 'E' for Events, 'C' for Club Sessions
  final List<int> groupNo;
  final String description;
  final Color dotColor;

  EventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.venue,
    required this.type,
    required this.groupNo,
    required this.description,
    required this.dotColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'time': time,
      'venue': venue,
      'type': type,
      'groupNo': groupNo,
      'description': description,
      'dotColor': dotColor.toARGB32(),
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return EventModel(
      id: docId ?? map['id'] ?? '',
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      venue: map['venue'] ?? '',
      type: map['type'] ?? '',
      groupNo: List<int>.from(map['groupNo'] ?? []),
      description: map['description'] ?? '',
      dotColor: Color(map['dotColor'] ?? 0xFF4A3AFF),
    );
  }

  // Helper method to convert the string date and time into a Dart DateTime object.
  // Example: date = '2024-05-21', time = '09:30 AM'
  DateTime getParsedDateTime() {
    try {
      final dateTimeString = '$date $time';
      return DateFormat('yyyy-MM-dd hh:mm a').parse(dateTimeString);
    } catch (e) {
      // Fallback if formatting is wrong
      return DateTime.now();
    }
  }
}
