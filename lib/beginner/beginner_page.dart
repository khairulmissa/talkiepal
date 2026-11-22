import 'package:flutter/material.dart';
import 'package:talkiepal/beginner/alphabets.dart';
import 'package:talkiepal/beginner/numbers_page.dart';
import 'package:talkiepal/practice/ai_practice_page.dart';
import 'package:talkiepal/services/exercise_service.dart';
import 'package:talkiepal/services/study_content_service.dart';
import 'package:talkiepal/widgets/level_menu_page.dart';

class BeginnerPage extends StatelessWidget {
  const BeginnerPage({super.key});

  static const LevelTheme _theme = LevelTheme(
    letter: 'A',
    title: 'Beginner',
    color: Color(0xFF4CAF50),
    darkColor: Color(0xFF2E7D32),
    lightColor: Color(0xFF81C784),
    dinoColor: Color(0xFF8BD17C),
  );

  /// Backup bila Firestore belum sampai / error: 6 topic asal.
  static final List<StudySubtopic> _fallbackTopics = [
    for (final (title, emoji, hint) in StudyContentService.beginnerDefaults)
      StudySubtopic(level: 'beginner', title: title, emoji: emoji, hint: hint, published: true),
  ];

  /// Every topic of this level, as named on the results screen, with its picture.
  /// (Progress page & parent report masih guna senarai asal ni.)
  static Map<String, String> get topicEmojis => {
        'Alphabets': '🔤',
        'Numbers': '🔢',
        for (final (title, emoji, _) in StudyContentService.beginnerDefaults) title: emoji,
      };

  /// Returns an unmodifiable list of topics to prevent accidental mutations.
  static List<String> get topics => List.unmodifiable(topicEmojis.keys);

  /// Helper method to navigate to a new page safely.
  static void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudySubtopic>>(
      stream: StudyContentService.watchMenu('beginner'),
      builder: (context, snapshot) {
        final subtopics = snapshot.hasData ? snapshot.data! : _fallbackTopics;

        return LevelMenuPage(
          theme: _theme,
          dinoMessage: "Let's learn our first words together!",
          sections: [
            LevelSection(
              topics: [
                LevelTopic(
                  emoji: '🔤',
                  title: 'Alphabets',
                  onTap: (context) => _open(context, const PracticeAlphabetsPage()),
                ),
                LevelTopic(
                  emoji: '🔢',
                  title: 'Numbers',
                  onTap: (context) => _open(context, const PracticeNumbers1To10Page()),
                ),
                for (final s in subtopics)
                  LevelTopic(
                    emoji: s.emoji,
                    title: s.title,
                    onTap: (context) => _open(
                      context,
                      AiPracticePage(
                        level: 'beginner',
                        levelLabel: 'Beginner',
                        topic: s.title,
                        topicEmoji: s.emoji,
                        topicHint: s.hint,
                        suggestedWords: [
                          for (final w in s.words) PracticeExercise(word: w.word, emoji: w.emoji),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}