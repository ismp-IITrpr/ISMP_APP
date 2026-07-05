import 'package:flutter/material.dart';
import '../events.dart';

// Strictly 2 Theme Colors
const Color colorEvent = Color(0xFFB0C4DE); // Deep Accent for Events
const Color colorClub = Color(0xFF8B78FF);  // Primary Purple for Clubs

final Map<int, List<EventModel>> eventsData = {
  1: [
    EventModel(
      id: 'E_orient_1',
      title: 'Orientation Session',
      date: '2024-07-21',
      time: '09:30 AM - 10:30 AM',
      startTime: '09:30 AM',
      endTime: '10:30 AM',
      venue: 'Main Auditorium',
      type: 'E',
      targetAudience: 'General',
      description: 'Welcome session and introduction to college life.',
      dotColor: colorEvent,
    ),
    EventModel(
      id: 'C_math_1',
      title: 'Maths Club',
      date: '2024-07-21',
      time: '11:00 AM - 12:30 PM',
      startTime: '11:00 AM',
      endTime: '12:30 PM',
      venue: 'LH-307',
      type: 'C',
      targetAudience: 'Group 2',
      description: 'First introductory meeting of the Maths Club.',
      dotColor: colorClub,
    ),
    EventModel(
      id: 'C_ard_1',
      title: 'Robotics Club',
      date: '2024-07-21',
      time: '02:00 PM - 03:30 PM',
      startTime: '02:00 PM',
      endTime: '03:30 PM',
      venue: 'Workshop Room',
      type: 'C',
      targetAudience: 'Group 3 4',
      description: 'Hands-on session with basic Arduino projects.',
      dotColor: colorClub,
    ),
  ],
  2: [
    EventModel(
      id: 'C_fb_1',
      title: 'Sports Club - Football',
      date: '2024-07-22',
      time: '04:30 PM - 06:00 PM',
      startTime: '04:30 PM',
      endTime: '06:00 PM',
      venue: 'Sports Complex',
      type: 'C',
      targetAudience: 'Group 5 6',
      description: 'Trials and basic practice for the freshers football team.',
      dotColor: colorClub,
    ),
    EventModel(
      id: 'C_music_1',
      title: 'Music Club',
      date: '2024-07-22',
      time: '07:00 PM - 08:30 PM',
      startTime: '07:00 PM',
      endTime: '08:30 PM',
      venue: 'Music Room',
      type: 'C',
      targetAudience: 'Group 7 8',
      description: 'Open mic and jamming session for all freshers.',
      dotColor: colorClub,
    ),
  ],
  3: [
    EventModel(
      id: 'E_code_1',
      title: 'Coding Contest',
      date: '2024-07-23',
      time: '09:00 PM - 11:00 PM',
      startTime: '09:00 PM',
      endTime: '11:00 PM',
      venue: 'Online',
      type: 'E',
      targetAudience: 'Group 1 3',
      description: 'First competitive programming contest for freshers.',
      dotColor: colorEvent,
    ),
  ],
};
