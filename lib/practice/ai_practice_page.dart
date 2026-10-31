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

  // Bumped on every load, so a slow AI answer cannot replace newer words.
  int _loadRun = 0;
  List<PracticeExercise> exercises = [];

  // Scores and tries for the results screen.
  PracticeSession session = PracticeSession();

  PracticeExercise get currentExercise => exercises[currentIndex];

  /// True once the child has spoken at least one word in this round.
  bool get _hasProgress => session.items.any((item) => item.tries > 0);

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final run = ++_loadRun;
    setState(() {
      isLoading = true;
      currentIndex = 0;
      _stopHighlight();
    });

    final given = widget.exercises;
    final result = given != null
        ? ExerciseResult(exercises: given, isOffline: false)
        : await ExerciseService.getExercises(level: widget.level, topic: widget.topic, count: widget.count);

    if (!mounted || run != _loadRun) return;

    setState(() {
      exercises = result.exercises;
      session = PracticeSession();
      for (final e in exercises) {
        session.addItem(e.word, emoji: e.emoji);
      }
      isLoading = false;
    });

    if (result.isOffline && exercises.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📴 AI is offline. Using practice words instead.'),
          backgroundColor: Color(0xFFFFB347),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// New words wipe this round's scores, so ask first once the child has started.
  Future<void> _onRefresh() async {
    if (_hasProgress) {
      final sure = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Get new words? 🔄'),
          content: const Text('Your stars for these words will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('KEEP GOING'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('NEW WORDS'),
            ),
          ],
        ),
      );
      if (sure != true || !mounted) return;
    }
    await _loadExercises();
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

  // Call inside setState.
  void _stopHighlight() {
    SpeechService.instance.stop();
    _highlightRun++;
    highlightedWord = -1;
    cancelSpeaking();
    isPlaying = false;
  }

  Future<void> _onListen() async {
    if (isPlaying || isListening || exercises.isEmpty) return;
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
      // Hear the word again before the next try, as the dialog suggests.
      onTryAgain: _onListen,
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
      onRefresh: _onRefresh,
      onNavTap: _onNavTap,
      children: isLoading
          ? const []
          : exercises.isEmpty
              ? [_buildNoWordsCard(look)]
              : _buildExercise(look),
    );
  }

  List<Widget> _buildExercise(PracticeLook look) {
    final words = currentExercise.word.split(' ');

    return [
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
                for (var i = 0; i < words.length; i++)
                  WordChip(
                    text: words[i],
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
    ];
  }

  /// Shown when neither the AI nor the backup list had words for this topic.
  Widget _buildNoWordsCard(PracticeLook look) {
    return PracticeCard(
      look: look,
      child: Column(
        children: [
          const Text('🦖💤', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text(
            'Dino could not find any words',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: look.darkColor),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check the internet, then try again.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF7A6A85)),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadExercises,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('TRY AGAIN', style: TextStyle(fontWeight: FontWeight.w900)),
            style: ElevatedButton.styleFrom(
              backgroundColor: look.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  void _onNavTap(KidsTab tab) {
    switch (tab) {
      case KidsTab.home:
        goToKidsHome(context);
      case KidsTab.game:
        _openTab(const GamePage());
      case KidsTab.progress:
        _openTab(const ProgressPage());
      case KidsTab.profile:
        _openTab(const ProfilePage());
    }
  }

  void _openTab(Widget page) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }
}