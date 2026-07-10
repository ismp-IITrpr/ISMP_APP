import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/team_member.dart';

class CoreTeamScreen extends StatelessWidget {
  const CoreTeamScreen({super.key});

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
          backgroundColor: const Color(0xFF15151A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: const Color(0xFF00FFCC).withValues(alpha: 0.3)),
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
                        color: Color(0xFF00FFCC),
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
                style: TextStyle(color: Color(0xFF00FFCC)),
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
      backgroundColor: Colors.transparent, // We will use a Container for the gradient
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2B124C), // Shiny Purple
              Color(0xFF0F0F13), // Midnight Dark
              Color(0xFF1E103C), // Deep Indigo
              Color(0xFF0F0F13), // Midnight Dark
            ],
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // 1. Creative Glowing Orbs
            Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4A3AFF).withValues(alpha: 0.15),
              ),
            ).animate().fadeIn(duration: 2.seconds).scale(begin: const Offset(0.8, 0.8)),
          ),
          Positioned(
            bottom: 200,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00FFCC).withValues(alpha: 0.1), // ISMP Neon Cyan Accent
              ),
            ).animate().fadeIn(duration: 2.seconds, delay: 500.ms).scale(begin: const Offset(0.8, 0.8)),
          ),
          // 2. Heavy Blur Filter for Glassmorphism
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
          // 3. Main Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 120, 24, 40),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A3AFF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF4A3AFF).withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'IIT ROPAR ISMP',
                          style: TextStyle(
                            color: Color(0xFF00FFCC),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.5, curve: Curves.easeOutBack),
                      const SizedBox(height: 20),
                      const Text(
                        'Mentorship\nCore Team',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn(duration: 800.ms, delay: 200.ms).slideY(begin: 0.3, curve: Curves.easeOutExpo),
                    ],
                  ),
                ),
              ),
              
              // Custom Layout for exactly 7 members
              if (coreTeamMembers.length >= 7)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Row 1: Faculty Advisor
                        _buildCreativeMemberCard(context, coreTeamMembers[0], 0),
                        // Student Team (Secretary & Co-Secretaries in rows of 2)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            double itemWidth = (constraints.maxWidth - 16) / 2; 
                            return Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 16,
                              runSpacing: 0,
                              children: [
                                for (int i = 1; i < coreTeamMembers.length; i++)
                                  SizedBox(
                                    width: itemWidth,
                                    child: _buildCreativeMemberCard(context, coreTeamMembers[i], i, scaleMode: 1),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                )
              else 
                // Fallback for different counts
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _buildCreativeMemberCard(context, coreTeamMembers[index], index);
                      },
                      childCount: coreTeamMembers.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ],
      ),
      ),
    );
  }

  // scaleMode: 0 = Full width, 1 = 2 per row, 2 = 3 per row
  Widget _buildCreativeMemberCard(BuildContext context, TeamMember member, int index, {int scaleMode = 0}) {
    if (index == 0) {
      return _buildFacultyCard(context, member);
    }

    bool isSpecial = index == 0 || index == 1; // Faculty and Secretary get the green accent
    
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
                  color: (isSpecial ? const Color(0xFF00FFCC) : const Color(0xFF4A3AFF)).withValues(alpha: 0.05),
                  blurRadius: 40,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isSpecial ? const Color(0xFF00FFCC) : const Color(0xFF4A3AFF)).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (isSpecial ? const Color(0xFF00FFCC) : const Color(0xFF4A3AFF)).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    member.role.toUpperCase(),
                    style: TextStyle(
                      color: isSpecial ? const Color(0xFF00FFCC) : const Color(0xFFB4B0FF),
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
                    if (member.instagram != null && member.instagram!.isNotEmpty)
                      _SocialButton(
                        icon: FaIcon(FontAwesomeIcons.instagram, size: scaleMode > 0 ? 24 : 28, color: const Color(0xFFB4B0FF)),
                        onTap: () => _launchUrl(member.instagram),
                        small: scaleMode > 0,
                      ),
                    if (member.phone != null && member.phone!.isNotEmpty)
                      _SocialButton(
                        icon: FaIcon(FontAwesomeIcons.whatsapp, size: scaleMode > 0 ? 24 : 28, color: const Color(0xFFB4B0FF)),
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
                      color: const Color(0xFF00FFCC).withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 800.ms, delay: (index * 100).ms).slideY(begin: 0.1, curve: Curves.easeOutExpo),
          // Floating Avatar Overlapping Card
          Container(
            margin: const EdgeInsets.only(top: 20),
            padding: EdgeInsets.all(scaleMode == 0 ? 4 : 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isSpecial
                    ? [const Color(0xFF00FFCC), const Color(0xFF00FFCC).withValues(alpha: 0.2)]
                    : [const Color(0xFF4A3AFF), const Color(0xFF00FFCC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSpecial ? const Color(0xFF00FFCC) : const Color(0xFF4A3AFF)).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundImage: AssetImage(member.image),
              backgroundColor: const Color(0xFF15151A),
            ),
          ).animate().fadeIn(duration: 800.ms, delay: (index * 100 + 200).ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
        ],
      ),
    ),
  );
  }

  Widget _buildFacultyCard(BuildContext context, TeamMember member) {
    return GestureDetector(
      onTap: () => _showBioDialog(context, member),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FFCC).withValues(alpha: 0.05),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [const Color(0xFF00FFCC), const Color(0xFF00FFCC).withValues(alpha: 0.2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FFCC).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 64,
                    backgroundImage: AssetImage(member.image),
                    backgroundColor: const Color(0xFF15151A),
                  ),
                ),
                const SizedBox(height: 16),
                if (member.mail != null && member.mail!.isNotEmpty)
                  _SocialButton(
                    icon: const Icon(Icons.mail_outline, size: 28, color: Color(0xFFB4B0FF)),
                    onTap: () => _launchEmail(member.mail),
                    small: false,
                  ),
              ],
            ),
            const SizedBox(width: 24),
            // Right side
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFCC).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00FFCC).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      member.role.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF00FFCC),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (member.bio != null && member.bio!.isNotEmpty) ...[
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
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          height: 1.5,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Click to view more',
                      style: TextStyle(
                        color: const Color(0xFF00FFCC).withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, curve: Curves.easeOutExpo),
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
          color: const Color(0xFF4A3AFF).withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF4A3AFF).withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A3AFF).withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: icon,
      ),
    );
  }
}
