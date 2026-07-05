import 'package:flutter/material.dart';
import '../models/profile_data.dart';
import 'login_screen.dart';
import 'rep_dashboard.dart';

class RepProfileScreen extends StatelessWidget {
  const RepProfileScreen({super.key});

  static const Color bgColor = Color(0xFF090A0F);
  static const Color surfaceColor = Color(0xFF12131A);
  static const Color iconBgColor = Color(0xFF1C1C23);
  static const Color primaryPurple = Color(0xFF8B78FF);
  static const Color textGray = Color(0xFF8B8B9B);
  static const Color dividerColor = Color(0xFF1A1A24);

  @override
  Widget build(BuildContext context) {
    final user = dummyUser;

    return Scaffold(
      backgroundColor: bgColor,
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
        backgroundColor: bgColor,
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
              _buildSectionHeader('CLUB REP'),
              const SizedBox(height: 16),
              _buildClubCard(user),
              const SizedBox(height: 32),

              // ── Quick Actions ──
              _buildSectionHeader('QUICK ACTIONS'),
              const SizedBox(height: 16),
              _buildCreateEventCard(context),
              const SizedBox(height: 32),

              _buildLogoutButton(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClubCard(UserProfile user) {
    final clubName = user.clubName ?? 'Unknown Club';
    final clubEmail = '${clubName.toLowerCase()}@iitrpr.ac.in';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryPurple.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          // Club avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: primaryPurple.withOpacity(0.4), width: 2),
            ),
            child: const Icon(Icons.groups_outlined, color: primaryPurple, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            clubName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          // REP badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryPurple.withOpacity(0.4)),
            ),
            child: const Text(
              'CLUB REPRESENTATIVE',
              style: TextStyle(
                color: primaryPurple,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.05), height: 1),
          const SizedBox(height: 16),
          // Email
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.email_outlined, color: primaryPurple, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email',
                      style: TextStyle(color: textGray, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clubEmail,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClubInfoCard(String clubName, String clubId) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryPurple.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: primaryPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.groups_outlined,
                  color: primaryPurple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Club',
                      style: TextStyle(
                        color: textGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      clubName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryPurple.withOpacity(0.4)),
                ),
                child: const Text(
                  'REP',
                  style: TextStyle(
                    color: primaryPurple,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.05), height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.badge_outlined, color: primaryPurple, size: 18),
              const SizedBox(width: 10),
              const Text(
                'Club ID',
                style: TextStyle(color: textGray, fontSize: 13),
              ),
              const Spacer(),
              Text(
                clubId,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
          child: Divider(color: dividerColor, thickness: 1, height: 1),
        ),
      ],
    );
  }

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
          _buildDetailRow(Icons.badge_outlined, 'Roll Number', user.rollNo),
          _buildListDivider(),
          _buildDetailRow(Icons.email_outlined, 'Email', 'robotics@iitrpr.ac.in'),
        ],
      ),
    );
  }

  Widget _buildUserHeader(UserProfile user) {
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
                  color: primaryPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryPurple.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_outlined, color: primaryPurple, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Club Representative',
                      style: TextStyle(
                        color: primaryPurple,
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

  Widget _buildListDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 60),
      child: Divider(color: dividerColor, height: 16, thickness: 1),
    );
  }

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
      backgroundImage: url.isNotEmpty
          ? (url.startsWith('http')
              ? NetworkImage(url)
              : AssetImage(url) as ImageProvider)
          : null,
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

  Widget _buildCreateEventCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RepDashboard()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: primaryPurple.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryPurple.withOpacity(0.3),
                    primaryPurple.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryPurple.withOpacity(0.4)),
              ),
              child: const Icon(
                Icons.add_circle_outline_rounded,
                color: primaryPurple,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Event',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Post a new session for your club',
                    style: TextStyle(
                      color: textGray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: textGray,
            ),
          ],
        ),
      ),
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