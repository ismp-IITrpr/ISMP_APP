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
}

class UserProfile {
  final String name;
  final String rollNo;
  final String degree;
  final String branch;
  final int groupNo;
  final int stickersCollected;
  final String profileUrl;
  final MentorProfile? mentor;

  UserProfile({
    required this.name,
    required this.rollNo,
    required this.degree,
    required this.branch,
    required this.groupNo,
    required this.stickersCollected,
    required this.profileUrl,
    this.mentor,
  });
}

// Dummy data for now
final MentorProfile dummyMentor = MentorProfile(
  name: 'Aarav Mehta',
  rollNo: '22CS1045',
  contactNo: '+91 98765 43210',
  profileUrl: '', // Placeholder for actual image URL
);

final UserProfile dummyUser = UserProfile(
  name: 'Rohan Sharma',
  rollNo: '24CS1001',
  degree: 'B.Tech',
  branch: 'Computer Science & Engineering',
  groupNo: 7,
  stickersCollected: 12,
  profileUrl: '', // Placeholder
  mentor: dummyMentor,
);
