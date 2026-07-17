import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/attendance.dart';
import '../services/firebase_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Total stickers that can be collected across all clubs.
const int TOTAL_STICKERS = 36;

class DetailedAttendanceScreen extends StatelessWidget {
  const DetailedAttendanceScreen({super.key});

  // ── Club data per board ──────────────────────────────────────────────
  // 'image' is the filename inside assets/images/clubs/
  // Matching is done by exact club name against attendance record title.
  static const Map<String, List<Map<String, dynamic>>> boardClubs = {
    'BOLA': [
      {'name': 'Alfaaz', 'image': 'alfaaz.png'},
      {'name': 'Alpha', 'image': 'alpha.png'},
      {'name': 'DebSoc', 'image': 'debsoc.png'},
      {'name': 'Ennarators', 'image': 'enn.png'},
      {'name': 'Enigma', 'image': 'enigma.png'},
      {'name': 'Filmski', 'image': 'filmski.png'},
      {'name': 'MUN', 'image': 'mun.png'},
    ],
    'BOCA': [
      {'name': 'Alankar', 'image': 'alankar.png'},
      {'name': 'Arturo', 'image': 'arturo.png'},
      {'name': "D'Cypher", 'image': 'dcypher.png'},
      {'name': 'Epicure', 'image': 'epicure.png'},
      {'name': 'Panache', 'image': 'panache.png'},
      {'name': 'Undekha', 'image': 'undekha.png'},
      {'name': 'Vibgyor', 'image': 'vibgyor.png'},
    ],
    'BOST': [
      {'name': 'Zenith', 'image': 'zenith.png'},
      {'name': 'E-Sportz', 'image': 'esportz.png'},
      {'name': 'Monochrome', 'image': 'monochrome.png'},
      {'name': 'Robotics', 'image': 'robotics.png'},
      {'name': 'Softcom', 'image': 'softcom.png'},
      {'name': 'Coding Club', 'image': 'coding.png'},
      {'name': 'FinCom', 'image': 'fincom.png'},
      {'name': 'CIM', 'image': 'cim.png'},
      {'name': 'Iota Cluster', 'image': 'iota.png'},
      {'name': 'Automotive', 'image': 'auto.png'},
      {'name': 'Aeromodelling', 'image': 'aero.png'},
    ],
    'BOSA': [
      {'name': 'Athletic', 'image': 'athletics.png'},
      {'name': 'Badminton', 'image': 'badminton.png'},
      {'name': 'Basketball', 'image': 'basketball.png'},
      {'name': 'Chess', 'image': 'chess.png'},
      {'name': 'Cricket', 'image': 'cricket.png'},
      {'name': 'Football', 'image': 'football.png'},
      {'name': 'Hockey', 'image': 'hockey.png'},
      {'name': 'Tennis', 'image': 'tennis.png'},
      {'name': 'Table Tennis', 'image': 'tt.png'},
      {'name': 'Volleyball', 'image': 'volleyball.png'},
      {'name': 'Weightlifting', 'image': 'wieght.png'},
    ],
  };

  // Board accent colors — all in the indigo/violet family
  static const Map<String, Color> boardColors = {
    'BOSA': AppColors.primary,
    'BOLA': AppColors.primary,
    'BOCA': AppColors.primary,
    'BOST': AppColors.primary,
  };

  // Board full names for display
  static const Map<String, String> boardFullNames = {
    'BOSA': 'Board of Sports Activities',
    'BOLA': 'Board of Literary Activities',
    'BOCA': 'Board of Cultural Activities',
    'BOST': 'Board of Science & Technology',
  };

  /// Returns 'present', 'absent', or 'locked' for a club.
  /// Matches attendance record title exactly with the club name.
  String _getClubStatus(String clubName, List<AttendanceRecord> records) {
    for (var record in records) {
      if (record.club.trim().toLowerCase() == clubName.trim().toLowerCase()) {
        return record.isPresent ? 'present' : 'absent';
      }
    }
    return 'locked';
  }

