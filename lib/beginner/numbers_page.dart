import 'package:flutter/material.dart';
import 'package:talkiepal/game_page.dart';
import 'package:talkiepal/profile_page.dart';
import 'package:talkiepal/practice/widgets/practice_scaffold.dart';
import 'package:talkiepal/practice/widgets/success_dialog.dart';
import 'package:talkiepal/widgets/kids_bottom_nav.dart';
import 'package:talkiepal/progress_page.dart';

class PracticeNumbers1To10Page extends StatefulWidget {
  const PracticeNumbers1To10Page({super.key});

  @override
  State<PracticeNumbers1To10Page> createState() => _PracticeNumbers1To10PageState();
}

class _PracticeNumbers1To10PageState extends State<PracticeNumbers1To10Page> {
  bool isListening = false;
  bool isPlaying = false;
  int currentIndex = 0;

  // List of 10 exercises (1 to 10)
  final List<Map<String, String>> exercises = [
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

  // Get current exercise
  Map<String, String> get currentExercise => exercises[currentIndex];

  void _goToNextExercise() {
    if (currentIndex + 1 < exercises.length) {
      setState(() {
        currentIndex++;
        isListening = false;
        isPlaying = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Congratulations! You completed all numbers! 🎉'),
          backgroundColor: Color(0xFFA8D5A2),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showResultDialog(BuildContext context, {required bool isSuccess}) {
    bool isLastExercise = currentIndex == exercises.length - 1;

    showSuccessDialog(
      context,
      detail: 'You said "${currentExercise['word']}"!',
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

    // Audio is not connected yet; the word lights up for a moment.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
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
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      isListening = false;
    });
    _showResultDialog(context, isSuccess: true);
  }

  @override
  Widget build(BuildContext context) {
    return PracticeScaffold(
      look: _look,
      title: 'Numbers 🔢',
      current: currentIndex + 1,
      total: exercises.length,
      dinoTip: 'Count with me, then say the number!',
      onNavTap: _onNavTap,
      children: [
        PracticeCard(
          look: _look,
          child: Column(
            children: [
              Container(
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