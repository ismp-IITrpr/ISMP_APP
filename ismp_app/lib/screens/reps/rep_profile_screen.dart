import 'package:flutter/material.dart';
import '../login_screen.dart';
import 'rep_dashboard.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class RepProfileScreen extends StatelessWidget {
  const RepProfileScreen({super.key});

  static const Color bgColor = AppColors.background;
  static const Color surfaceColor = AppColors.background;
  static const Color iconBgColor = AppColors.surface;
  static const Color primaryPurple = AppColors.primary;
  static const Color textGray = AppColors.mutedText;
  static const Color dividerColor = AppColors.background;

  @override
  Widget build(BuildContext context) {
    final String email = FirebaseService.instance.currentUserEmail ?? 'robotics@iitrpr.ac.in';
    final String clubName = FirebaseService.instance.getClubForEmail(email);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
              _buildSectionHeader('CLUB REP'),
              const SizedBox(height: 16),
              _buildClubCard(clubName, email),
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

  Widget _buildClubCard(String clubName, String email) {
    final clubEmail = email;

    final googlePhotoUrl = FirebaseService.instance.currentUser?.photoURL ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryPurple.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // Club avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primaryPurple.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: primaryPurple.withValues(alpha: 0.4), width: 2),
            ),
            child: ClipOval(
              child: googlePhotoUrl.isNotEmpty
                  ? Image.network(
                      googlePhotoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to groups icon if loading fails (CORS, network error, etc.)
                        return const Icon(Icons.groups_outlined, color: primaryPurple, size: 40);
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: primaryPurple,
                            strokeWidth: 2,
                          ),
                        );
                      },
                    )
                  : const Icon(Icons.groups_outlined, color: primaryPurple, size: 40),
            ),
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
              color: primaryPurple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.secondaryAccent.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'CLUB REPRESENTATIVE',
              style: TextStyle(
                color: AppColors.secondaryAccent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
          const SizedBox(height: 16),
          // Email
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondaryAccent.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.email_outlined, color: AppColors.secondaryAccent, size: 22),
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
          border: Border.all(color: primaryPurple.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withValues(alpha: 0.08),
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
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.secondaryAccent.withValues(alpha: 0.4)),
              ),
              child: const Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.secondaryAccent,
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
        onPressed: () async {
          await FirebaseService.instance.signOut();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
            );
          }
        },
        style: TextButton.styleFrom(
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Log Out',
          style: TextStyle(
            color: AppColors.error,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}