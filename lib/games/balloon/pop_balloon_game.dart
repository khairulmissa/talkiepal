import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:talkiepal/games/balloon/balloon_world.dart';
import 'package:talkiepal/games/game_words.dart';
import 'package:talkiepal/games/widgets/game_scaffold.dart';
import 'package:talkiepal/practice/widgets/practice_scaffold.dart';
import 'package:talkiepal/practice/widgets/success_dialog.dart';
import 'package:talkiepal/services/exercise_service.dart';
import 'package:talkiepal/widgets/dino_mascot.dart';

/// Words for one level: balloons with the sound and balloons without it.
class _LevelWords {
  final List<String> targets;
  final List<String> others;
  final bool isOffline;

  const _LevelWords(this.targets, this.others, this.isOffline);
}

/// Pop the Balloon (Flame): balloons with words float up and the child pops
/// every word with the target sound before time runs out. There is one level
/// per sound (S, R, L, SH, CH).
/// The words come from the AI backend (Special Sound words + Beginner words).
class PopBalloonGame extends StatefulWidget {
  final int goal;
  final int seconds;

  const PopBalloonGame({super.key, this.goal = 10, this.seconds = 60});

  @override
  State<PopBalloonGame> createState() => _PopBalloonGameState();
}

enum _Phase { loading, ready, playing, levelDone, won, timeUp }

class _PopBalloonGameState extends State<PopBalloonGame> {
  static const GameLook _look = GameLook.popBalloon;

  // Sounds that are easy to spot in written words. One level each.
  static const List<String> _allSounds = ['S', 'R', 'L', 'SH', 'CH'];

  // Backup words without the target sound, if the AI gives too few.
  static const List<String> _backupWords = [
    'CAT', 'DOG', 'MOON', 'BOOK', 'HAT', 'PEN', 'CUP', 'BED', 'EGG', 'FAN', 'KITE', 'DUCK', 'BOAT', 'TOY',
  ];

  final Random _random = Random();

  _Phase phase = _Phase.loading;
  List<String> sounds = [];
  int level = 0;
  BalloonGame? game;
  bool hasNoWords = false;

  int popped = 0;
  int totalPopped = 0;
  int secondsLeft = 0;
  String? message;
  bool messageIsWrong = false;
  Timer? _timer;

  // Words for each level, loaded one level ahead while the child plays.
  final Map<int, Future<_LevelWords>> _levelWords = {};
  Future<GameWords>? _otherWords;

  String get sound => sounds.isEmpty ? '' : sounds[level];
  bool get isLastLevel => level == sounds.length - 1;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Starts again from level 1 with the sounds in a new order.
  void _newGame() {
    _timer?.cancel();
    _levelWords.clear();
    _otherWords = GameWords.load(count: 10, random: _random);
    sounds = [..._allSounds]..shuffle(_random);
    totalPopped = 0;
    _openLevel(0);
  }

  Future<_LevelWords> _wordsFor(int i) {
    return _levelWords.putIfAbsent(i, () async {
      final sound = sounds[i];
      final results = await Future.wait([
        ExerciseService.getExercises(level: 'special_words', topic: sound, count: 10),
        _otherWords!,
      ]);
      final soundResult = results[0] as ExerciseResult;
      final otherResult = results[1] as GameWords;

      bool isShort(String w) => !w.contains(' ') && w.length <= 8;

      return _LevelWords(
        soundResult.exercises.map((e) => e.word).where((w) => isShort(w) && w.contains(sound)).toSet().toList(),
        {...otherResult.words.map((e) => e.word), ..._backupWords}
            .where((w) => isShort(w) && !w.contains(sound))
            .toList(),
        soundResult.isOffline || otherResult.isOffline,
      );
    });
  }

