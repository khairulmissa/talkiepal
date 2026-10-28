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

/// Special Sound practice for one target sound (R, S, TH, ...).
/// Words mode shows one word; sentence mode (Mini Challenge) shows a sentence.
/// The words and sentences come from the AI backend.
class AiSoundPage extends StatefulWidget {
  final String sound;
  final bool isSentence;
  final int count;

  /// Practice exactly these (e.g. the hard words again) instead of new AI words.
  final List<PracticeExercise>? exercises;

  const AiSoundPage({
    super.key,
    required this.sound,
    required this.isSentence,
    this.count = 10,
    this.exercises,
  });

  @override
  State<AiSoundPage> createState() => _AiSoundPageState();
}

class _AiSoundPageState extends State<AiSoundPage> with HoldToSpeak {
  // Words that are not good practice words on their own.
  static const Set<String> _notPracticeWords = {'THE', 'A', 'AN'};

  static const Map<String, String> _soundTips = {
    'R': 'Focus on the "R" sound - Roll your tongue!',
    'S': 'Focus on the "S" sound - Like a snake hissing!',
    'L': 'Focus on the "L" sound - Tongue touches the top of your mouth!',
    'TH': 'Stick your tongue out between your teeth for "TH"!',
    'SH': 'Pucker your lips and blow air for "SH"!',
    'CH': 'Like a train "choo choo" sound!',
    'V': 'Bite your bottom lip to say "V"!',
    'W': 'Round your lips like you are blowing a kiss for "W"!',
  };

  bool isLoading = true;
  bool isPlaying = false;
  int currentIndex = 0;
  List<PracticeExercise> exercises = [];

  // Scores and tries for the results screen.
  PracticeSession session = PracticeSession();

  // Index of the letter box (words) or word (sentences) that is lit up.
  int highlightedUnit = -1;

  // True while the whole word is being said, so every letter box is lit.
  bool isWholeWordLit = false;
  Color highlightColor = PracticeColors.listen;

  // Bumped whenever the item changes, so an old highlight run stops.
  int _highlightRun = 0;

  PracticeExercise get currentExercise => exercises[currentIndex];

  String get _apiLevel => widget.isSentence ? 'special_sentences' : 'special_words';

  /// Letter boxes for a word, keeping the target sound together: TH R E E.
  List<String> _splitLetters(String word) {
    final sound = widget.sound;
    final boxes = <String>[];
    var i = 0;

    while (i < word.length) {
      if (word.startsWith(sound, i)) {
        boxes.add(sound);
        i += sound.length;
      } else {
        boxes.add(word[i]);
        i++;
      }
    }
    return boxes;
  }

  /// What lights up one by one: letter boxes for a word, words for a sentence.
  List<String> get currentUnits => widget.isSentence
      ? currentExercise.word.split(' ')
      : _splitLetters(currentExercise.word);

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
        : await ExerciseService.getExercises(level: _apiLevel, topic: widget.sound, count: widget.count);

    if (!mounted) return;

