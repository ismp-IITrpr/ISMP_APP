import 'package:flutter/material.dart';
import '../models/profile_data.dart';
import '../screens/rep_access.dart';
import 'login_screen.dart';
import 'events_screen.dart';

class ProfileScreen extends StatelessWidget {
  final bool isRep;

  const ProfileScreen({
    super.key,
    this.isRep = false,
  });

  static const int TOTAL_STICKERS = 36;

  // Colors based on reference images
  static const Color bgColor = Color(0xFF090A0F); // Very dark navy/black
  static const Color surfaceColor = Color(0xFF12131A);
  static const Color iconBgColor = Color(0xFF1C1C23); // Dark background for icons
  static const Color primaryPurple = Color(0xFF8B78FF); // Vibrant purple for icons/text
  static const Color textGray = Color(0xFF8B8B9B);
  static const Color dividerColor = Color(0xFF1A1A24);

  @override
  Widget build(BuildContext context) {
    final user = dummyUser;
    final bool isRep = isCurrentUserRep(user.rollNo);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mentor Profile Section
              if (!isRep && user.mentor != null) ...[
                _buildSectionHeader('YOUR MENTOR'),
                const SizedBox(height: 16),
                _buildMentorContainer(user.mentor!),
                const SizedBox(height: 40),
              ],

              // User Profile Section
              _buildSectionHeader('YOUR PROFILE'),
              const SizedBox(height: 16),
              _buildUserContainer(user),

              // Rep-only quick access — only rendered when isCurrentUserRep
              // is true for this user. No manual toggle anywhere.
              if (isRep) ...[
                const SizedBox(height: 32),
                _buildSectionHeader('CLUB REP'),
                const SizedBox(height: 16),
                _buildRepAccessCard(context),
              ],

              const SizedBox(height: 48),

              // Logout Button
              _buildLogoutButton(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Rep-only card — takes the rep straight to Events, where each club
  // session now shows a "Start Attendance" action.
  Widget _buildRepAccessCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryPurple.withOpacity(0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EventsScreen()),
          );
        },
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: primaryPurple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.event_available_outlined, color: primaryPurple, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Open Rep Events',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Take attendance for your club sessions',
                    style: TextStyle(color: textGray, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: textGray),
          ],
        ),
      ),
    );
  }

  // Header with text and a line in the same row
  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: textGray,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Divider(
            color: dividerColor,
            thickness: 1,
            height: 1,
          ),
        ),
      ],
    );
  }

  // Mentor Profile Container
  Widget _buildMentorContainer(MentorProfile mentor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMentorHeader(mentor),
          const SizedBox(height: 24),
          _buildDetailRow(Icons.badge_outlined, 'Roll Number', mentor.rollNo),
          _buildListDivider(),
          _buildDetailRow(Icons.phone_outlined, 'Contact', mentor.contactNo),
        ],
      ),
    );
  }

  // User Profile Container
  Widget _buildUserContainer(UserProfile user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(user),
          const SizedBox(height: 24),

          if (isRep) ...[
            _buildDetailRow(Icons.groups_outlined, 'Club Name', 'Coding Club'),
            _buildListDivider(),
            _buildDetailRow(Icons.email_outlined, 'Email', 'codingclub@iitrpr.ac.in'),
          ] else ...[
            _buildDetailRow(Icons.badge_outlined, 'Roll Number', user.rollNo),
            _buildListDivider(),
            _buildDetailRow(Icons.school_outlined, 'Degree', user.degree),
            _buildListDivider(),
            _buildDetailRow(Icons.account_tree_outlined, 'Branch', user.branch),
            _buildListDivider(),
            _buildDetailRow(Icons.groups_2_outlined, 'Group No.', "${user.groupNo}"),
          ],
        ],
      ),
    );
  }

  // Mentor Header (Centered Avatar with Name below)
  Widget _buildMentorHeader(MentorProfile mentor) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAvatar(
            name: mentor.name,
            url: mentor.profileUrl,
            radius: 40,
            fontSize: 32,
          ),
          const SizedBox(height: 12),
          Text(
            mentor.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mentor',
            style: TextStyle(
              color: primaryPurple,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // User Header (Avatar, Name, Sticker Pill - without "Student" text)
  Widget _buildUserHeader(UserProfile user) {
    if (isRep) {
      const String clubName = "Coding Club"; // baad mein Firebase se aayega

      return Center(
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: iconBgColor,
              child: Text(
                clubName[0].toUpperCase(),
                style: const TextStyle(
                  color: primaryPurple,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Student ke liye purana UI
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildAvatar(
          name: user.name,
          url: user.profileUrl,
          radius: 36,
          fontSize: 28,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.workspace_premium_outlined,
                      color: primaryPurple,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${user.stickersCollected}/$TOTAL_STICKERS Stickers',
                      style: const TextStyle(
                        color: textGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Detail Row
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryPurple, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: textGray,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Divider inside the list
  Widget _buildListDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 60), // Align divider with text, skip icon
      child: Divider(
        color: dividerColor,
        height: 16,
        thickness: 1,
      ),
    );
  }

  // Helper for Avatars
  Widget _buildAvatar({
    required String name,
    required String url,
    required double radius,
    required double fontSize,
  }) {
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: iconBgColor,
      backgroundImage: url.isNotEmpty ? (url.startsWith('http') ? NetworkImage(url) : AssetImage(url) as ImageProvider) : null,
      child: url.isEmpty
          ? Text(
        initial,
        style: TextStyle(
          color: primaryPurple,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      )
          : null,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: TextButton(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
          );
        },
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFF44336).withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Log Out',
          style: TextStyle(
            color: Color(0xFFF44336),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}