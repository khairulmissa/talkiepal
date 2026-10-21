import 'package:flutter/material.dart';
import 'package:talkiepal/practice/ai_sound_page.dart';
import 'package:talkiepal/widgets/level_menu_page.dart';

class _Sound {
  final String sound;
  final String emoji;
  final String description;

  const _Sound(this.sound, this.emoji, this.description);
}

class SpecialSoundPage extends StatelessWidget {
  const SpecialSoundPage({super.key});

  static const LevelTheme _theme = LevelTheme(
    letter: 'D',
    title: 'Special Sound',
    color: Color(0xFFD81B8C),
    darkColor: Color(0xFF9C1361),
    lightColor: Color(0xFFF06292),
    dinoColor: Color(0xFFE77BC3),
  );

  static const List<_Sound> _level1 = [
    _Sound('R', '🐰', 'The Basic Tricky Sound - Roll your tongue'),
    _Sound('S', '🐍', 'The Hissing Sound - Like a snake'),
    _Sound('L', '🦁', 'The Light Sound - Tongue touches top'),
  ];

  static const List<_Sound> _level2 = [
    _Sound('TH', '👍', 'The Biting Sound - Tongue between teeth'),
    _Sound('SH', '🤫', 'The Quiet Sound - Like "shhh"'),
    _Sound('CH', '🚂', 'The Train Sound - Like a choo-choo train'),
    _Sound('V', '🚐', 'The Buzzing Sound - Teeth on lip'),
    _Sound('W', '💧', 'The Woo Sound - Round your lips'),
  ];

  /// Every topic of this level (words and mini challenge for each sound),
  /// as named on the results screen.
  static List<String> get topics => topicEmojis.keys.toList();

  /// The same topics with their pictures.
  static Map<String, String> get topicEmojis => {
    for (final s in [..._level1, ..._level2]) ...{'Sound ${s.sound}': s.emoji, 'Mini Challenge ${s.sound}': '🏆'},
  };

  LevelTopic _soundTile(_Sound sound) {
    return LevelTopic(
      emoji: sound.emoji,
      title: 'Sound ${sound.sound}',
      onTap: (context) => _showModes(context, sound),
    );
  }

  /// Lets the child choose Words to Practice or Mini Challenge for a sound.
  void _showModes(BuildContext context, _Sound sound) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        void open(bool isSentence) {
          Navigator.pop(sheetContext);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AiSoundPage(sound: sound.sound, isSentence: isSentence),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(height: 16),
                Text(sound.emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 6),
                Text(
                  'Sound ${sound.sound}',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _theme.darkColor),
                ),
                const SizedBox(height: 4),
                Text(
                  sound.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF7A6A85)),
                ),
                const SizedBox(height: 20),
                _buildModeButton(
                  emoji: '📝',
                  title: 'Words to Practice',
                  subtitle: 'Learn and repeat words',
                  background: const Color(0xFFE3F2FD),
                  edge: const Color(0xFF90CAF9),
                  onTap: () => open(false),
                ),
                const SizedBox(height: 14),
                _buildModeButton(
                  emoji: '🎤',
                  title: 'Mini Challenge',
                  subtitle: 'Say the whole sentence',
                  background: const Color(0xFFFFE0E6),
                  edge: const Color(0xFFF48FB1),
                  onTap: () => open(true),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeButton({
    required String emoji,
    required String title,
    required String subtitle,
    required Color background,
    required Color edge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF4A3B57)),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF7A6A85)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill_rounded, size: 32, color: Color(0xFFD81B8C)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LevelMenuPage(
      theme: _theme,
      dinoMessage: "Let's practice tricky sounds together!",
      question: 'Which sound do you want to practice? 🎶',
      tip: 'Watch the mouth shape, listen first, then try the sound slowly!',
      sections: [
        LevelSection(heading: '🌟 Level 1', topics: [for (final sound in _level1) _soundTile(sound)]),
        LevelSection(heading: '🚀 Level 2', topics: [for (final sound in _level2) _soundTile(sound)]),
      ],
    );
  }
}
