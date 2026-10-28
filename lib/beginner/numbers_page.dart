import 'package:flutter/material.dart';
import 'package:talkiepal/game_page.dart';
import 'package:talkiepal/profile_page.dart';
import 'package:talkiepal/practice/widgets/practice_scaffold.dart';
import 'package:talkiepal/practice/practice_session.dart';
import 'package:talkiepal/practice/result_page.dart';
import 'package:talkiepal/practice/speak_check.dart';
import 'package:talkiepal/practice/widgets/score_dialog.dart';
import 'package:talkiepal/services/speech_service.dart';
import 'package:talkiepal/widgets/kids_bottom_nav.dart';
import 'package:talkiepal/progress_page.dart';

class PracticeNumbers1To10Page extends StatefulWidget {
  /// Practice only these numbers (e.g. the hard ones again); null for all.
  final List<String>? only;

  const PracticeNumbers1To10Page({super.key, this.only});

  @override
  State<PracticeNumbers1To10Page> createState() => _PracticeNumbers1To10PageState();
}

class _PracticeNumbers1To10PageState extends State<PracticeNumbers1To10Page> with HoldToSpeak {
  bool isPlaying = false;
  int currentIndex = 0;

  // List of 10 exercises (1 to 10)
  final List<Map<String, String>> _allExercises = [
    {'number': '1', 'word': 'ONE', 'focus': 'Numbers', 'image': 'lib/assets/images/numbers/1.png'},
    {'number': '2', 'word': 'TWO', 'focus': 'Numbers', 'image': 'lib/assets/images/numbers/2.png'},
    {'number': '3', 'word': 'THREE', 'focus': 'Numbers', 'image': 'lib/assets/images/numbers/3.png'},
    {'number': '4', 'word': 'FOUR', 'focus': 'Numbers', 'image': 'lib/assets/images/numbers/4.png'},
    {'number': '5', 'word': 'FIVE', 'focus': 'Numbers', 'image': 'lib/assets/images/numbers/5.png'},
    {'number': '6', 'word': 'SIX', 'focus': 'Numbers', 'image': 'lib/assets/images/numbers/6.png'},
    {'number': '7', 'word': 'SEVEN', 'focus': 'Numbers', 'image': 'lib/assets/images/numbers/7.png'},
    {'number': '8', 'word': 'EIGHT', 'focus': 'Numbers', 'image': 'lib/assets/images/numbers/8.png'},
    {'number': '9', 'word': 'NINE', 'focus': 'Numbers', 'image': 'lib/assets/images/numbers/9.png'},
    {'number': '10', 'word': 'TEN', 'focus': 'Numbers', 'image': 'lib/assets/images/numbers/10.png'},
  ];

  late final List<Map<String, String>> exercises = widget.only == null
      ? _allExercises
      : _allExercises.where((e) => widget.only!.contains(e['word'])).toList();

  // Scores and tries for the results screen.
  late final PracticeSession session = PracticeSession();

  @override
  void initState() {
    super.initState();
    for (final e in exercises) {
      session.addItem(e['word']!, emoji: e['number']);
    }
  }

  // Get current exercise
  Map<String, String> get currentExercise => exercises[currentIndex];

  void _goToNextExercise() {
    SpeechService.instance.stop();
    if (currentIndex + 1 < exercises.length) {
      setState(() {
        currentIndex++;
        cancelSpeaking();
        isPlaying = false;
      });
    } else {
      // Show the results; "practice again" opens just the hard numbers.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            session: session,
            look: PracticeLook.beginner,
            title: 'Numbers',
            practiceAgain: (labels) => PracticeNumbers1To10Page(only: labels),
          ),
        ),
      );
    }
  }

  void _showResultDialog(SpeechCheck check) {
    final bool isLastExercise = currentIndex == exercises.length - 1;

    showScoreDialog(
      context,
      score: check.score,
      target: currentExercise['word']!,
      heard: check.heard,
      nextLabel: isLastExercise ? 'FINISH →' : 'NEXT NUMBER →',
      onNext: _goToNextExercise,
    );
  }

  static const PracticeLook _look = PracticeLook.beginner;

  Future<void> _onListen() async {
    if (isPlaying || isListening) return;
    setState(() {
      isPlaying = true;
    });

    // The word stays lit while the voice says it.
    await SpeechService.instance.speak(toSpoken(currentExercise['word']!));
    if (!mounted) return;
    setState(() {
      isPlaying = false;
    });
  }

  @override
  void dispose() {
    SpeechService.instance.stop();
    super.dispose();
  }

  @override
  String get speakTarget => currentExercise['word']!;

  @override
  bool get speakBlocked => isPlaying;

  @override
  void onSpeechChecked(SpeechCheck check) {
    session.recordScore(currentExercise['word']!, check.score, heard: check.heard);
    _showResultDialog(check);
  }

  @override
  Widget build(BuildContext context) {
    return PracticeScaffold(
      look: _look,
      title: 'Numbers 🔢',
      current: currentIndex + 1,
      total: exercises.length,
      dinoTip: 'Count with me, then hold SPEAK and say the number!',
      onNavTap: _onNavTap,
      children: [
        PracticeCard(
          look: _look,
          child: Column(
            children: [
              TapToListen(
                onTap: _onListen,
                child: Container(
                  width: 170,
                  height: 170,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: _look.lightColor, shape: BoxShape.circle),
                  child: Image.asset(
                    currentExercise['image']!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Text('🦖', style: TextStyle(fontSize: 70))),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              WordChip(
                text: currentExercise['number']!,
                isLit: isPlaying || isListening,
                litColor: isListening ? PracticeColors.speak : PracticeColors.listen,
                size: 52,
              ),
              const SizedBox(height: 4),
              Text(
                currentExercise['word']!,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: PracticeColors.ink, letterSpacing: 2),
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