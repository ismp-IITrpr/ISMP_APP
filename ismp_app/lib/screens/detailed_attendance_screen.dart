import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/attendance.dart';
import '../models/events.dart';

/// ---------------------------------------------------------------------
/// THEME NOTE:
/// These constants mirror the colors already used across Attendance /
/// Profile / Home screens (sampled from the app itself). If you already
/// have a shared `AppColors` / `AppTheme` class, just swap these consts
/// for references to it — the rest of the widget doesn't care where the
/// colors come from.
/// ---------------------------------------------------------------------
class _AppTheme {
  static const Color bg = Color(0xFF0F0F13); // Scaffold background
  static const Color card = Color(0xFF1C1C23); // flat card bg (session tiles, nav bar)
  static const Color cardAlt = Color(0xFF12131A); // flat card bg (profile-style cards)
  static const Color primary = Color(0xFF4A3AFF); // main indigo accent
  static const Color primaryLight = Color(0xFF8B78FF); // lighter lavender accent
  static const Color success = Color(0xFF4CAF50); // "Present" green
  static const Color error = Color(0xFFF44336); // "Absent" red
  static const Color border = Colors.white10; // subtle card border
}

class DetailedAttendanceScreen extends StatelessWidget {
  const DetailedAttendanceScreen({super.key});

  final String currentStudentId = "student_123";

  // All boards now live in the same indigo/violet family as the rest of
  // the app (varying only in brightness), instead of a multi-hue rainbow.
  static const Map<String, List<Map<String, dynamic>>> boardClubs = {
    'BOSA': [
      {'name': 'Athletic', 'emoji': '🏃', 'keywords': ['athletic']},
      {'name': 'Badminton', 'emoji': '🏸', 'keywords': ['badminton']},
      {'name': 'Basketball', 'emoji': '🏀', 'keywords': ['basketball']},
      {'name': 'Chess', 'emoji': '♟️', 'keywords': ['chess']},
      {'name': 'Cricket', 'emoji': '🏏', 'keywords': ['cricket']},
      {'name': 'Football', 'emoji': '⚽', 'keywords': ['football']},
      {'name': 'Hockey', 'emoji': '🏑', 'keywords': ['hockey']},
      {'name': 'Tennis', 'emoji': '🎾', 'keywords': ['tennis']},
      {'name': 'Table Tennis', 'emoji': '🏓', 'keywords': ['table tennis']},
      {'name': 'Volleyball', 'emoji': '🏐', 'keywords': ['volleyball']},
      {'name': 'Weightlifting', 'emoji': '🏋️', 'keywords': ['weightlifting']},
    ],
    'BOLA': [
      {'name': 'Alfaaz', 'emoji': '🎤', 'keywords': ['alfaaz']},
      {'name': 'Alpha', 'emoji': '📖', 'keywords': ['alpha']},
      {'name': 'DebSoc', 'emoji': '🎙️', 'keywords': ['debate', 'debsoc']},
      {'name': 'Ennarators', 'emoji': '📝', 'keywords': ['ennarators']},
      {'name': 'Enigma', 'emoji': '🧩', 'keywords': ['enigma']},
      {'name': 'Filmski', 'emoji': '🎬', 'keywords': ['film', 'filmski']},
      {'name': 'MUN', 'emoji': '🌍', 'keywords': ['mun']},
    ],
    'BOCA': [
      {'name': 'Alankar', 'emoji': '🎵', 'keywords': ['music', 'alankar']},
      {'name': 'Arturo', 'emoji': '🎨', 'keywords': ['art', 'arturo']},
      {'name': "D'Cypher", 'emoji': '💃', 'keywords': ['dance', "d'cypher", 'dcypher']},
      {'name': 'Epicure', 'emoji': '🍽️', 'keywords': ['epicure', 'food']},
      {'name': 'Panache', 'emoji': '✨', 'keywords': ['panache', 'fashion']},
      {'name': 'Undekha', 'emoji': '📸', 'keywords': ['undekha', 'photo']},
      {'name': 'Vibgyor', 'emoji': '🌈', 'keywords': ['vibgyor']},
    ],
    'BOST': [
      {'name': 'Zenith', 'emoji': '🚀', 'keywords': ['zenith']},
      {'name': 'E-Sportz', 'emoji': '🎮', 'keywords': ['esportz', 'e-sportz', 'gaming']},
      {'name': 'Monochrome', 'emoji': '📷', 'keywords': ['monochrome']},
      {'name': 'Robotics', 'emoji': '🤖', 'keywords': ['robotics', 'arduino']},
      {'name': 'Softcom', 'emoji': '💻', 'keywords': ['softcom']},
      {'name': 'Coding Club', 'emoji': '⌨️', 'keywords': ['coding', 'maths']},
      {'name': 'FinCom', 'emoji': '💰', 'keywords': ['fincom', 'finance']},
      {'name': 'CIM', 'emoji': '📊', 'keywords': ['cim']},
      {'name': 'Iota Cluster', 'emoji': '⚡', 'keywords': ['iota']},
      {'name': 'Automotive', 'emoji': '🚗', 'keywords': ['automotive']},
      {'name': 'Aeromodelling', 'emoji': '✈️', 'keywords': ['aero']},
    ],
  };

