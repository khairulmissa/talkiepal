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

class PracticeAlphabetsPage extends StatefulWidget {
  /// Practice only these letters (e.g. the hard ones again); null for all.
  final List<String>? only;

  const PracticeAlphabetsPage({super.key, this.only});

  @override
  State<PracticeAlphabetsPage> createState() => _PracticeAlphabetsPageState();
}

class _PracticeAlphabetsPageState extends State<PracticeAlphabetsPage> with HoldToSpeak {
  bool isPlaying = false;
  int currentIndex = 0;

  // List of 26 exercises (A to Z)
  final List<Map<String, String>> _allExercises = [
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

  late final List<Map<String, String>> exercises = widget.only == null
      ? _allExercises
      : _allExercises.where((e) => widget.only!.contains(e['letter'])).toList();

  // Scores and tries for the results screen.
  late final PracticeSession session = PracticeSession();

  @override
  void initState() {
    super.initState();
    for (final e in exercises) {
      session.addItem(e['letter']!, emoji: null);
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
      // Show the results; "practice again" opens just the hard letters.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            session: session,
            look: PracticeLook.beginner,
            title: 'Alphabets',
            practiceAgain: (labels) => PracticeAlphabetsPage(only: labels),
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
      target: currentExercise['letter']!,
      heard: check.heard,
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

    // The word stays lit while the voice says it.
    await SpeechService.instance.speak(currentExercise['letter']!);
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
  String get speakTarget => currentExercise['letter']!;

  @override
  bool get speakBlocked => isPlaying;

  @override
  void onSpeechChecked(SpeechCheck check) {
    session.recordScore(currentExercise['letter']!, check.score, heard: check.heard);
    _showResultDialog(check);
  }

  @override
  Widget build(BuildContext context) {
    return PracticeScaffold(
      look: _look,
      title: 'Alphabets 🔤',
      current: currentIndex + 1,
      total: exercises.length,
      dinoTip: 'Listen, then hold SPEAK and say the letter!',
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
                text: '${currentExercise['letter']!}${currentExercise['letter']!.toLowerCase()}',
                isLit: isPlaying || isListening,
                litColor: isListening ? PracticeColors.speak : PracticeColors.listen,
                size: 52,
              ),
              const SizedBox(height: 6),
              Text(
                'say "${_letterNames[currentExercise['letter']!.codeUnitAt(0) - 65]}"',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: PracticeColors.soft),
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