  /// Counts how many stickers are collected (status == 'present') across all boards.
  int _countCollectedStickers(List<AttendanceRecord> records) {
    int count = 0;
    for (var clubs in boardClubs.values) {
      for (var club in clubs) {
        if (_getClubStatus(club['name'] as String, records) == 'present') {
          count++;
        }
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final rollNo = FirebaseService.instance.currentStudentRollNo;

    return FutureBuilder<List<AttendanceRecord>>(
      future: DatabaseService().getPersistentStudentAttendanceRecords(rollNo),
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];
        final int collected = _countCollectedStickers(records);

        return Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              centerTitle: true,
              title: const Text(
                'Sticker Collection',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stickers Collected Header ──
                    _buildStickersHeader(collected)
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: -0.05),
                    const SizedBox(height: 20),

                    // ── Legend ──
                    _buildLegend()
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 100.ms),
                    const SizedBox(height: 24),

                    // ── Board Sections ──
                    ...boardClubs.keys.toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final board = entry.value;
                      return _buildBoardSection(
                        board,
                        boardColors[board]!,
                        boardClubs[board]!,
                        records,
                      ).animate().fadeIn(
                        duration: 700.ms,
                        delay: (200 + index * 120).ms,
                      ).slideY(begin: 0.08);
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Stickers Collected Header ──────────────────────────────────────
  Widget _buildStickersHeader(int collected) {
    final double progress = collected / TOTAL_STICKERS;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Sticker icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stickers Collected',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$collected',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: ' / $TOTAL_STICKERS',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).toInt()}% complete',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Legend ──────────────────────────────────────────────────────────
  Widget _buildLegend() {
    return Row(
      children: [
        _legendDot(AppColors.primary, 'Collected'),
        const SizedBox(width: 20),
        _legendDot(Colors.grey.shade700, 'Missed'),
        const SizedBox(width: 20),
        _legendDot(Colors.grey.shade800.withValues(alpha: 0.5), 'Locked'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        ),
      ],
    );
  }

  // ── Board Section ──────────────────────────────────────────────────
  Widget _buildBoardSection(
    String boardName,
    Color color,
    List<Map<String, dynamic>> clubs,
    List<AttendanceRecord> records,
  ) {
    int collected = 0;
    for (var club in clubs) {
      if (_getClubStatus(club['name'] as String, records) == 'present') {
        collected++;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          // Board header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // Board logo in a circular frame
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    backgroundImage: AssetImage('assets/images/clubs/$boardName.png'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        boardName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        boardFullNames[boardName] ?? '',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Score badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    '$collected / ${clubs.length}',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),

          // Club stickers grid
          Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 12,
              runSpacing: 14,
              children: clubs.map((club) {
                final status = _getClubStatus(club['name'] as String, records);
                return _buildStickerTile(
                  club['name'] as String,
                  club['image'] as String,
                  status,
                  color,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Individual Sticker Tile ────────────────────────────────────────
  Widget _buildStickerTile(
    String name,
    String imagePath,
    String status,
    Color boardColor,
  ) {
    final bool isPresent = status == 'present';
    final bool isAbsent = status == 'absent';

    // Colors based on status
    Color borderColor;
    List<BoxShadow>? shadow;

    if (isPresent) {
      borderColor = boardColor;
      shadow = [
        BoxShadow(
          color: boardColor.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    } else if (isAbsent) {
      borderColor = Colors.grey.shade800;
      shadow = null;
    } else {
      borderColor = Colors.white.withValues(alpha: 0.04);
      shadow = null;
    }

    return SizedBox(
      width: 74,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular club image
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor,
                width: isPresent ? 2.5 : 1.5,
              ),
              boxShadow: shadow,
            ),
            child: Opacity(
              opacity: isPresent ? 1.0 : (isAbsent ? 0.3 : 0.15),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                backgroundImage: AssetImage('assets/images/clubs/$imagePath'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Club name
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isPresent
                  ? Colors.white
                  : (isAbsent ? Colors.grey.shade600 : Colors.grey.shade800),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          // Status indicator dot
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPresent
                  ? boardColor
                  : (isAbsent
                      ? Colors.grey.shade700
                      : Colors.white.withValues(alpha: 0.08)),
            ),
          ),
        ],
      ),
    );
  }
}