  static const Map<String, Color> boardColors = {
    'BOSA': _AppTheme.primary, // 0xFF4A3AFF
    'BOLA': Color(0xFF6C5DD3), // deeper violet
    'BOCA': _AppTheme.primaryLight, // 0xFF8B78FF
    'BOST': Color(0xFF7A6CF0), // mid indigo
  };

  static const Map<String, IconData> boardIcons = {
    'BOSA': Icons.sports_soccer_outlined,
    'BOLA': Icons.menu_book_outlined,
    'BOCA': Icons.palette_outlined,
    'BOST': Icons.computer_outlined,
  };

  bool _eventMatchesClub(EventModel event, List<dynamic> keywords) {
    final title = event.title.toLowerCase();
    return keywords.any((k) => title.contains((k as String).toLowerCase()));
  }

  String _getClubStatus(List<dynamic> keywords, List<EventModel> allClubEvents) {
    EventModel? matchedEvent;
    for (var e in allClubEvents) {
      if (_eventMatchesClub(e, keywords)) {
        matchedEvent = e;
        break;
      }
    }
    if (matchedEvent == null) return 'locked';
    final record = recentSessions.firstWhere(
          (r) => r.eventId == matchedEvent!.id,
      orElse: () => AttendanceRecord(eventId: '', eventType: '', isPresent: false),
    );
    if (record.eventId.isEmpty) return 'locked';
    return record.isPresent ? 'present' : 'absent';
  }