    setState(() {
      // Words like "THE" or "A" have no picture and sound wrong said alone.
      exercises = result.exercises.where((e) => !_notPracticeWords.contains(e.word)).toList();
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

  // Call inside setState.
  void _stopHighlight() {
    SpeechService.instance.stop();
    _highlightRun++;
    highlightedUnit = -1;
    isWholeWordLit = false;
    isPlaying = false;
    cancelSpeaking();
  }

  Future<void> _onListen() async {
    if (isPlaying || isListening) return;
    final run = ++_highlightRun;
    setState(() {
      isPlaying = true;
      highlightColor = PracticeColors.listen;
    });

    final text = toSpoken(currentExercise.word);

    if (widget.isSentence) {
      // Slowly, one word at a time, so the target sound is clear.
      await speakWordByWord(
        text,
        slow: true,
        keepGoing: () => mounted && run == _highlightRun,
        onWord: (i) => setState(() {
          highlightedUnit = i;
        }),
      );
    } else {
      // Spell it box by box (R - E - D), then say the whole word (RED).
      await _spellThenSay(text, run);
    }

    if (!mounted || run != _highlightRun) return;
    setState(() {
      highlightedUnit = -1;
      isWholeWordLit = false;
      isPlaying = false;
    });
  }

  /// Says each letter box in turn while it is lit, then the whole word slowly
  /// with every box lit. The voice can only say letter names ("ar", "ee",
  /// "dee"), so a box like TH is spelt as its two letters.
  Future<void> _spellThenSay(String word, int run) async {
    bool stillHere() => mounted && run == _highlightRun;
    final units = currentUnits;

    for (var i = 0; i < units.length; i++) {
      if (!stillHere()) return;
      setState(() {
        highlightedUnit = i;
      });
      await SpeechService.instance.speak(units[i].split('').join(' '));
      if (!stillHere()) return;
      await Future.delayed(const Duration(milliseconds: 250));
    }

    if (!stillHere()) return;
    setState(() {
      highlightedUnit = -1;
      isWholeWordLit = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));
    if (!stillHere()) return;
    await SpeechService.instance.speak(word, slow: true);
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

  /// Shows the results; "practice again" opens just the hard words.
  void _finish() {
    final all = exercises;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          session: session,
          look: _look,
          title: widget.isSentence ? 'Mini Challenge ${widget.sound}' : 'Sound ${widget.sound}',
          practiceAgain: (labels) => AiSoundPage(
            sound: widget.sound,
            isSentence: widget.isSentence,
            exercises: all.where((e) => labels.contains(e.word)).toList(),
          ),
        ),
      ),
    );
  }

  void _goToNext() {
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
    final bool isLast = currentIndex == exercises.length - 1;

    showScoreDialog(
      context,
      score: check.score,
      target: currentExercise.word,
      heard: check.heard,
      nextLabel: isLast ? 'FINISH →' : 'NEXT →',
      onNext: _goToNext,
    );
  }

  static const PracticeLook _look = PracticeLook.specialSound;

  @override
  Widget build(BuildContext context) {
    return PracticeScaffold(
      look: _look,
      title: widget.isSentence ? 'Mini Challenge ${widget.sound} 🏆' : 'Sound ${widget.sound} 🎶',
      current: isLoading ? 0 : currentIndex + 1,
      total: exercises.length,
      dinoTip: _soundTips[widget.sound] ?? 'Listen first, then say it clearly!',
      isLoading: isLoading,
      loadingText: widget.isSentence
          ? 'Creating new sentences for you... ✨'
          : 'Creating new words for you... ✨',
      onRefresh: _loadExercises,
      onNavTap: _onNavTap,
      children: isLoading || exercises.isEmpty
          ? const []
          : [
              _buildPracticeCard(),
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

  Widget _buildPracticeCard() {
    final units = currentUnits;

    return PracticeCard(
      look: _look,
      child: Column(
        children: [
          BigEmoji(emoji: currentExercise.emoji, background: _look.lightColor, onTap: _onListen),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: widget.isSentence ? 4 : 6,
            runSpacing: 8,
            children: [
              for (var i = 0; i < units.length; i++)
                widget.isSentence
                    ? WordChip(
                        text: units[i],
                        isLit: i == highlightedUnit,
                        litColor: highlightColor,
                        target: widget.sound,
                        size: 24,
                      )
                    : _buildLetterBox(units[i], isWholeWordLit || i == highlightedUnit, units.length),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: _look.lightColor, borderRadius: BorderRadius.circular(14)),
            child: Text(
              '⭐ Target sound: ${widget.sound}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _look.darkColor),
            ),
          ),
        ],
      ),
    );
  }

  /// One letter box. The target sound box is yellow.
  Widget _buildLetterBox(String text, bool isLit, int boxCount) {
    final isTarget = text == widget.sound;
    final double fontSize = boxCount <= 5 ? 30 : (boxCount <= 7 ? 24 : 20);

    final Color background = isLit
        ? highlightColor
        : (isTarget ? const Color(0xFFFFF59D) : const Color(0xFFF7F2FA));
    final Color border = isLit
        ? highlightColor
        : (isTarget ? const Color(0xFFFFB300) : const Color(0xFFE6DCEB));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: BoxConstraints(minWidth: fontSize * 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 3),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: isLit ? Colors.white : (isTarget ? _look.darkColor : PracticeColors.ink),
        ),
      ),
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
