import 'package:flutter/material.dart';

class EventModel {
  final String title;
  final String time;
  final String venue;
  final String type;
  final List<int> groupNo;
  final String description;
  final Color dotColor;

  EventModel({
    required this.title,
    required this.time,
    required this.venue,
    required this.type,
    required this.groupNo,
    required this.description,
    required this.dotColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'time': time,
      'venue': venue,
      'type': type,
      'groupNo': groupNo,
      'description': description,
      'dotColor': dotColor.toARGB32(),
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      title: map['title'] ?? '',
      time: map['time'] ?? '',
      venue: map['venue'] ?? '',
      type: map['type'] ?? '',
      groupNo: List<int>.from(map['groupNo'] ?? []),
      description: map['description'] ?? '',
      dotColor: Color(map['dotColor'] ?? 0xFF4A3AFF),
    );
  }
}

final Map<int, List<EventModel>> eventsData = {
  1: [
    EventModel(
      title: 'Orientation Session',
      time: '09:30 AM',
      venue: 'Main Auditorium',
      type: 'Event',
      groupNo: [1],
      description: 'Welcome session and introduction to the college life.',
      dotColor: const Color(0xFF8B78FF),
    ),
    EventModel(
      title: 'Maths Club Meeting',
      time: '11:00 AM',
      venue: 'LH-307',
      type: 'Club Session',
      groupNo: [2],
      description: 'First introductory meeting of the Maths Club.',
      dotColor: const Color(0xFF8BC34A),
    ),
    EventModel(
      title: 'Arduino Workshop',
      time: '02:00 PM',
      venue: 'Workshop Room',
      type: 'Club Session',
      groupNo: [3, 4],
      description: 'Hands-on session with basic Arduino projects.',
      dotColor: const Color(0xFF2196F3),
    ),
  ],
  2: [
    EventModel(
      title: 'Football Practice',
      time: '04:30 PM',
      venue: 'Sports Complex',
      type: 'Club Session',
      groupNo: [5,6],
      description: 'Trials and basic practice for the freshers football team.',
      dotColor: const Color(0xFFFF9800),
    ),
    EventModel(
      title: 'Music Club Jamming',
      time: '07:00 PM',
      venue: 'Music Room',
      type: 'Club Session',
      groupNo: [7,8],
      description: 'Open mic and jamming session for all freshers.',
      dotColor: const Color(0xFFFF9800),
    ),
  ],
  3: [
    EventModel(
      title: 'Coding Contest',
      time: '09:00 PM',
      venue: 'Online',
      type: 'Event',
      groupNo: [1,3],
      description: 'First competitive programming contest for freshers.',
      dotColor: const Color(0xFFE91E63),
    ),
  ],
};