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

final List<TeamMember> devTeamMembers = [
  TeamMember(
    name: 'Gorish Lamba',
    role: 'DEVELOPER',
    image: 'img/2026/2025CSB1191.jpg',
    phone: '+91 7027155745',
    instagram: 'https://www.instagram.com/glk._.7/?hl=en',
    mail: '2025csb1191@iitrpr.ac.in',
  ),
  TeamMember(
    name: 'Harsh Thapar',
    role: 'DEVELOPER',
    image: 'img/2026/2025CSB1199.jpg',
    phone: '+91 9988841406',
    instagram: 'https://www.instagram.com/harshthapar07?igsh=MXR2dWsxb2E0aHNpZg==',
    mail: '2025csb1199@iitrpr.ac.in',
  ),
  TeamMember(
    name: 'Parag Gupta',
    role: 'DEVELOPER',
    image: 'img/2026/2025CHB1137.jpg',
    phone: '+91 9009826800',
    instagram: 'https://www.instagram.com/p4r4_g?igsh=OGQ3NWR4N2cyNGJ0',
    mail: '2025chb1137@iitrpr.ac.in',
  ),
  TeamMember(
    name: 'Saksham',
    role: 'DEVELOPER',
    image: 'img/2026/2025CSB1251.jpg',
    phone: '+91 7011055687',
    instagram: 'https://www.instagram.com/makshas007?igsh=MW9lbnFycjBqdzk0MA==',
    mail: '2025CSB1251@iitrpr.ac.in',
  ),
  TeamMember(
    name: 'Thoihenba B',
    role: 'DEVELOPER',
    image: 'img/2026/2025ICB1449.jpeg',
    phone: '+91 7348954235',
    instagram: 'https://www.instagram.com/th0i_boi/',
    mail: '2025icb1449@iitrpr.ac.in',
  ),
  TeamMember(
    name: 'Deepti Ashwani',
    role: 'DEVELOPER',
    image: 'img/2026/2025EEB1319.jpg',
    phone: '+91 9696551140',
    instagram: 'https://www.instagram.com/deeptiashwani7?igsh=MTJlcnd2eDlmNTl3eA==',
    mail: '2025eeb1319@iitrpr.ac.in',
  ),
  TeamMember(
    name: 'Vishavpreet Singh',
    role: 'DEVELOPER',
    image: 'img/2026/2025AIB1078.webp',
    phone: '+91 7696146238',
    instagram: 'https://www.instagram.com/mrvishavop1?igsh=MTVwaDB1NGt2ZGYzMA==',
    mail: '2025AIB1078@iitrpr.ac.in',
  ),
  TeamMember(
    name: 'Digvijaya Singh',
    role: 'DEVELOPER',
    image: 'img/2026/2025CSB1188.jpeg',
    phone: '+91 9416316600',
    instagram: 'https://www.instagram.com/digvijaya2007?igsh=Y2FpYnRoankxZHo0',
    mail: '2025csb1188@iitrpr.ac.in',
  ),
  TeamMember(
    name: 'Gurnoor Singh',
    role: 'DEVELOPER',
    image: 'img/2026/2025CSB1196.jpg',
    phone: '+91 9501587214',
    instagram: 'https://www.instagram.com/singh_gnoor/',
    mail: '2025csb1196@iitrpr.ac.in',
  ),
  TeamMember(
    name: 'Jasmine Kaur Dhaliwal',
    role: 'CONTRIBUTOR',
    image: 'img/2026/2025DAB1277.jpg',
    phone: '+91 8360646191',
    instagram: 'instagram.com/dhaliwal.jas_mine/',
    mail: '2025dab1277@iitrpr.ac.in',
  ),
  
];
