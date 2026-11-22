import 'package:flutter/material.dart';
import 'package:talkiepal/practice/ai_practice_page.dart';
import 'package:talkiepal/services/exercise_service.dart';
import 'package:talkiepal/services/study_content_service.dart';
import 'package:talkiepal/widgets/level_menu_page.dart';

class PreIntermediatePage extends StatelessWidget {
  const PreIntermediatePage({super.key});

  static const String _level = 'pre_intermediate';

  static const LevelTheme _theme = LevelTheme(
    letter: 'B',
    title: 'Pre Intermediate',
    color: Color(0xFF42A5F5),
    darkColor: Color(0xFF1565C0),
    lightColor: Color(0xFF90CAF9),
    dinoColor: Color(0xFF7EC3F2),
  );

 
  static Map<String, String> get topicEmojis => {
        for (final (title, emoji, _) in StudyContentService.preIntermediateDefaults) title: emoji,
      };

  
  static List<String> get topics => List.unmodifiable(topicEmojis.keys);

  void _open(BuildContext context, StudySubtopic s) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiPracticePage(
          level: _level,
          levelLabel: 'Pre Intermediate',
          topic: s.title,
          topicEmoji: s.emoji,
          topicHint: s.hint,
          suggestedWords: [
            for (final w in s.words) PracticeExercise(word: w.word, emoji: w.emoji),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudySubtopic>>(
      stream: StudyContentService.watchMenu(_level),
      builder: (context, snapshot) {
        final subtopics = snapshot.data ?? StudyContentService.defaultsFor(_level);

        return LevelMenuPage(
          theme: _theme,
          dinoMessage: "Let's join words together and make short phrases!",
          sections: [
            LevelSection(
              topics: [
                for (final s in subtopics)
                  LevelTopic(
                    emoji: s.emoji,
                    title: s.title,
                    onTap: (context) => _open(context, s),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}