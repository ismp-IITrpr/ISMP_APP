import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/team_member.dart';
import '../../theme/app_theme.dart';

class DevTeamScreen extends StatelessWidget {
  const DevTeamScreen({super.key});

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _launchEmail(String? email) async {
    if (email == null) return;
    final Uri url = Uri.parse('mailto:$email');
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  void _showBioDialog(BuildContext context, TeamMember member) {
    if (member.bio == null || member.bio!.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          contentPadding: const EdgeInsets.all(24),
          title: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage(member.image),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.role,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Text(
            member.bio!,
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchPhone(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length == 10) cleanPhone = '91$cleanPhone';
    final Uri url = Uri.parse('https://wa.me/$cleanPhone');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Extremely dark sleek background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                  Icons.arrow_back_ios_new, size: 16, color: Colors.white),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 40),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16,
                        vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                          alpha: 0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: AppColors.secondaryAccent.withValues(
                              alpha: 0.3)),
                    ),
                    child: const Text(
                      'IIT ROPAR ISMP',
                      style: TextStyle(
                        color: AppColors.secondaryAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ).animate().fadeIn(duration: 800.ms).slideY(
                      begin: -0.5, curve: Curves.easeOutBack),
                  const SizedBox(height: 20),
                  const Text(
                    'Development\nTeam',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 200.ms)
                      .slideY(begin: 0.3, curve: Curves.easeOutExpo),
                ],
              ),
            ),
          ),

          // Layout for all members (2 per row)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double itemWidth = (constraints.maxWidth - 16) / 2;
                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 0,
                    children: [
                      for (int i = 0; i < devTeamMembers.length; i++)
                        SizedBox(
                          width: itemWidth,
                          child: _buildCreativeMemberCard(
                              context, devTeamMembers[i], i,
                              scaleMode: 1),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // scaleMode: 0 = Full width, 1 = 2 per row, 2 = 3 per row
  Widget _buildCreativeMemberCard(BuildContext context, TeamMember member,
      int index, {int scaleMode = 0}) {
    bool isSpecial = true; // Everyone gets the green accent

    // Dynamic sizing based on row capacity
    double avatarRadius = scaleMode == 0 ? 64 : (scaleMode == 1 ? 64 : 64);
    double nameFontSize = scaleMode == 0 ? 24 : (scaleMode == 1 ? 16 : 13);
    double roleFontSize = scaleMode == 0 ? 10 : (scaleMode == 1 ? 8 : 7);
    double cardTopMargin = scaleMode == 0 ? 65 : (scaleMode == 1 ? 65 : 65);
    double cardPaddingTop = scaleMode == 0 ? 95 : (scaleMode == 1 ? 95 : 95);

    return GestureDetector(
      onTap: () => _showBioDialog(context, member),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Background Card
            Container(
              margin: EdgeInsets.only(top: cardTopMargin),
              padding: EdgeInsets.fromLTRB(10, cardPaddingTop, 10, 24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(
                    color: (isSpecial ? AppColors.primary : const Color(
                        0xFFD9278D)).withValues(alpha: 0.05),
                    blurRadius: 15.0,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    member.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: nameFontSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.secondaryAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      member.role.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.secondaryAccent,
                        fontSize: roleFontSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (member.instagram != null &&
                          member.instagram!.isNotEmpty)
                        _SocialButton(
                          icon: FaIcon(FontAwesomeIcons.instagram,
                              size: scaleMode > 0 ? 24 : 28,
                              color: AppColors.secondaryAccent),
                          onTap: () => _launchUrl(member.instagram),
                          small: scaleMode > 0,
                        ),
                      if (member.phone != null && member.phone!.isNotEmpty)
                        _SocialButton(
                          icon: FaIcon(FontAwesomeIcons.whatsapp,
                              size: scaleMode > 0 ? 24 : 28,
                              color: AppColors.secondaryAccent),
                          onTap: () => _launchPhone(member.phone),
                          small: scaleMode > 0,
                        ),
                    ],
                  ),
                  if (member.bio != null && member.bio!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Colors.transparent],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Text(
                        member.bio!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.clip,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Click to view more',
                      style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 800.ms, delay: (index * 100).ms)
                .slideY(begin: 0.1, curve: Curves.easeOutExpo),
            // Floating Avatar Overlapping Card
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: EdgeInsets.all(scaleMode == 0 ? 4 : 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isSpecial
                      ? [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.2)
                  ]
                      : [AppColors.primary, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isSpecial ? AppColors.primary : const Color(
                        0xFFD9278D)).withValues(alpha: 0.3),
                    blurRadius: 15.0,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundImage: AssetImage(member.image),
                backgroundColor: AppColors.surface,
              ),
            )
                .animate()
                .fadeIn(duration: 800.ms, delay: (index * 100 + 200).ms)
                .scale(
                begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  final bool small;

  const _SocialButton({required this.icon, required this.onTap, this.small = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: EdgeInsets.all(small ? 14 : 18),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.secondaryAccent.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 5.0,
              spreadRadius: 2.0,
            ),
          ],
        ),
        child: icon,
      ),
    );
  }
}
