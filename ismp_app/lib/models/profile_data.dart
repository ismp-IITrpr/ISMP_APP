import 'package:cloud_firestore/cloud_firestore.dart';

class MentorProfile {
  final String name;
  final String rollNo;
  final String contactNo;
  final String profileUrl;

  MentorProfile({
    required this.name,
    required this.rollNo,
    required this.contactNo,
    required this.profileUrl,
  });

  // THE TRANSLATOR: Converts raw Firebase data into a MentorProfile object
  factory MentorProfile.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return MentorProfile(
      name: data['name'] ?? '',
      rollNo: doc.id, // We use their actual Roll Number as the Firebase Document ID
      contactNo: data['contactNo'] ?? '',
      profileUrl: data['profileUrl'] ?? '',
    );
  }
}

class UserProfile {
  final String name;
  final String rollNo;
  final String degree;
  final String branch;
  final int groupNo;
  final int stickersCollected;
  final String profileUrl;
  final String? mentorRollNo; // We just store the ID (Roll No) of their mentor here
  MentorProfile? mentor; // The app will hold the full mentor object here later

  UserProfile({
    required this.name,
    required this.rollNo,
    required this.degree,
    required this.branch,
    required this.groupNo,
    required this.stickersCollected,
    required this.profileUrl,
    this.mentorRollNo,
    this.mentor,
  });

  // THE TRANSLATOR: Converts raw Firebase data into a UserProfile object
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      name: data['name'] ?? '',
      rollNo: doc.id,
      degree: data['degree'] ?? '',
      branch: data['branch'] ?? '',
      groupNo: data['groupNo'] ?? 0,
      stickersCollected: data['stickersCollected'] ?? 0,
      profileUrl: data['profileUrl'] ?? '',
      mentorRollNo: data['mentorRollNo'], // Grabs the assigned mentor's ID
    );
  }
}

// Dummy data for now
final MentorProfile dummyMentor = MentorProfile(
  name: 'Aarav Mehta',
  rollNo: '22CS1045',
  contactNo: '+91 98765 43210',
  profileUrl: '',
);

final UserProfile dummyUser = UserProfile(
  name: 'Rohan Sharma',
  rollNo: '24CS1001',
  degree: 'B.Tech',
  branch: 'Computer Science & Engineering',
  groupNo: 7,
  stickersCollected: 12,
  profileUrl: '',
  mentor: dummyMentor,
);