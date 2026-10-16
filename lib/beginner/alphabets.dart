import 'package:flutter/material.dart';
import 'package:talkiepal/game_page.dart';
import 'package:talkiepal/profile_page.dart';
import 'package:talkiepal/practice/widgets/practice_scaffold.dart';
import 'package:talkiepal/practice/widgets/success_dialog.dart';
import 'package:talkiepal/widgets/kids_bottom_nav.dart';
import 'package:talkiepal/progress_page.dart';

class PracticeAlphabetsPage extends StatefulWidget {
  const PracticeAlphabetsPage({super.key});

  @override
  State<PracticeAlphabetsPage> createState() => _PracticeAlphabetsPageState();
}

class _PracticeAlphabetsPageState extends State<PracticeAlphabetsPage> {
  bool isListening = false;
  bool isPlaying = false;
  int currentIndex = 0;

  // List of 26 exercises (A to Z)
  final List<Map<String, String>> exercises = [
    {'letter': 'A', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/A.png'},
    {'letter': 'B', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/B.png'},
    {'letter': 'C', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/C.png'},
    {'letter': 'D', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/D.png'},
    {'letter': 'E', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/E.png'},
    {'letter': 'F', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/F.png'},
    {'letter': 'G', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/G.png'},
    {'letter': 'H', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/H.png'},
    {'letter': 'I', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/I.png'},
    {'letter': 'J', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/J.png'},
    {'letter': 'K', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/K.png'},
    {'letter': 'L', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/L.png'},
    {'letter': 'M', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/M.png'},
    {'letter': 'N', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/N.png'},
    {'letter': 'O', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/O.png'},
    {'letter': 'P', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/P.png'},
    {'letter': 'Q', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/Q.png'},
    {'letter': 'R', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/R.png'},
    {'letter': 'S', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/S.png'},
    {'letter': 'T', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/T.png'},
    {'letter': 'U', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/U.png'},
    {'letter': 'V', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/V.png'},
    {'letter': 'W', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/W.png'},
    {'letter': 'X', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/X.png'},
    {'letter': 'Y', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/Y.png'},
    {'letter': 'Z', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/Z.png'},
  ];

  // How each letter name sounds, A to Z.
  static const List<String> _letterNames = [
    'ay',
    'bee',
    'see',
    'dee',
    'ee',
    'ef',
    'jee',
    'aych',
    'eye',
    'jay',
    'kay',
    'el',
    'em',
    'en',
    'oh',
    'pee',
    'cue',
    'ar',
    'es',
    'tee',
    'you',
    'vee',
    'double-you',
    'ex',
    'why',
    'zee',
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
          content: Text('🎉 Congratulations! You completed all alphabets! 🎉'),
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
      detail: 'You said "${currentExercise['letter']}"!',
      nextLabel: isLastExercise ? 'FINISH →' : 'NEXT LETTER →',
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
      title: 'Alphabets 🔤',
      current: currentIndex + 1,
      total: exercises.length,
      dinoTip: 'Look at the picture, listen, then say the letter!',
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
                text: '${currentExercise['letter']!}${currentExercise['letter']!.toLowerCase()}',
                isLit: isPlaying || isListening,
                litColor: isListening ? PracticeColors.speak : PracticeColors.listen,
                size: 52,
              ),
              const SizedBox(height: 6),
              Text(
                'say "${_letterNames[currentIndex]}"',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: PracticeColors.soft),
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