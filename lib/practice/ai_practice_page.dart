import 'package:flutter/material.dart';
import 'package:talkiepal/game_page.dart';
import 'package:talkiepal/profile_page.dart';
import 'package:talkiepal/services/exercise_service.dart';
import 'package:talkiepal/services/speech_service.dart';
import 'package:talkiepal/practice/widgets/practice_scaffold.dart';
import 'package:talkiepal/practice/practice_session.dart';
import 'package:talkiepal/practice/result_page.dart';
import 'package:talkiepal/practice/speak_check.dart';
import 'package:talkiepal/practice/widgets/score_dialog.dart';
import 'package:talkiepal/widgets/kids_bottom_nav.dart';
import 'package:talkiepal/progress_page.dart';

/// One practice page for every topic. The words come from the AI backend
/// instead of being written in the code.
class AiPracticePage extends StatefulWidget {
  final String level;
  final String levelLabel;
  final String topic;
  final String topicEmoji;
  final int count;

  /// Practice exactly these (e.g. the hard words again) instead of new AI words.
  final List<PracticeExercise>? exercises;

  const AiPracticePage({
    super.key,
    required this.level,
    required this.levelLabel,
    required this.topic,
    this.topicEmoji = '⭐',
    this.count = 10,
    this.exercises,
  });

  @override
  State<AiPracticePage> createState() => _AiPracticePageState();
}

class _AiPracticePageState extends State<AiPracticePage> with HoldToSpeak {
  bool isLoading = true;
  bool isPlaying = false;
  int currentIndex = 0;

  // Index of the word that is lit up while LISTEN or SPEAK runs (-1 = none).
  int highlightedWord = -1;
  Color highlightColor = PracticeColors.listen;

  // Bumped whenever the exercise changes, so an old highlight run stops.
  int _highlightRun = 0;
  List<PracticeExercise> exercises = [];

  // Scores and tries for the results screen.
  PracticeSession session = PracticeSession();

  PracticeExercise get currentExercise => exercises[currentIndex];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() {
      isLoading = true;
      currentIndex = 0;
      _stopHighlight();
    });

    final given = widget.exercises;
    final result = given != null
        ? ExerciseResult(exercises: given, isOffline: false)
        : await ExerciseService.getExercises(level: widget.level, topic: widget.topic, count: widget.count);

    if (!mounted) return;

    setState(() {
      exercises = result.exercises;
      session = PracticeSession();
      for (final e in exercises) {
        session.addItem(e.word, emoji: e.emoji);
      }
      isLoading = false;
    });

    if (result.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📴 AI is offline. Using practice words instead.'),
          backgroundColor: Color(0xFFFFB347),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Shows the results; "practice again" opens just the hard words.
  void _finish() {
    final all = exercises;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          session: session,
          look: _look,
          title: widget.topic,
          practiceAgain: (labels) => AiPracticePage(
            level: widget.level,
            levelLabel: widget.levelLabel,
            topic: widget.topic,
            topicEmoji: widget.topicEmoji,
            exercises: all.where((e) => labels.contains(e.word)).toList(),
          ),
        ),
      ),
    );
  }

  List<String> get currentWords => currentExercise.word.split(' ');

  // Call inside setState.
  void _stopHighlight() {
    SpeechService.instance.stop();
    _highlightRun++;
    highlightedWord = -1;
    cancelSpeaking();
    isPlaying = false;
  }

  Future<void> _onListen() async {
    if (isPlaying || isListening) return;
    final run = ++_highlightRun;
    setState(() {
      isPlaying = true;
      highlightColor = PracticeColors.listen;
    });

    // One word at a time, each lit as the voice says it.
    await speakWordByWord(
      toSpoken(currentExercise.word),
      keepGoing: () => mounted && run == _highlightRun,
      onWord: (i) => setState(() {
        highlightedWord = i;
      }),
    );

    if (!mounted || run != _highlightRun) return;
    setState(() {
      highlightedWord = -1;
      isPlaying = false;
    });
  }

  @override
  void dispose() {
    SpeechService.instance.stop();
    super.dispose();
  }

  @override
  String get speakTarget => currentExercise.word;

  @override
  bool get speakBlocked => isPlaying;

  @override
  void onSpeechChecked(SpeechCheck check) {
    session.recordScore(currentExercise.word, check.score, heard: check.heard);
    _showResultDialog(check);
  }

  void _goToNextExercise() {
    if (currentIndex + 1 < exercises.length) {
      setState(() {
        currentIndex++;
        _stopHighlight();
      });
    } else {
      _finish();
    }
  }

  void _showResultDialog(SpeechCheck check) {
    final bool isLastExercise = currentIndex == exercises.length - 1;

    showScoreDialog(
      context,
      score: check.score,
      target: currentExercise.word,
      heard: check.heard,
      nextLabel: isLastExercise ? 'FINISH →' : 'NEXT →',
      onNext: _goToNextExercise,
    );
  }

  PracticeLook get _look => PracticeLook.forLevel(widget.level);

  String get _dinoTip => widget.level == 'beginner'
      ? 'Listen, then hold SPEAK and say the word!'
      : 'Listen to each word, then hold SPEAK and say the sentence!';

  @override
  Widget build(BuildContext context) {
    final look = _look;

    return PracticeScaffold(
      look: look,
      title: '${widget.topic} ${widget.topicEmoji}',
      current: isLoading ? 0 : currentIndex + 1,
      total: exercises.length,
      dinoTip: _dinoTip,
      isLoading: isLoading,
      onRefresh: _loadExercises,
      onNavTap: _onNavTap,
      children: isLoading || exercises.isEmpty
          ? const []
          : [
        PracticeCard(
          look: look,
          child: Column(
            children: [
              BigEmoji(emoji: currentExercise.emoji, background: look.lightColor, onTap: _onListen),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < currentWords.length; i++)
                    WordChip(
                      text: currentWords[i],
                      isLit: i == highlightedWord,
                      litColor: highlightColor,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        ListenSpeakButtons(
          onListen: _onListen,
          onSpeakDown: onSpeakDown,
          onSpeakUp: onSpeakUp,
          isPlaying: isPlaying,
          isListening: isListening,
          isMicReady: isMicReady,
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProgressPage()),
        );
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
