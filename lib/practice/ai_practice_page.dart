import 'package:flutter/material.dart';
import 'package:talkiepal/game_page.dart';
import 'package:talkiepal/profile_page.dart';
import 'package:talkiepal/services/exercise_service.dart';
import 'package:talkiepal/practice/widgets/practice_scaffold.dart';
import 'package:talkiepal/practice/widgets/success_dialog.dart';
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

  const AiPracticePage({
    super.key,
    required this.level,
    required this.levelLabel,
    required this.topic,
    this.topicEmoji = '⭐',
    this.count = 10,
  });

  @override
  State<AiPracticePage> createState() => _AiPracticePageState();
}

class _AiPracticePageState extends State<AiPracticePage> {
  bool isLoading = true;
  bool isListening = false;
  bool isPlaying = false;
  int currentIndex = 0;

  // Index of the word that is lit up while LISTEN or SPEAK runs (-1 = none).
  int highlightedWord = -1;
  Color highlightColor = PracticeColors.listen;

  // Bumped whenever the exercise changes, so an old highlight run stops.
  int _highlightRun = 0;
  List<PracticeExercise> exercises = [];

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

    final result = await ExerciseService.getExercises(
      level: widget.level,
      topic: widget.topic,
      count: widget.count,
    );

    if (!mounted) return;

    setState(() {
      exercises = result.exercises;
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

  void _finish() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Congratulations! You completed ${widget.topic.toLowerCase()}! 🎉'),
        backgroundColor: const Color(0xFFA8D5A2),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  List<String> get currentWords => currentExercise.word.split(' ');

  /// Lights up each word of the current exercise one by one.
  /// Returns false if it was stopped because the exercise changed.
  Future<bool> _highlightWords(Color color, Duration perWord) async {
    final run = ++_highlightRun;
    final words = currentWords;

    for (var i = 0; i < words.length; i++) {
      if (!mounted || run != _highlightRun) return false;
      setState(() {
        highlightColor = color;
        highlightedWord = i;
      });
      await Future.delayed(perWord);
    }

    if (!mounted || run != _highlightRun) return false;
    setState(() {
      highlightedWord = -1;
    });
    return true;
  }

  // Call inside setState.
  void _stopHighlight() {
    _highlightRun++;
    highlightedWord = -1;
    isListening = false;
    isPlaying = false;
  }

  Future<void> _onListen() async {
    if (isPlaying || isListening) return;
    setState(() {
      isPlaying = true;
    });

    // Audio is not connected yet; the highlight shows the reading pace.
    final finished = await _highlightWords(PracticeColors.listen, const Duration(milliseconds: 700));

    if (!mounted || !finished) return;
    setState(() {
      isPlaying = false;
    });
  }

  Future<void> _onSpeak() async {
    if (isPlaying || isListening) return;
    setState(() {
      isListening = true;
    });

    // Speech checking is not connected yet, so this always passes.
    final finished = await _highlightWords(PracticeColors.speak, const Duration(milliseconds: 900));

    if (!mounted || !finished) return;
    setState(() {
      isListening = false;
    });
    _showResultDialog();
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

  void _showResultDialog() {
    final bool isLastExercise = currentIndex == exercises.length - 1;

    showSuccessDialog(
      context,
      detail: 'You said "${currentExercise.word}"!',
      nextLabel: isLastExercise ? 'FINISH →' : 'NEXT →',
      onNext: _goToNextExercise,
    );
  }

  PracticeLook get _look => PracticeLook.forLevel(widget.level);

  String get _dinoTip => widget.level == 'beginner'
      ? 'Listen, then say the word with me!'
      : 'Listen to each word, then say the whole sentence!';

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
              BigEmoji(emoji: currentExercise.emoji, background: look.lightColor),
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
          onSpeak: _onSpeak,
          isPlaying: isPlaying,
          isListening: isListening,
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
