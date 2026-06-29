class TeamMember {
  final String name;
  final String role;
  final String image;
  final String? linkedin;
  final String? instagram;
  final String? mail;
  final String? phone;
  final String? bio;

  const TeamMember({
    required this.name,
    required this.role,
    required this.image,
    this.linkedin,
    this.instagram,
    this.mail,
    this.phone,
    this.bio,
  });
}

final List<TeamMember> coreTeamMembers = [
  TeamMember(
    name: 'Dr. Manmohan Vashisth',
    role: 'FACULTY IN-CHARGE',
    image: 'img/2026/manmohan.jpg',
    mail: 'manmohanvashisth@iitrpr.ac.in',
    bio: 'Dr. Manmohan Vashisth, Assistant Professor in the Mathematics department, IIT Ropar is the faculty incharge of this programme and has taken special interest to help and encourage the students to form this Mentorship Programme. He has made a special effort to prepare the events for counselling of the joining Batch. With his mentorship we ensure that we will counsel the freshers to the best extent possible.',
  ),
  TeamMember(
    name: 'Kanika Nagar',
    role: 'SECRETARY',
    image: 'img/2026/Kanika.jpg',
    phone: '+91 8817929545',
    instagram: 'https://www.instagram.com/kan03_07',
    mail: '2024meb1358@iitrpr.ac.in',
  ),
  TeamMember(
    name: 'Prakhar Garg',
    role: 'CO-SECRETARY',
    image: 'img/2026/Prakhar.jpg',
    phone: '+91 7483231609',
    instagram: 'https://www.instagram.com/prakhargarg01',
    mail: '2024meb1371@iitrpr.ac.in',
  ),
  TeamMember(
    name: 'Shivang Kumar',
    role: 'CO-SECRETARY',
    image: 'img/2026/Shivang.jpg',
    phone: '+91 7979785122',
    instagram: 'https://www.instagram.com/shivang_kr_',
    mail: '2024ceb1049@iitrpr.ac.in',
  ),
  TeamMember(
    name: 'Keisha Nanda',
    role: 'CO-SECRETARY',
    image: 'img/2026/Keisha.jpg',
    phone: '+91 9877937389',
    instagram: 'https://www.instagram.com/keisha__nanda',
    mail: '2024ceb1035@iitrpr.ac.in',
  ),
  TeamMember(
    name: 'Akshit Kumar',
    role: 'CO-SECRETARY',
    image: 'img/2026/Akshit.jpg',
    phone: '+91 8264772777',
    instagram: 'https://www.instagram.com/aknator001',
    mail: '2024eeb1178@iitrpr.ac.in',
  ),
  TeamMember(
    name: 'Vinay',
    role: 'CO-SECRETARY',
    image: 'img/2026/Vinay.jpg',
    phone: '+91 85287521978',
    instagram: 'https://www.instagram.com/vin.ay0606',
    mail: '2024mmb1426@iitrpr.ac.in',
  ),
];
