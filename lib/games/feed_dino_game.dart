import 'dart:math';

import 'package:flutter/material.dart';
import 'package:talkiepal/games/food_words.dart';
import 'package:talkiepal/games/game_words.dart';
import 'package:talkiepal/games/game_result_page.dart';
import 'package:talkiepal/games/widgets/game_scaffold.dart';
import 'package:talkiepal/practice/widgets/practice_scaffold.dart';
import 'package:talkiepal/services/exercise_service.dart';
import 'package:talkiepal/services/speech_service.dart';
import 'package:talkiepal/widgets/dino_mascot.dart';

/// One round: the food Dino asks for and the four foods on the tray.
class _Round {
  final PracticeExercise target;
  final List<PracticeExercise> foods;

  const _Round(this.target, this.foods);
}

/// Feed the Dino: Dino asks for a food by name and the child drags the
/// right picture into Dino's mouth. The words come from the AI backend.
class FeedDinoGame extends StatefulWidget {
  final int rounds;

  const FeedDinoGame({super.key, this.rounds = 10});

  @override
  State<FeedDinoGame> createState() => _FeedDinoGameState();
}

class _FeedDinoGameState extends State<FeedDinoGame> {
  static const GameLook _look = GameLook.feedDino;

  static const Color _green = Color(0xFF43A047);
  static const Color _greenDark = Color(0xFF2E7D32);
  static const Color _red = Color(0xFFFF6B6B);

  final Random _random = Random();

  bool isLoading = true;
  bool isPlaying = false;
  List<_Round> rounds = [];
  int currentIndex = 0;
  int stars = 0;

  // Foods given by mistake in this round, and whether Dino got the right one.
  Set<int> wrongFoods = {};
  bool isFed = false;

  // The food Dino just refused (-1 = none), to say what it was.
  int lastWrong = -1;

  // Bumped whenever the round changes, so an old sound run stops.
  int _playRun = 0;

  // Right on the first try or not, for the results screen.
  FirstTryScore _score = FirstTryScore();

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

    final result = await GameWords.load(count: widget.rounds, random: _random, from: const ['Fruits']);

    if (!mounted) return;

    setState(() {
      // Only real food words, each with its own picture.
      rounds = _buildRounds(FoodWords.pick(result.words, widget.rounds, _random));
      isLoading = false;
    });
    _score = FirstTryScore();
    _scoreRound();
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

  /// Every food becomes one round, with three other foods on the tray.
  List<_Round> _buildRounds(List<PracticeExercise> words) {
    if (words.length < 4) return [];

    return words.map((target) {
      final others = words.where((e) => e != target).toList()..shuffle(_random);
      final foods = [target, ...others.take(3)]..shuffle(_random);
      return _Round(target, foods);
    }).toList();
  }

  // Call inside setState.
  void _resetRound() {
    SpeechService.instance.stop();
    _playRun++;
    isPlaying = false;
    isFed = false;
    wrongFoods = {};
    lastWrong = -1;
  }

  Future<void> _onPlaySound() async {
    if (isPlaying) return;
    final run = ++_playRun;
    setState(() {
      isPlaying = true;
    });

    await SpeechService.instance.speak('Give me the ${toSpoken(currentRound.target.word)}!');

    if (!mounted || run != _playRun) return;
    setState(() {
      isPlaying = false;
    });
  }

  void _scoreRound() {
    if (rounds.isEmpty) return;
    final target = currentRound.target;
    _score.newRound(lead: target.emoji, label: target.word, answer: target.word);
  }

