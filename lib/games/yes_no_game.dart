import 'dart:math';

import 'package:flutter/material.dart';
import 'package:talkiepal/games/game_words.dart';
import 'package:talkiepal/games/widgets/game_scaffold.dart';
import 'package:talkiepal/practice/widgets/practice_scaffold.dart';
import 'package:talkiepal/practice/widgets/success_dialog.dart';
import 'package:talkiepal/services/exercise_service.dart';

/// One round: the picture shown and the word Dino asks about.
class _Round {
  final PracticeExercise picture;
  final String askedWord;

  const _Round(this.picture, this.askedWord);

  bool get isYes => askedWord == picture.word;
}

/// Yes or No?: Dino shows a picture and asks "Is it a CAT?".
/// The child taps YES or NO. The words come from the AI backend.
class YesNoGame extends StatefulWidget {
  final int rounds;

  const YesNoGame({super.key, this.rounds = 10});

  @override
  State<YesNoGame> createState() => _YesNoGameState();
}

class _YesNoGameState extends State<YesNoGame> {
  static const GameLook _look = GameLook.yesOrNo;

  static const Color _yesColor = Color(0xFF66BB6A);
  static const Color _yesDark = Color(0xFF2E7D32);
  static const Color _noColor = Color(0xFFFF6B6B);
  static const Color _noDark = Color(0xFFC62828);

  final Random _random = Random();

  bool isLoading = true;
  bool isPlaying = false;
  List<_Round> rounds = [];
  int currentIndex = 0;
  int stars = 0;

  // The answer tapped by mistake in this round (null = none), and whether it is solved.
  bool? wrongAnswer;
  bool isSolved = false;

  // Index of the question word lit up during LISTEN (-1 = none).
  int highlightedWord = -1;

  // Bumped whenever the round changes, so an old highlight run stops.
  int _highlightRun = 0;

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

  /// Every word becomes one round. Half ask about the picture itself (YES),
  /// half ask about another word (NO), in a random order.
  List<_Round> _buildRounds(List<PracticeExercise> words) {
    if (words.length < 2) return [];

    final answers = List.generate(words.length, (i) => i.isEven)..shuffle(_random);

    return [
      for (var i = 0; i < words.length; i++)
        _Round(
          words[i],
          answers[i] ? words[i].word : _otherWord(words, words[i]),
        ),
    ];
  }

  String _otherWord(List<PracticeExercise> words, PracticeExercise picture) {
    final others = words.where((e) => e != picture).toList();
    return others[_random.nextInt(others.length)].word;
  }

  /// "Is it a CAT?", "Is it an APPLE?" or "Are they SHOES?"
  String _question(String word) {
    final isPlural = word.endsWith('S') && !word.endsWith('SS') && !word.endsWith('US');
    if (isPlural) return 'Are they $word?';
    final article = 'AEIOU'.contains(word[0]) ? 'an' : 'a';
    return 'Is it $article $word?';
  }

  List<String> get questionWords => _question(currentRound.askedWord).split(' ');

  // Call inside setState.
  void _resetRound() {
    _highlightRun++;
    highlightedWord = -1;
    isPlaying = false;
    isSolved = false;
    wrongAnswer = null;
  }

  Future<void> _onListen() async {
    if (isPlaying) return;
    final run = ++_highlightRun;
    setState(() {
      isPlaying = true;
    });

    // Audio is not connected yet; the highlight shows the reading pace.
    final words = questionWords;
    for (var i = 0; i < words.length; i++) {
      if (!mounted || run != _highlightRun) return;
      setState(() {
        highlightedWord = i;
      });
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!mounted || run != _highlightRun) return;
    setState(() {
      highlightedWord = -1;
      isPlaying = false;
    });
  }

  void _onAnswer(bool saidYes) {
    if (isSolved || wrongAnswer == saidYes) return;

    setState(() {
      _highlightRun++;
      highlightedWord = -1;
      isPlaying = false;

      if (saidYes == currentRound.isYes) {
        isSolved = true;
        // A star only when it was right on the first try.
        if (wrongAnswer == null) stars++;
      } else {
        wrongAnswer = saidYes;
      }
    });
  }

  void _onNext() {
    if (currentIndex + 1 < rounds.length) {
      setState(() {
        currentIndex++;
        _resetRound();
      });
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
  Widget build(BuildContext context) {
    final hasGame = !isLoading && rounds.isNotEmpty;

    return GameScaffold(
      look: _look,
      title: 'Yes or No? 👍',
      stars: stars,
      current: hasGame ? currentIndex + 1 : 0,
      total: rounds.length,
      dinoTip: isSolved ? 'Yay! You got it! 🎉' : 'Look at the picture. Is it true? Say YES or NO!',
      isLoading: isLoading,
      loadingText: 'Dino is picking new pictures... ✨',
      children: hasGame ? _buildGame() : [_buildNoWords()],
    );
  }

  List<Widget> _buildGame() {
    final round = currentRound;
    final isLast = currentIndex == rounds.length - 1;
    final words = questionWords;

    final Color cardColor = isSolved ? _yesColor : (wrongAnswer != null ? _noColor : _look.color);
    final Color cardEdge = isSolved ? _yesDark : (wrongAnswer != null ? _noDark : _look.darkColor);

    return [
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: cardColor, width: 4),
          boxShadow: [BoxShadow(color: cardEdge, offset: const Offset(0, 7))],
        ),
        child: Column(
          children: [
            BigEmoji(emoji: round.picture.emoji, background: _look.lightColor),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 2,
              runSpacing: 4,
              children: [
                for (var i = 0; i < words.length; i++)
                  WordChip(text: words[i], isLit: i == highlightedWord, litColor: PracticeColors.listen, size: 26),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 180,
              child: ChunkyButton(
                emoji: '🔊',
                label: 'LISTEN',
                color: PracticeColors.listen,
                darkColor: PracticeColors.listenDark,
                busy: isPlaying,
                small: true,
                onTap: isSolved ? null : _onListen,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      if (isSolved) ...[
        Text(
          round.isYes
              ? '🎉 Yes! It is ${round.picture.word}!'
              : '🎉 Right! It is ${round.picture.word}, not ${round.askedWord}!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _yesDark),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 220,
          child: ChunkyButton(
            emoji: isLast ? '🏁' : '➡️',
            label: isLast ? 'FINISH' : 'NEXT',
            color: _yesColor,
            darkColor: _yesDark,
            onTap: _onNext,
          ),
        ),
      ] else ...[
        Row(
          children: [
            Expanded(child: _buildAnswerButton(true)),
            const SizedBox(width: 14),
            Expanded(child: _buildAnswerButton(false)),
          ],
        ),
        if (wrongAnswer != null) ...[
          const SizedBox(height: 16),
          const Text(
            'Oops! Look at the picture again 👀',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFE53935)),
          ),
        ],
      ],
    ];
  }

  Widget _buildAnswerButton(bool isYes) {
    final isWrong = wrongAnswer == isYes;

    return AnimatedOpacity(
      opacity: isWrong ? 0.4 : 1,
      duration: const Duration(milliseconds: 200),
      child: ChunkyButton(
        emoji: isWrong ? '❌' : (isYes ? '👍' : '👎'),
        label: isYes ? 'YES' : 'NO',
        color: isYes ? _yesColor : _noColor,
        darkColor: isYes ? _yesDark : _noDark,
        onTap: () => _onAnswer(isYes),
      ),
    );
  }

  Widget _buildNoWords() {
    return Column(
      children: [
        const Text(
          'Oh no! Dino could not find enough pictures. 🦖',
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
