import 'package:flutter/material.dart';
import '../events.dart';

final Map<int, List<EventModel>> eventsData = {
  1: [
    EventModel(
      id: 'evt_orient_1',
      title: 'Orientation Session',
      date: '2024-07-21',
      time: '09:30 AM',
      venue: 'Main Auditorium',
      type: 'Event',
      groupNo: [1],
      description: 'Welcome session and introduction to the college life.',
      dotColor: const Color(0xFF8B78FF),
    ),
    EventModel(
      id: 'evt_math_1',
      title: 'Maths Club',
      date: '2024-07-21',
      time: '11:00 AM',
      venue: 'LH-307',
      type: 'Club Session',
      groupNo: [2],
      description: 'First introductory meeting of the Maths Club.',
      dotColor: const Color(0xFF8BC34A),
    ),
    EventModel(
      id: 'evt_ard_1',
      title: 'Robotics Club',
      date: '2024-07-21',
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
      id: 'evt_fb_1',
      title: 'Sports Club - Football',
      date: '2024-07-22',
      time: '04:30 PM',
      venue: 'Sports Complex',
      type: 'Club Session',
      groupNo: [5,6],
      description: 'Trials and basic practice for the freshers football team.',
      dotColor: const Color(0xFFFF9800),
    ),
    EventModel(
      id: 'evt_music_1',
      title: 'Music Club',
      date: '2024-07-22',
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
      id: 'evt_code_1',
      title: 'Coding Club',
      date: '2024-07-23',
      time: '09:00 PM',
      venue: 'Online',
      type: 'Event', // Notice this is 'Event' not 'Club Session', testing the filter
      groupNo: [1,3],
      description: 'First competitive programming contest for freshers.',
      dotColor: const Color(0xFFE91E63),
    ),
  ],
};
