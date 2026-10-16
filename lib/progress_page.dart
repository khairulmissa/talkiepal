import 'package:flutter/material.dart';
import 'package:talkiepal/game_page.dart';
import 'package:talkiepal/profile_page.dart';
import 'package:talkiepal/services/current_kid.dart';
import 'package:talkiepal/widgets/dino_mascot.dart';
import 'package:talkiepal/widgets/kids_bottom_nav.dart';

class LevelProgress {
  final String letter;
  final String name;
  final int done;
  final int total;
  final Color color;
  final Color darkColor;

  const LevelProgress(this.letter, this.name, this.done, this.total, this.color, this.darkColor);
}

class ProgressBadge {
  final String emoji;
  final String name;
  final bool earned;

  const ProgressBadge(this.emoji, this.name, this.earned);
}

/// Everything shown on the Progress page.
class ProgressData {
  final String kidName;
  final int stars;
  final int dayStreak;
  final int wordsSaid;
  final int daysThisWeek;

  /// How much the child practised each day, Monday to Sunday, from 0 to 1.
  final List<double> week;
  final int todayIndex;
  final List<LevelProgress> levels;
  final List<ProgressBadge> badges;

  const ProgressData({
    required this.kidName,
    required this.stars,
    required this.dayStreak,
    required this.wordsSaid,
    required this.daysThisWeek,
    required this.week,
    required this.todayIndex,
    required this.levels,
    required this.badges,
  });

  /// Sample numbers until practice results are saved.
  static const ProgressData sample = ProgressData(
    kidName: 'Aisyah',
    stars: 128,
    dayStreak: 5,
    wordsSaid: 64,
    daysThisWeek: 5,
    week: [0.5, 0.8, 0.3, 0.9, 0.6, 0.0, 0.0],
    todayIndex: 4,
    levels: [
      LevelProgress('A', 'Beginner', 34, 40, Color(0xFF4CAF50), Color(0xFF2E7D32)),
      LevelProgress('B', 'Pre Intermediate', 18, 40, Color(0xFF42A5F5), Color(0xFF1565C0)),
      LevelProgress('C', 'Intermediate', 7, 35, Color(0xFFFF8A3D), Color(0xFFD84315)),
      LevelProgress('D', 'Special Sound', 3, 16, Color(0xFFD81B8C), Color(0xFF9C1361)),
    ],
    badges: [
      ProgressBadge('🌱', 'First Word', true),
      ProgressBadge('🔤', 'ABC Star', true),
      ProgressBadge('🔥', '5 Day Streak', true),
      ProgressBadge('🐍', 'S Sound', false),
      ProgressBadge('🦁', 'L Sound', false),
      ProgressBadge('🏆', 'Super Talker', false),
    ],
  );
}

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  static const Color _cream = Color(0xFFFFF8EC);
  static const Color _teal = Color(0xFF26A69A);
  static const Color _tealDark = Color(0xFF00796B);
  static const Color _ink = Color(0xFF4A3B57);
  static const Color _soft = Color(0xFF7A6A85);
  static const List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final ProgressData data = ProgressData.sample;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          // Soft coloured circles in the background
          Positioned(top: -50, right: -50, child: _buildBlob(170, const Color(0xFFE0F2F1))),
          Positioned(top: 520, left: -80, child: _buildBlob(160, const Color(0xFFFFE0F0))),
          Positioned(bottom: 140, right: -60, child: _buildBlob(170, const Color(0xFFE3EEFF))),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('📊', style: TextStyle(fontSize: 28)),
                            SizedBox(width: 10),
                            Text(
                              'My Progress',
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _tealDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDinoCard(),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _buildStatTile('⭐', '${data.stars}', 'Stars',
                                const Color(0xFFFFF3D6), const Color(0xFFFFCC80)),
                            const SizedBox(width: 12),
                            _buildStatTile('🔥', '${data.dayStreak}', 'Day streak',
                                const Color(0xFFFFE0E6), const Color(0xFFF48FB1)),
                            const SizedBox(width: 12),
                            _buildStatTile('🗣️', '${data.wordsSaid}', 'Words said',
                                const Color(0xFFE3F2FD), const Color(0xFF90CAF9)),
                          ],
                        ),
                        _buildSectionTitle('My levels 🦖'),
                        _buildCard(
                          Column(children: [for (final level in data.levels) _buildLevelBar(level)]),
                        ),
                        _buildSectionTitle('This week 📅'),
                        _buildCard(
                          SizedBox(
                            height: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (var i = 0; i < _days.length; i++)
                                  _buildDayBar(_days[i], data.week[i], i == data.todayIndex),
                              ],
                            ),
                          ),
                        ),
                        _buildSectionTitle('My badges 🏅'),
                        _buildCard(
                          Wrap(
                            spacing: 8,
                            runSpacing: 12,
                            alignment: WrapAlignment.spaceAround,
                            children: [for (final badge in data.badges) _buildBadge(badge)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                KidsBottomNav(selected: KidsTab.progress, onTap: _onNavTap),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildDinoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF80CBC4), _teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(color: _tealDark, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 110,
            height: 110,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: const DinoMascot(color: Color(0xFF80CBC4), size: 94),
          ),
          const SizedBox(width: 8),
          // Speech bubble
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Great job! 🌟',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _tealDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${CurrentKid.name ?? data.kidName} practised ${data.daysThisWeek} days this week!',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5D4E6D)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String emoji, String value, String label, Color background, Color edge) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _ink)),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _soft)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF6B4C7A)),
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Color(0xFFE6DCEB), offset: Offset(0, 5))],
      ),
      child: child,
    );
  }

  Widget _buildLevelBar(LevelProgress level) {
    final progress = level.total == 0 ? 0.0 : (level.done / level.total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: level.color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: level.darkColor, offset: const Offset(0, 3))],
            ),
            child: Text(
              level.letter,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      level.name,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: level.darkColor),
                    ),
                    const Spacer(),
                    Text(
                      '${level.done} / ${level.total}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _soft),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 14,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1EAF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: level.color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayBar(String day, double amount, bool isToday) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 26,
          // A small bar even on days with no practice, so every day is visible.
          height: 90 * amount.clamp(0.05, 1.0),
          decoration: BoxDecoration(
            color: isToday ? _teal : const Color(0xFFB2DFDB),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isToday ? _tealDark : _soft),
        ),
      ],
    );
  }

  Widget _buildBadge(ProgressBadge badge) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: badge.earned ? const Color(0xFFFFF3D6) : const Color(0xFFEEEEEE),
            shape: BoxShape.circle,
            border: Border.all(
              color: badge.earned ? const Color(0xFFFFCC80) : const Color(0xFFDDDDDD),
              width: 3,
            ),
          ),
          child: Opacity(
            opacity: badge.earned ? 1 : 0.3,
            child: Text(badge.emoji, style: const TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 72,
          child: Text(
            badge.name,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: badge.earned ? _ink : _soft),
          ),
        ),
      ],
    );
  }

  void _onNavTap(KidsTab tab) {
    switch (tab) {
      case KidsTab.home:
        goToKidsHome(context);
        break;
      case KidsTab.game:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GamePage()),
        );
        break;
      case KidsTab.progress:
        // Already on this page
        break;
      case KidsTab.profile:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }
}
