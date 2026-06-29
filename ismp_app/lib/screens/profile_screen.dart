import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color backgroundColor = Color(0xFF0F0F13);
  static const Color cardColor = Color(0xFF1C1C23);
  static const Color borderColor = Color(0xFF23232D);
  static const Color accentColor = Color(0xFF8B78FF);
  static const Color deepAccentColor = Color(0xFF4A3AFF);

  static const String name = 'Rohan Sharma';
  static const String entryNumber = '24CS1001';
  static const String degree = 'B.Tech';
  static const String branch = 'Computer Science & Engineering';
  static const String groupNumber = 'Group 07';
  static const String stickersCollected = '12/36';

  static const String mentorName = 'Aarav Mehta';
  static const String mentorEntryNumber = '22CS1045';
  static const String mentorEnrollmentNumber = 'IITRPR/2022/CSE/1045';
  static const String mentorPhone = '+91 98765 43210';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStudentCard(),
              const SizedBox(height: 20),
              _buildSectionTitle('Mentor Details'),
              const SizedBox(height: 12),
              _buildMentorCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(radius: 52, iconSize: 56),
              const SizedBox(width: 20),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      entryNumber,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.workspace_premium_outlined,
                          color: Color(0xFFFFC107),
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          stickersCollected,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Stickers",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          _buildDetailRow(
            Icons.school_outlined,
            'Degree',
            degree,
          ),
          _buildDetailRow(
            Icons.account_tree_outlined,
            'Branch',
            branch,
          ),
          _buildDetailRow(
            Icons.groups_2_outlined,
            'Group Number',
            groupNumber,
          ),
        ],
      ),
    );
  }

  Widget _buildMentorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatar(radius: 34, iconSize: 36),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mentorName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      mentorEntryNumber,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildDetailRow(
            Icons.badge_outlined,
            'Enrollment Number',
            mentorEnrollmentNumber,
          ),
          _buildDetailRow(
            Icons.phone_outlined,
            'Phone',
            mentorPhone,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          height: 28,
          width: 4,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar({required double radius, required double iconSize}) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [accentColor, deepAccentColor],
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF2A2A35),
        child: Icon(Icons.person, size: iconSize, color: Colors.white70),
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Icon(
              icon,
              color: Colors.grey.shade500,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}