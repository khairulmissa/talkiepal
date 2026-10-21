import 'dart:math';

import 'package:flutter/material.dart';
import 'package:talkiepal/games/game_result_page.dart';
import 'package:talkiepal/games/widgets/game_scaffold.dart';
import 'package:talkiepal/practice/widgets/practice_scaffold.dart';
import 'package:talkiepal/services/exercise_service.dart';
import 'package:talkiepal/services/minimal_pair_service.dart';
import 'package:talkiepal/services/speech_service.dart';

/// One round: a pair of words and the one Dino says.
class _Round {
  final MinimalPair pair;
  final bool saysA;

  const _Round(this.pair, this.saysA);

  PracticeExercise get target => saysA ? pair.a : pair.b;
  PracticeExercise get other => saysA ? pair.b : pair.a;
}

/// Where two words are different: CAT / RAT share "AT", so only the start differs.
class _Difference {
  final int prefix;
  final int suffix;

  const _Difference(this.prefix, this.suffix);

  factory _Difference.of(String a, String b) {
    var prefix = 0;
    while (prefix < min(a.length, b.length) && a[prefix] == b[prefix]) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < min(a.length, b.length) - prefix && a[a.length - 1 - suffix] == b[b.length - 1 - suffix]) {
      suffix++;
    }
    return _Difference(prefix, suffix);
  }

  /// The sounds that are different, e.g. "R ↔ W" for RED / WED.
  String mixedUp(String a, String b) {
    String part(String w) => w.substring(prefix, max(prefix, w.length - suffix));
    final sounds = [part(a), part(b)]..sort();
    return sounds.join(' ↔ ');
  }

  String get hint {
    if (prefix == 0) return 'ONLY THE FIRST SOUND IS DIFFERENT!';
    if (suffix == 0) return 'ONLY THE LAST SOUND IS DIFFERENT!';
    return 'ONLY THE MIDDLE SOUND IS DIFFERENT!';
  }
}

/// Minimal Pairs: Dino says one of two words that sound almost the same
/// (CAT or RAT?) and the child taps the right picture.
/// The pairs come from the AI backend.
class MinimalPairsGame extends StatefulWidget {
  final int rounds;

  const MinimalPairsGame({super.key, this.rounds = 10});

  @override
  State<MinimalPairsGame> createState() => _MinimalPairsGameState();
}

class _MinimalPairsGameState extends State<MinimalPairsGame> {
  static const GameLook _look = GameLook.minimalPairs;

  // Colours for the two cards: [main, bottom edge].
  static const List<Color> _cardA = [Color(0xFFD81B60), Color(0xFFAD1457)];
  static const List<Color> _cardB = [Color(0xFF7E57C2), Color(0xFF5E35B1)];

  static const Color _green = Color(0xFF43A047);
  static const Color _greenDark = Color(0xFF2E7D32);
  static const Color _red = Color(0xFFFF6B6B);

  final Random _random = Random();

  bool isLoading = true;
  bool isPlaying = false;
  List<_Round> rounds = [];
  int currentIndex = 0;
  int stars = 0;

  // The card tapped by mistake in this round (null = none), and whether it is solved.
  bool? wrongPickA;
  bool isSolved = false;

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

    final result = await MinimalPairService.getPairs(count: widget.rounds);

    if (!mounted) return;

