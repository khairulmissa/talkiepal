import 'package:flutter/material.dart';
import 'package:talkiepal/game_page.dart';
import 'package:talkiepal/profile_page.dart';
import 'package:talkiepal/beginner/beginner_page.dart';
import 'package:talkiepal/games/widgets/game_scaffold.dart';
import 'package:talkiepal/intermediate/intermediate_page.dart';
import 'package:talkiepal/practice/widgets/practice_scaffold.dart';
import 'package:talkiepal/practice/widgets/score_dialog.dart';
import 'package:talkiepal/pre intermediate/pre_intermediate_page.dart';
import 'package:talkiepal/services/current_kid.dart';
import 'package:talkiepal/services/progress_store.dart';
import 'package:talkiepal/special_sound/specialsound_page.dart';
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

/// How the child did in one game.
class GameProgress {
  final String emoji;
  final String name;

  /// Best stars in one game (0 = not played yet).
  final int bestStars;
  final int plays;
  final GameLook look;

  const GameProgress(this.emoji, this.name, this.bestStars, this.plays, this.look);
}

/// Everything shown on the Progress page, worked out from the child's
/// saved practices and games.
class ProgressData {
  final int stars;
  final int dayStreak;
  final int wordsSaid;
  final int daysThisWeek;

  /// How much the child practiced each day, Monday to Sunday, from 0 to 1.
  final List<double> week;
  final int todayIndex;
  final List<LevelProgress> levels;
  final List<GameProgress> games;
  final List<ProgressBadge> badges;

  const ProgressData({
    required this.stars,
    required this.dayStreak,
    required this.wordsSaid,
    required this.daysThisWeek,
    required this.week,
    required this.todayIndex,
    required this.levels,
    required this.games,
    required this.badges,
  });

  // Every level with its topics, in menu order.
  static final List<(PracticeLook, List<String>)> _levels = [
    (PracticeLook.beginner, BeginnerPage.topics),
    (PracticeLook.preIntermediate, PreIntermediatePage.topics),
    (PracticeLook.intermediate, IntermediatePage.topics),
    (PracticeLook.specialSound, SpecialSoundPage.topics),
  ];

  // Every game, named as on its results screen.
  static const List<(String, String, GameLook)> _games = [
    ('🔊', 'Sound Matcher', GameLook.soundMatcher),
    ('👂', 'Minimal Pairs', GameLook.minimalPairs),
    ('👍', 'Yes or No', GameLook.yesOrNo),
    ('🦕', 'Feed the Dino', GameLook.feedDino),
    ('🚀', 'Voice Rocket', GameLook.voiceRocket),
    ('🎈', 'Pop the Balloon', GameLook.popBalloon),
  ];

  /// A full bar in "This week" is this much practice in a day.
  static const Duration _fullDay = Duration(minutes: 15);

  factory ProgressData.fromSessions(List<SessionRecord> sessions, {DateTime? now}) {
    final today = _day(now ?? DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));

    // Days the child practiced or played, and for how long.
    final timeByDay = <DateTime, Duration>{};
    for (final s in sessions) {
      final day = _day(s.finishedAt);
      // A session shorter than a second still counts as practice that day.
      final time = s.time < const Duration(seconds: 1) ? const Duration(seconds: 1) : s.time;
      timeByDay[day] = (timeByDay[day] ?? Duration.zero) + time;
    }

    final week = [
      for (var i = 0; i < 7; i++)
        ((timeByDay[monday.add(Duration(days: i))] ?? Duration.zero).inSeconds / _fullDay.inSeconds).clamp(0.0, 1.0),
    ];
    final daysThisWeek = [
      for (var i = 0; i < 7; i++) monday.add(Duration(days: i)),
    ].where(timeByDay.containsKey).length;

    final practices = sessions.where((s) => !s.isGame).toList();
    final wordsSaid = practices.fold(0, (sum, s) => sum + s.wordsSaid);
    final streak = _streak(timeByDay.keys.toSet(), today);

    bool did(String level, String topic, {int score = 0}) =>
        practices.any((s) => s.level == level && s.topic == topic && s.score >= score);

    final games = [
      for (final (emoji, name, look) in _games)
        () {
          final played = sessions.where((s) => s.isGame && s.topic == name).toList();
          final best = played.fold(0, (b, s) => s.stars > b ? s.stars : b);
          return GameProgress(emoji, name, best, played.length, look);
        }(),
    ];

