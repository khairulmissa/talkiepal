import 'dart:math';

import 'package:flutter/material.dart';
import 'package:talkiepal/games/game_words.dart';
import 'package:talkiepal/games/widgets/game_scaffold.dart';
import 'package:talkiepal/practice/widgets/practice_scaffold.dart';
import 'package:talkiepal/practice/widgets/success_dialog.dart';
import 'package:talkiepal/services/exercise_service.dart';
import 'package:talkiepal/services/speech_service.dart';

/// One round: the word Dino says and the four pictures to pick from.
class _Round {
  final PracticeExercise target;
  final List<PracticeExercise> options;

  const _Round(this.target, this.options);
}

/// Sound Matcher: Dino says a word, the child taps the matching picture.
/// The words come from the AI backend (Beginner words).
class SoundMatcherGame extends StatefulWidget {
  final int rounds;

  const SoundMatcherGame({super.key, this.rounds = 10});

  @override
  State<SoundMatcherGame> createState() => _SoundMatcherGameState();
}

class _SoundMatcherGameState extends State<SoundMatcherGame> {
  static const GameLook _look = GameLook.soundMatcher;

  static const Color _green = Color(0xFF43A047);
  static const Color _greenDark = Color(0xFF2E7D32);
  static const Color _red = Color(0xFFFF6B6B);

  final Random _random = Random();

  bool isLoading = true;
  bool isPlaying = false;
  List<_Round> rounds = [];
  int currentIndex = 0;
  int stars = 0;

  // Pictures tapped by mistake in this round, and whether it is solved.
  Set<int> wrongPicks = {};
  bool isSolved = false;

  // Bumped whenever the round changes, so an old sound run stops.
  int _playRun = 0;

  _Round get currentRound => rounds[currentIndex];

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  Future<void> _loadGame() async {
    setState(() {
      isLoading = true;
      currentIndex = 0;
      stars = 0;
      _resetRound();
    });

    final result = await GameWords.load(count: widget.rounds, random: _random);

    if (!mounted) return;

    setState(() {
      rounds = _buildRounds(result.words);
      isLoading = false;
    });
    _autoPlay();

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

  /// Every word becomes one round, with three other words as wrong pictures.
  List<_Round> _buildRounds(List<PracticeExercise> words) {
    if (words.length < 4) return [];

    return words.map((target) {
      final others = words.where((e) => e != target).toList()..shuffle(_random);
      final options = [target, ...others.take(3)]..shuffle(_random);
      return _Round(target, options);
    }).toList();
  }

  // Call inside setState.
  void _resetRound() {
    SpeechService.instance.stop();
    _playRun++;
    isPlaying = false;
    isSolved = false;
    wrongPicks = {};
  }

  Future<void> _onPlaySound() async {
    if (isPlaying) return;
    final run = ++_playRun;
    setState(() {
      isPlaying = true;
    });

    await SpeechService.instance.speak(toSpoken(currentRound.target.word));

    if (!mounted || run != _playRun) return;
    setState(() {
      isPlaying = false;
    });
  }

  /// Says the word by itself when a new round starts, so the child can just listen.
  void _autoPlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !isLoading && rounds.isNotEmpty) _onPlaySound();
    });
  }

  void _onPictureTap(int i) {
    if (isSolved || wrongPicks.contains(i)) return;

    if (currentRound.options[i] == currentRound.target) {
      setState(() {
        isSolved = true;
        isPlaying = false;
        _playRun++;
        // A star only when it was right on the first try.
        if (wrongPicks.isEmpty) stars++;
      });
    } else {
      setState(() {
        wrongPicks = {...wrongPicks, i};
      });
    }
  }

  void _onNext() {
    if (currentIndex + 1 < rounds.length) {
      setState(() {
        currentIndex++;
        _resetRound();
      });
      _autoPlay();
    } else {
      showSuccessDialog(
        context,
        detail: 'You got $stars ⭐ out of ${rounds.length}!',
        nextLabel: 'FINISH →',
        onNext: () => Navigator.pop(context),
      );
    }
  }

  @override
  void dispose() {
    SpeechService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasGame = !isLoading && rounds.isNotEmpty;

    return GameScaffold(
      look: _look,
      title: 'Sound Matcher 🔊',
      stars: stars,
      current: hasGame ? currentIndex + 1 : 0,
      total: rounds.length,
      dinoTip: isSolved ? 'Yay! You found it! 🎉' : 'Listen! Which picture did I say?',
      isLoading: isLoading,
      loadingText: 'Dino is picking new words... ✨',
      children: hasGame ? _buildGame() : [_buildNoWords()],
    );
  }

  List<Widget> _buildGame() {
    final round = currentRound;
    final isLast = currentIndex == rounds.length - 1;

    return [
      SizedBox(
        width: 230,
        child: ChunkyButton(
          emoji: '🔊',
          label: 'PLAY SOUND',
          color: PracticeColors.listen,
          darkColor: PracticeColors.listenDark,
          busy: isPlaying,
          onTap: isSolved ? null : _onPlaySound,
        ),
      ),
      const SizedBox(height: 10),
      const SizedBox(height: 16),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.05,
        children: [
          for (var i = 0; i < round.options.length; i++) _buildPicture(i),
        ],
      ),
      const SizedBox(height: 14),
      if (isSolved) ...[
        Text(
          '🎉 Yes! It is ${round.target.word}!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _greenDark),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: 220,
          child: ChunkyButton(
            emoji: isLast ? '🏁' : '➡️',
            label: isLast ? 'FINISH' : 'NEXT',
            color: _green,
            darkColor: _greenDark,
            onTap: _onNext,
          ),
        ),
      ] else if (wrongPicks.isNotEmpty)
        const Text(
          'Oops! Listen again and try another one 👂',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFE53935)),
        ),
    ];
  }

  Widget _buildPicture(int i) {
    final option = currentRound.options[i];
    final isCorrect = isSolved && option == currentRound.target;
    final isWrong = wrongPicks.contains(i);
    final isDim = isSolved && !isCorrect;

    final Color border = isCorrect ? _green : (isWrong ? _red : _look.edgeColor);
    final Color edge = isCorrect ? _greenDark : (isWrong ? const Color(0xFFFFB3B3) : const Color(0xFF64B5F6));
    final Color background = isCorrect
        ? const Color(0xFFE8F5E9)
        : (isWrong ? const Color(0xFFFFEBEE) : Colors.white);

    return GestureDetector(
      onTap: () => _onPictureTap(i),
      child: AnimatedOpacity(
        opacity: isDim || isWrong ? 0.5 : 1,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.fromLTRB(4, 4, 4, 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border, width: 4),
            boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 6))],
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(option.emoji, style: const TextStyle(fontSize: 56)),
                    const SizedBox(height: 4),
                    Text(
                      option.word,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: PracticeColors.ink),
                    ),
                  ],
                ),
              ),
              if (isCorrect || isWrong)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: isCorrect ? _green : _red, shape: BoxShape.circle),
                    child: Icon(
                      isCorrect ? Icons.check_rounded : Icons.close_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoWords() {
    return Column(
      children: [
        const Text(
          'Oh no! Dino could not find enough words. 🦖',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: PracticeColors.ink),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 220,
          child: ChunkyButton(
            emoji: '🔄',
            label: 'TRY AGAIN',
            color: _look.color,
            darkColor: _look.darkColor,
            onTap: _loadGame,
          ),
        ),
      ],
    );
  }
}