  Future<void> _openLevel(int i) async {
    _timer?.cancel();
    setState(() {
      level = i;
      popped = 0;
      phase = _Phase.loading;
      game = null;
      hasNoWords = false;
      message = null;
    });

    final words = await _wordsFor(i);
    if (!mounted || level != i) return;

    // Get the next level's words ready while this one is played.
    if (i + 1 < sounds.length) _wordsFor(i + 1);

    setState(() {
      hasNoWords = words.targets.isEmpty;
      game = hasNoWords
          ? null
          : BalloonGame(
              sound: sound,
              targetWords: words.targets,
              otherWords: words.others,
              onCorrect: _onCorrect,
              onWrong: _onWrong,
            );
      phase = _Phase.ready;
    });

    if (words.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📴 AI is offline. Using practice words instead.'),
          backgroundColor: Color(0xFFFFB347),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _retryLevel() {
    // Load this level's words again, e.g. after the AI was not reachable.
    _levelWords.remove(level);
    _openLevel(level);
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      // Playing a level again does not count its earlier pops twice.
      totalPopped -= popped;
      popped = 0;
      secondsLeft = widget.seconds;
      message = null;
      phase = _Phase.playing;
    });
    game?.start();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        secondsLeft--;
      });
      if (secondsLeft <= 0) _onTimeUp();
    });
  }

  void _onCorrect(String word) {
    if (phase != _Phase.playing) return;
    setState(() {
      popped++;
      totalPopped++;
      message = '🎉 Yes! $word has the $sound sound!';
      messageIsWrong = false;
    });
    if (popped >= widget.goal) _onLevelDone();
  }

  void _onWrong(String word) {
    if (phase != _Phase.playing) return;
    setState(() {
      message = 'Oops! $word has no $sound sound 🙈';
      messageIsWrong = true;
    });
  }

  void _onLevelDone() {
    _timer?.cancel();
    game?.stop();

    if (!isLastLevel) {
      setState(() {
        phase = _Phase.levelDone;
      });
      return;
    }

    var isLeaving = false;
    setState(() {
      phase = _Phase.won;
    });

    showSuccessDialog(
      context,
      detail: 'You finished all ${sounds.length} sounds and popped $totalPopped balloons!',
      nextLabel: 'FINISH →',
      onNext: () {
        isLeaving = true;
        Navigator.pop(context);
      },
    ).then((_) {
      // TRY AGAIN in the popup starts a new game from level 1.
      if (mounted && !isLeaving) _newGame();
    });
  }

  void _onTimeUp() {
    _timer?.cancel();
    game?.stop();
    setState(() {
      phase = _Phase.timeUp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB3E5FC), Color(0xFFE0F7FA), Color(0xFFFFF8EC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              children: [
                GameHeader(look: _look, title: 'Pop the Balloon 🎈', stars: totalPopped),
                const SizedBox(height: 12),
                if (sounds.isNotEmpty) _buildInstruction(),
                const SizedBox(height: 8),
                Expanded(child: _buildSky()),
                const SizedBox(height: 8),
                if (phase == _Phase.playing) _buildProgress(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _look.color, width: 3),
            ),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: 'Level ${level + 1}/${sounds.length}  ', style: TextStyle(color: _look.color)),
                const TextSpan(text: 'Pop words with '),
                TextSpan(text: sound, style: const TextStyle(color: Color(0xFFD81B8C), fontSize: 22)),
                const TextSpan(text: ' !'),
              ]),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: PracticeColors.ink),
            ),
          ),
        ),
        if (phase == _Phase.playing) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: secondsLeft <= 10 ? const Color(0xFFE53935) : const Color(0xFFFF7043),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '⏱ 0:${secondsLeft.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSky() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // Clouds and trees behind the balloons
          const Positioned(left: 10, top: 40, child: Text('☁️', style: TextStyle(fontSize: 60))),
          const Positioned(right: 0, top: 200, child: Text('☁️', style: TextStyle(fontSize: 48))),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Text('🌳🌳🌳🌳🌳', textAlign: TextAlign.center, style: TextStyle(fontSize: 46)),
          ),
          if (game != null) Positioned.fill(child: GameWidget(key: ValueKey(game), game: game!)),
          if (phase == _Phase.loading) _buildLoading(),
          if (phase == _Phase.ready) _buildStartCard(),
          if (phase == _Phase.levelDone) _buildLevelDoneCard(),
          if (phase == _Phase.timeUp) _buildTimeUpCard(),
          if (phase == _Phase.playing && message != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 64,
              // Taps go through to the balloons behind the message.
              child: IgnorePointer(child: Center(child: _buildMessage())),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: messageIsWrong ? const Color(0xFFFF6B6B) : const Color(0xFF43A047), width: 3),
      ),
      child: Text(
        message!,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: messageIsWrong ? const Color(0xFFE53935) : const Color(0xFF2E7D32),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: _buildCard(children: [
        CircularProgressIndicator(color: _look.color),
        const SizedBox(height: 16),
        const Text(
          'Dino is blowing up balloons... 🎈',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: PracticeColors.ink),
        ),
      ]),
    );
  }

  Widget _buildStartCard() {
    if (hasNoWords) {
      return Center(
        child: _buildCard(children: [
          const Text(
            'Oh no! Dino could not find any words. 🦖',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: PracticeColors.ink),
          ),
          const SizedBox(height: 16),
          _buildButton('🔄', 'TRY AGAIN', _retryLevel),
        ]),
      );
    }

    return Center(
      child: _buildCard(children: [
        DinoMascot(color: _look.dinoColor, size: 90),
        const SizedBox(height: 4),
        Text(
          'LEVEL ${level + 1} OF ${sounds.length}',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _look.color, letterSpacing: 1),
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'Pop '),
            TextSpan(text: '${widget.goal}', style: TextStyle(color: _look.color)),
            const TextSpan(text: ' balloons with the '),
            TextSpan(text: sound, style: const TextStyle(color: Color(0xFFD81B8C), fontSize: 24)),
            const TextSpan(text: ' sound!'),
          ]),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: PracticeColors.ink),
        ),
        const SizedBox(height: 6),
        Text(
          'You have ${widget.seconds} seconds. Say each word when you pop it!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PracticeColors.soft),
        ),
        const SizedBox(height: 16),
        _buildButton('🎈', 'START', _start),
      ]),
    );
  }

  Widget _buildTimeUpCard() {
    return Center(
      child: _buildCard(children: [
        const Text('⏰', style: TextStyle(fontSize: 56)),
        const Text(
          "Time's up!",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFE65100)),
        ),
        const SizedBox(height: 6),
        Text(
          'You popped $popped of ${widget.goal} $sound balloons. Try again!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: PracticeColors.ink),
        ),
        const SizedBox(height: 16),
        _buildButton('🔄', 'PLAY AGAIN', _start),
      ]),
    );
  }

  Widget _buildLevelDoneCard() {
    final next = sounds[level + 1];

    return Center(
      child: _buildCard(children: [
        const Text('🎉', style: TextStyle(fontSize: 56)),
        Text(
          'Sound $sound done!',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32)),
        ),
        const SizedBox(height: 6),
        Text(
          'You popped ${widget.goal} $sound balloons in ${widget.seconds - secondsLeft} seconds!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: PracticeColors.ink),
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'Next sound: '),
            TextSpan(text: next, style: const TextStyle(color: Color(0xFFD81B8C), fontSize: 24)),
          ]),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: PracticeColors.ink),
        ),
        const SizedBox(height: 16),
        _buildButton('➡️', 'NEXT LEVEL', () => _openLevel(level + 1)),
      ]),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _look.color, width: 4),
        boxShadow: [BoxShadow(color: _look.darkColor, offset: const Offset(0, 7))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _buildButton(String emoji, String label, VoidCallback onTap, {Color? color, Color? darkColor}) {
    return SizedBox(
      width: 220,
      child: ChunkyButton(
        emoji: emoji,
        label: label,
        color: color ?? _look.color,
        darkColor: darkColor ?? _look.darkColor,
        onTap: onTap,
      ),
    );
  }

  Widget _buildProgress() {
    return Row(
      children: [
        for (var i = 0; i < widget.goal; i++)
          Expanded(
            child: Container(
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i < popped ? _look.color : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _look.edgeColor, width: 2),
              ),
            ),
          ),
        const SizedBox(width: 8),
        Text(
          '🎈 $popped / ${widget.goal}',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _look.darkColor),
        ),
      ],
    );
  }
}