    return ProgressData(
      stars: sessions.fold(0, (sum, s) => sum + s.stars),
      dayStreak: streak,
      wordsSaid: wordsSaid,
      daysThisWeek: daysThisWeek,
      week: week,
      todayIndex: today.weekday - 1,
      levels: [
        for (final (look, topics) in _levels)
          LevelProgress(
            look.letter,
            look.name,
            topics.where((t) => did(look.name, t)).length,
            topics.length,
            look.color,
            look.darkColor,
          ),
      ],
      games: games,
      badges: [
        ProgressBadge('🌱', 'First Word', practices.any((s) => s.wordsSaid > 0)),
        ProgressBadge('🔤', 'ABC Star', did('Beginner', 'Alphabets', score: ScoreBand.pass)),
        ProgressBadge('🔥', '5 Day Streak', _bestStreak(timeByDay.keys.toSet()) >= 5),
        ProgressBadge('🐍', 'S Sound', did('Special Sound', 'Sound S', score: ScoreBand.great)),
        ProgressBadge('🦁', 'L Sound', did('Special Sound', 'Sound L', score: ScoreBand.great)),
        ProgressBadge('🎮', 'Game Fan', games.every((g) => g.plays > 0)),
        ProgressBadge('🏆', 'Super Talker', wordsSaid >= 100),
      ],
    );
  }

  static DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

  /// Days in a row up to today (or yesterday, if today is not done yet).
  static int _streak(Set<DateTime> days, DateTime today) {
    var day = days.contains(today) ? today : today.subtract(const Duration(days: 1));
    var count = 0;
    while (days.contains(day)) {
      count++;
      day = _day(day.subtract(const Duration(hours: 12)));
    }
    return count;
  }

  /// Most days in a row ever.
  static int _bestStreak(Set<DateTime> days) {
    var best = 0;
    for (final day in days) {
      // Count only from the first day of each run.
      if (days.contains(_day(day.subtract(const Duration(hours: 12))))) continue;
      var count = 0;
      var d = day;
      while (days.contains(d)) {
        count++;
        d = _day(d.add(const Duration(hours: 36)));
      }
      if (count > best) best = count;
    }
    return best;
  }
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

  ProgressData data = ProgressData.fromSessions(const []);
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<SessionRecord> sessions;
    try {
      sessions = await ProgressStore.instance.sessions();
    } catch (e) {
      debugPrint('[Progress] could not load: $e');
      sessions = const [];
    }
    if (!mounted) return;
    setState(() {
      data = ProgressData.fromSessions(sessions);
      isLoading = false;
    });
  }

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
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 120),
                            child: Center(child: CircularProgressIndicator(color: _teal)),
                          )
                        else ...[
                          _buildDinoCard(),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _buildStatTile(
                                '⭐',
                                '${data.stars}',
                                'Stars',
                                const Color(0xFFFFF3D6),
                                const Color(0xFFFFCC80),
                              ),
                              const SizedBox(width: 12),
                              _buildStatTile(
                                '🔥',
                                '${data.dayStreak}',
                                'Day streak',
                                const Color(0xFFFFE0E6),
                                const Color(0xFFF48FB1),
                              ),
                              const SizedBox(width: 12),
                              _buildStatTile(
                                '🗣️',
                                '${data.wordsSaid}',
                                'Words said',
                                const Color(0xFFE3F2FD),
                                const Color(0xFF90CAF9),
                              ),
                            ],
                          ),
                          _buildSectionTitle('My levels 🦖'),
                          _buildCard(Column(children: [for (final level in data.levels) _buildLevelBar(level)])),
                          _buildSectionTitle('My games 🎮'),
                          GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.92,
                            children: [for (final game in data.games) _buildGame(game)],
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
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), shape: BoxShape.circle),
            child: const DinoMascot(color: Color(0xFF80CBC4), size: 94),
          ),
          const SizedBox(width: 8),
          // Speech bubble
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.daysThisWeek == 0 ? 'Hello! 👋' : 'Great job! 🌟',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _tealDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dinoMessage,
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

  String get _dinoMessage {
    final name = CurrentKid.name ?? 'You';
    final days = data.daysThisWeek;
    if (days == 0) return "Let's practice with Dino today! 🦖";
    return '$name practiced ${days == 1 ? '1 day' : '$days days'} this week!';
  }

  Widget _buildGame(GameProgress game) {
    final played = game.plays > 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: game.look.lightColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: game.look.edgeColor, width: 2.5),
      ),
      // Shrinks to fit on small phones or with large text.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: played ? 1 : 0.5,
              child: Text(game.emoji, style: const TextStyle(fontSize: 28)),
            ),
            Text(
              game.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _ink),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 5; i++)
                  Opacity(
                    opacity: i < game.bestStars ? 1 : 0.2,
                    child: const Text('⭐', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
            Text(
              played ? 'played ${game.plays}×' : 'not yet',
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: _soft),
            ),
          ],
        ),
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
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _ink),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _soft),
            ),
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
                  decoration: BoxDecoration(color: const Color(0xFFF1EAF5), borderRadius: BorderRadius.circular(10)),
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(color: level.color, borderRadius: BorderRadius.circular(10)),
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
            border: Border.all(color: badge.earned ? const Color(0xFFFFCC80) : const Color(0xFFDDDDDD), width: 3),
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
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GamePage()));
        break;
      case KidsTab.progress:
        // Already on this page
        break;
      case KidsTab.profile:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
        break;
    }
  }
}