  /// Dino asks for the food out loud when a new round starts.
  void _autoPlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !isLoading && rounds.isNotEmpty) _onPlaySound();
    });
  }

  void _onFeed(int i) {
    if (isFed || wrongFoods.contains(i)) return;

    setState(() {
      if (currentRound.foods[i] == currentRound.target) {
        isFed = true;
        lastWrong = -1;
        // A star only when it was right on the first try.
        if (wrongFoods.isEmpty) stars++;
      } else {
        wrongFoods = {...wrongFoods, i};
        _score.wrong(currentRound.foods[i].word);
        lastWrong = i;
      }
    });
  }

  void _onNext() {
    if (currentIndex + 1 < rounds.length) {
      setState(() {
        currentIndex++;
        _resetRound();
      });
      _scoreRound();
      _autoPlay();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GameResultPage(
            result: _score.result(
              title: 'Feed the Dino',
              look: _look,
              praise: 'Yummy job',
              emoji: '😋',
              heard: 'wanted',
              picked: 'gave',
            ),
            playAgain: () => FeedDinoGame(rounds: widget.rounds),
          ),
        ),
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
      title: 'Feed the Dino 🦕',
      stars: stars,
      current: hasGame ? currentIndex + 1 : 0,
      total: rounds.length,
      dinoTip: hasGame ? null : 'I am so hungry! Let me find some food...',
      isLoading: isLoading,
      loadingText: 'Dino is looking for food... ✨',
      children: hasGame ? _buildGame() : [_buildNoFood()],
    );
  }

  List<Widget> _buildGame() {
    final isLast = currentIndex == rounds.length - 1;

    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          color: _look.lightColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _look.edgeColor, width: 4),
        ),
        child: Column(
          children: [
            _buildRequest(),
            const SizedBox(height: 10),
            _buildDino(),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < currentRound.foods.length; i++)
                  Expanded(child: Center(child: _buildFood(i))),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      if (isFed) ...[
        Text(
          '😋 Yum yum! Thank you for the ${currentRound.target.word}!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _greenDark),
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
      ] else
        Text(
          lastWrong >= 0
              ? 'Hmm, that is ${currentRound.foods[lastWrong].word}. Try another one! 🤔'
              : 'Drag the food into Dino\'s mouth!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: lastWrong >= 0 ? const Color(0xFFE53935) : _look.darkColor,
          ),
        ),
    ];
  }

  /// What Dino asks for. Only the word, no picture, so the answer is not given away.
  Widget _buildRequest() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: _look.edgeColor, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(
            isFed ? 'Yum! That was...' : 'I am hungry! 😋 Give me...',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: PracticeColors.soft),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'the ${currentRound.target.word}',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: _look.color),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _onPlaySound,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isPlaying ? PracticeColors.listen : const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isPlaying ? '🔊 PLAYING...' : '🔊 TAP TO HEAR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: isPlaying ? Colors.white : const Color(0xFF1565C0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Big Dino that accepts dropped food.
  Widget _buildDino() {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => !isFed && !wrongFoods.contains(details.data),
      onAcceptWithDetails: (details) => _onFeed(details.data),
      builder: (context, candidates, rejected) {
        final isHovering = candidates.isNotEmpty;

        return SizedBox(
          height: 210,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow when food is held over Dino
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isHovering ? 200 : 170,
                height: isHovering ? 200 : 170,
                decoration: BoxDecoration(
                  color: isHovering ? Colors.white : Colors.white.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isHovering ? _look.color : Colors.transparent,
                    width: 4,
                  ),
                ),
              ),
              AnimatedScale(
                scale: isFed ? 1.12 : (isHovering ? 1.06 : 1),
                duration: const Duration(milliseconds: 250),
                curve: Curves.elasticOut,
                child: DinoMascot(color: _look.dinoColor, size: 160),
              ),
              if (isFed)
                Positioned(top: 4, right: 30, child: _buildBubble('😋', _green)),
              if (!isFed && lastWrong >= 0)
                Positioned(top: 4, right: 30, child: _buildBubble('🙅', _red)),
              if (isHovering)
                Positioned(top: 4, left: 30, child: _buildBubble('😮', _look.color)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBubble(String emoji, Color border) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 3),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 28)),
    );
  }

  /// One food on the tray: picture only, no name, so the child has to know the word.
  Widget _buildFood(int i) {
    final food = currentRound.foods[i];
    final isGiven = isFed && food == currentRound.target;
    final isWrong = wrongFoods.contains(i);
    final canDrag = !isFed && !isWrong;

    final card = _buildFoodCard(food.emoji, isWrong: isWrong, isGiven: isGiven, isDim: isFed && !isGiven);

    if (!canDrag) return card;

    return Draggable<int>(
      data: i,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.rotate(angle: -0.15, child: _buildFoodCard(food.emoji, isLifted: true)),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      // Only dropping the food on Dino counts; a tap does nothing.
      child: card,
    );
  }

  Widget _buildFoodCard(
    String emoji, {
    bool isWrong = false,
    bool isGiven = false,
    bool isDim = false,
    bool isLifted = false,
  }) {
    final Color border = isGiven
        ? _green
        : (isWrong ? _red : (isLifted ? _look.color : _look.edgeColor));

    return AnimatedOpacity(
      opacity: isWrong || isDim ? 0.4 : 1,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 72,
        height: 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isGiven ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border, width: 3),
          boxShadow: [
            BoxShadow(
              color: isLifted ? const Color(0x55000000) : const Color(0xFFFFB74D),
              offset: Offset(0, isLifted ? 10 : 5),
              blurRadius: isLifted ? 10 : 0,
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 42)),
            if (isWrong || isGiven)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(color: isGiven ? _green : _red, shape: BoxShape.circle),
                  child: Icon(
                    isGiven ? Icons.check_rounded : Icons.close_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFood() {
    return Column(
      children: [
        const Text(
          'Oh no! Dino could not find any food. 🦖',
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
