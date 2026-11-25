import 'package:flutter/material.dart';
import 'package:talkiepal/practice/ai_question_page.dart';
import 'package:talkiepal/services/study_content_service.dart';
import 'package:talkiepal/widgets/level_menu_page.dart';

class IntermediatePage extends StatelessWidget {
  const IntermediatePage({super.key});

  static const String _level = 'intermediate';

  static const LevelTheme _theme = LevelTheme(
    letter: 'C',
    title: 'Intermediate',
    color: Color(0xFFFF8A3D),
    darkColor: Color(0xFFD84315),
    lightColor: Color(0xFFFFB74D),
    dinoColor: Color(0xFFFFA569),
  );

  
  static Map<String, String> get topicEmojis => {
        for (final s in StudyContentService.menuFor(_level)) s.title: s.emoji,
      };

  
  static List<String> get topics => List.unmodifiable(topicEmojis.keys);

  void _openTopic(BuildContext context, StudySubtopic s) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiQuestionPage(
          topic: s.title,
          topicHint: s.hint,
          exampleQuestions: [
            for (final q in s.questions) [q.question, q.answer, ...q.wrong],
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
          dinoMessage: 'Listen to my questions and pick the right answer!',
          tip: 'Listen to the question first, then tap the answer you think is right!',
          sections: [
            LevelSection(
              topics: [
                for (final s in subtopics)
                  LevelTopic(
                    emoji: s.emoji,
                    title: s.title,
                    onTap: (context) => _openTopic(context, s),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}