  @override
  Widget build(BuildContext context) {
    final allClubEvents = eventsData.values
        .expand((e) => e)
        .where((e) => e.type == 'C')
        .toList();

    int totalStickers = recentSessions.where((r) => r.isPresent).length;

    return Scaffold(
      backgroundColor: _AppTheme.bg,
      appBar: AppBar(
        backgroundColor: _AppTheme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Club Trophy Boards',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'ISMP',
                style: TextStyle(
                  color: _AppTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(duration: 600.ms),
              const SizedBox(height: 4),
              const Text(
                'Sticker Collection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.05),
              const SizedBox(height: 4),
              Text(
                'Attend club sessions to collect stickers & level up!',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ).animate().fadeIn(duration: 600.ms),
              const SizedBox(height: 20),

              // Rank Card
              _buildRankCard(totalStickers)
                  .animate()
                  .fadeIn(duration: 700.ms, delay: 100.ms)
                  .slideY(begin: 0.1),
              const SizedBox(height: 12),

              // Legend
              _buildLegend()
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 200.ms),
              const SizedBox(height: 20),

              // Board sections
              ...boardColors.keys.toList().asMap().entries.map((entry) {
                final index = entry.key;
                final board = entry.value;
                return _buildBoardSection(
                  board,
                  boardColors[board]!,
                  boardIcons[board]!,
                  boardClubs[board]!,
                  allClubEvents,
                ).animate().fadeIn(
                  duration: 700.ms,
                  delay: (300 + index * 100).ms,
                ).slideY(begin: 0.1);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankCard(int totalStickers) {
    // Rank tiers now stay within the app's indigo/violet family
    // (increasing brightness = higher rank) instead of an
    // unrelated gold/cyan palette.
    String tag;
    Color tagColor;
    String emoji;
    String nextRank;
    int needed;

    if (totalStickers >= 36) {
      tag = 'Extraordinary'; tagColor = const Color(0xFFAFA3FF);
      emoji = '⚡'; nextRank = 'Max Rank!'; needed = 0;
    } else if (totalStickers >= 20) {
      tag = 'Legend'; tagColor = const Color(0xFF6C5DD3);
      emoji = '👑'; nextRank = 'Extraordinary'; needed = 36 - totalStickers;
    } else if (totalStickers >= 12) {
      tag = 'Achiever'; tagColor = _AppTheme.primaryLight;
      emoji = '🚀'; nextRank = 'Legend'; needed = 20 - totalStickers;
    } else if (totalStickers >= 5) {
      tag = 'Explorer'; tagColor = _AppTheme.primary;
      emoji = '🌱'; nextRank = 'Achiever'; needed = 12 - totalStickers;
    } else {
      tag = 'Joined'; tagColor = _AppTheme.primaryLight;
      emoji = '👋'; nextRank = 'Explorer'; needed = 5 - totalStickers;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _AppTheme.cardAlt,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _AppTheme.primary.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: _AppTheme.primary.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Emoji badge — matches the avatar-circle treatment used on Profile
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [tagColor, tagColor.withOpacity(0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: tagColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: _AppTheme.card,
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Rank',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tag,
                  style: TextStyle(
                    color: tagColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalStickers / 36,
                    backgroundColor: Colors.white.withOpacity(0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(tagColor),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalStickers / 36 stickers',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (needed > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Next',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nextRank,
                  style: TextStyle(
                    color: tagColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$needed more',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _legendItem(_AppTheme.primary, 'Attended'),
        const SizedBox(width: 16),
        _legendItem(Colors.grey.shade700, 'Missed'),
        const SizedBox(width: 16),
        _legendItem(Colors.grey.shade900, 'Locked'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
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

  Widget _buildBoardSection(
      String boardName,
      Color color,
      IconData icon,
      List<Map<String, dynamic>> clubs,
      List<EventModel> allClubEvents,
      ) {
    int collected = 0;
    for (var club in clubs) {
      if (_getClubStatus(club['keywords'], allClubEvents) == 'present') {
        collected++;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _AppTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _AppTheme.border),
      ),
      child: Column(
        children: [
          // Board header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Icon(icon, color: color, size: 20),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        '${clubs.length} clubs',
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
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.35)),
                  ),
                  child: Text(
                    '$collected / ${clubs.length} ⭐',
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

          Divider(color: _AppTheme.border, height: 1),

          // Sticker grid
          Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: clubs.map((club) {
                final status = _getClubStatus(club['keywords'], allClubEvents);
                return _buildStickerTile(
                  club['name'] as String,
                  club['emoji'] as String,
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

  Widget _buildStickerTile(
      String name,
      String emoji,
      String status,
      Color boardColor,
      ) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    String displayEmoji;
    List<BoxShadow>? shadow;

    switch (status) {
      case 'present':
        bgColor = boardColor.withOpacity(0.12);
        borderColor = boardColor.withOpacity(0.6);
        textColor = Colors.white;
        displayEmoji = emoji;
        shadow = [
          BoxShadow(
            color: boardColor.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ];
        break;
      case 'absent':
        bgColor = _AppTheme.cardAlt;
        borderColor = _AppTheme.border;
        textColor = Colors.grey.shade700;
        displayEmoji = emoji;
        shadow = null;
        break;
      default: // locked
        bgColor = _AppTheme.cardAlt.withOpacity(0.6);
        borderColor = Colors.white.withOpacity(0.04);
        textColor = Colors.grey.shade800;
        displayEmoji = '🔒';
        shadow = null;
    }

    return Opacity(
      opacity: status == 'absent' ? 0.4 : 1.0,
      child: Container(
        width: 74,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: status == 'present' ? 1.5 : 1,
          ),
          boxShadow: shadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(displayEmoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: status == 'present'
                    ? boardColor
                    : Colors.white.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}