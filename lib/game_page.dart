import 'package:flutter/material.dart';
import 'package:talkiepal/games/minimal_pairs_game.dart';
import 'package:talkiepal/games/sound_matcher_game.dart';
import 'package:talkiepal/games/yes_no_game.dart';
import 'package:talkiepal/profile_page.dart';
import 'package:talkiepal/widgets/dino_mascot.dart';
import 'package:talkiepal/widgets/kids_bottom_nav.dart';
import 'package:talkiepal/progress_page.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _Game {
  final String emoji;
  final String title;
  final String subtitle;
  final String skill;
  final Color background;
  final Color edge;
  final Color skillColor;

  // Opens the game; null means it is not ready yet.
  final WidgetBuilder? page;

  const _Game(this.emoji, this.title, this.subtitle, this.skill, this.background, this.edge, this.skillColor,
      {this.page});
}

Widget _soundMatcherPage(BuildContext context) => const SoundMatcherGame();
Widget _yesNoPage(BuildContext context) => const YesNoGame();
Widget _minimalPairsPage(BuildContext context) => const MinimalPairsGame();

class _GamePageState extends State<GamePage> {
  static const Color _cream = Color(0xFFFFF8EC);
  static const Color _purple = Color(0xFF8E5CD9);
  static const Color _purpleDark = Color(0xFF5E35B1);
  static const Color _purpleLight = Color(0xFFB39DDB);

  static const List<_Game> _games = [
    _Game('🔊', 'Sound Matcher', 'Hear it, find it!', '👂 Listen',
        Color(0xFFE3F2FD), Color(0xFF90CAF9), Color(0xFF1E88E5), page: _soundMatcherPage),
    _Game('👂', 'Minimal Pairs', 'Cat or Rat?', '👂 Listen',
        Color(0xFFFFE0E6), Color(0xFFF48FB1), Color(0xFFD81B60), page: _minimalPairsPage),
    _Game('👍', 'Yes or No?', 'Is it a cat?', '🧠 Think',
        Color(0xFFE8F5E9), Color(0xFFA5D6A7), Color(0xFF43A047), page: _yesNoPage),
    _Game('🦕', 'Feed the Dino', 'Dino is hungry!', '🍎 Words',
        Color(0xFFFFF3D6), Color(0xFFFFCC80), Color(0xFFF57C00)),
    _Game('🚀', 'Voice Rocket', 'Use your voice!', '🗣️ Voice',
        Color(0xFFF3E5F5), Color(0xFFCE93D8), Color(0xFF8E24AA)),
    _Game('🎈', 'Pop the Balloon', 'Pop the S sounds!', '🔤 Sounds',
        Color(0xFFE0F7FA), Color(0xFF80DEEA), Color(0xFF00897B)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          // Soft coloured circles in the background
          Positioned(top: -50, right: -50, child: _buildBlob(170, const Color(0xFFEDE7F6))),
          Positioned(top: 460, left: -80, child: _buildBlob(160, const Color(0xFFFFE0F0))),
          Positioned(bottom: 120, right: -60, child: _buildBlob(170, const Color(0xFFE3EEFF))),
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
                            Text('🎮', style: TextStyle(fontSize: 28)),
                            SizedBox(width: 10),
                            Text(
                              'Game Zone',
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _purpleDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDinoCard(),
                        const SizedBox(height: 24),
                        const Text(
                          'Choose your game ⭐',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF6B4C7A)),
                        ),
                        const SizedBox(height: 14),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.84,
                          children: [for (final game in _games) _buildGameTile(game)],
                        ),
                      ],
                    ),
                  ),
                ),
                KidsBottomNav(selected: KidsTab.game, onTap: _onNavTap),
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
          colors: [_purpleLight, _purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(color: _purpleDark, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            height: 120,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: const DinoMascot(color: Color(0xFFB794F6), size: 104),
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Let's play! 🎉",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _purpleDark),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pick a game and talk with me!',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5D4E6D)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameTile(_Game game) {
    return GestureDetector(
      onTap: () => _openGame(game),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: game.background,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [BoxShadow(color: game.edge, offset: const Offset(0, 6))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Text(game.emoji, style: const TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 8),
            Text(
              game.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF4A3B57), height: 1.1),
            ),
            const SizedBox(height: 2),
            Text(
              game.subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7A6A85)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: game.skillColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                game.skill,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNavTap(KidsTab tab) {
    switch (tab) {
      case KidsTab.home:
        goToKidsHome(context);
        break;
      case KidsTab.game:
        // Already on this page
        break;
      case KidsTab.progress:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProgressPage()),
        );
        break;
      case KidsTab.profile:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  void _openGame(_Game game) {
    final page = game.page;
    if (page == null) {
      _showComingSoon(game.title);
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: page));
  }

  void _showComingSoon(String gameName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$gameName coming soon! 🎮'),
        backgroundColor: _purple,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}