    setState(() {
      rounds = [for (final pair in result.pairs) _Round(pair, _random.nextBool())];
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

  // Call inside setState.
  void _resetRound() {
    SpeechService.instance.stop();
    _playRun++;
    isPlaying = false;
    isSolved = false;
    wrongPickA = null;
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

  void _scoreRound() {
    if (rounds.isEmpty) return;
    final round = currentRound;
    _score.newRound(
      lead: round.target.emoji,
      label: '${round.pair.a.word}  vs  ${round.pair.b.word}',
      answer: round.target.word,
    );
  }

  /// Says the word by itself when a new round starts, so the child can just listen.
  void _autoPlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !isLoading && rounds.isNotEmpty) _onPlaySound();
    });
  }

  void _onCardTap(bool isA) {
    if (isSolved || wrongPickA == isA) return;

    setState(() {
      _playRun++;
      isPlaying = false;

      if (isA == currentRound.saysA) {
        isSolved = true;
        // A star only when it was right on the first try.
        if (wrongPickA == null) stars++;
      } else {
        wrongPickA = isA;
        final round = currentRound;
        _score.wrong(
          round.other.word,
          mixedUp: _Difference.of(round.pair.a.word, round.pair.b.word).mixedUp(round.pair.a.word, round.pair.b.word),
        );
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
            result: _score.result(title: 'Minimal Pairs', look: _look, praise: 'Great listening', emoji: '👂'),
            playAgain: () => MinimalPairsGame(rounds: widget.rounds),
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
    final pair = hasGame ? currentRound.pair : null;

    return GameScaffold(
      look: _look,
      title: 'Minimal Pairs 👂',
      stars: stars,
      current: hasGame ? currentIndex + 1 : 0,
      total: rounds.length,
      dinoTip: isSolved
          ? 'Yay! Your ears are super! 🎉'
          : (pair == null
              ? 'Listen carefully!'
              : 'Listen carefully! Did I say ${pair.a.word} or ${pair.b.word}?'),
      isLoading: isLoading,
      loadingText: 'Dino is finding words that sound alike... ✨',
      children: hasGame ? _buildGame() : [_buildNoPairs()],
    );
  }

  List<Widget> _buildGame() {
    final round = currentRound;
    final isLast = currentIndex == rounds.length - 1;
    final difference = _Difference.of(round.pair.a.word, round.pair.b.word);

    return [
      GestureDetector(
        onTap: isSolved ? null : _onPlaySound,
        child: AnimatedOpacity(
          opacity: isPlaying ? 0.7 : 1,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 110,
            height: 110,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PracticeColors.listen,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 5),
              boxShadow: const [BoxShadow(color: PracticeColors.listenDark, offset: Offset(0, 7))],
            ),
            child: const Text('🔊', style: TextStyle(fontSize: 52)),
          ),
        ),
      ),
      const SizedBox(height: 10),
      // No word shown here: the child has to listen.
      SizedBox(
        height: 34,
        child: Text(
          isPlaying ? '👂 Listen...' : 'Tap to hear the word again',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: PracticeColors.soft),
        ),
      ),
      const SizedBox(height: 14),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildCard(true, difference)),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('or', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: PracticeColors.soft)),
              ),
            ),
            Expanded(child: _buildCard(false, difference)),
          ],
        ),
      ),
      const SizedBox(height: 22),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: _look.lightColor, borderRadius: BorderRadius.circular(10)),
        child: Text(
          difference.hint,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _look.color, letterSpacing: 1),
        ),
      ),
      const SizedBox(height: 16),
      if (isSolved) ...[
        Text(
          '🎉 Yes! I said ${round.target.word}!',
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
      ] else if (wrongPickA != null)
        Text(
          'Oops! That was ${round.other.word}. Listen again 👂',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFE53935)),
        ),
    ];
  }

  Widget _buildCard(bool isA, _Difference difference) {
    final round = currentRound;
    final word = isA ? round.pair.a : round.pair.b;
    final colors = isA ? _cardA : _cardB;

    final isCorrect = isSolved && isA == round.saysA;
    final isWrong = wrongPickA == isA;
    final isDim = (isSolved && !isCorrect) || isWrong;

    final Color border = isCorrect ? _green : (isWrong ? _red : colors[0]);
    final Color edge = isCorrect ? _greenDark : (isWrong ? const Color(0xFFFFB3B3) : colors[1]);
    final Color background = isCorrect
        ? const Color(0xFFE8F5E9)
        : (isWrong ? const Color(0xFFFFEBEE) : Colors.white);

    // Split the word so the different sound can be coloured.
    final text = word.word;
    final start = difference.prefix;
    final end = text.length - difference.suffix;

    return GestureDetector(
      onTap: () => _onCardTap(isA),
      child: AnimatedOpacity(
        opacity: isDim ? 0.5 : 1,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: border, width: 4),
            boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 7))],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(word.emoji, style: const TextStyle(fontSize: 70)),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: text.substring(0, start)),
                        TextSpan(text: text.substring(start, end), style: TextStyle(color: colors[0])),
                        TextSpan(text: text.substring(end)),
                      ]),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: PracticeColors.ink,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
              if (isCorrect || isWrong)
                Positioned(
                  top: -10,
                  right: 0,
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

  Widget _buildNoPairs() {
    return Column(
      children: [
        const Text(
          'Oh no! Dino could not find any words. 🦖',
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
