import 'package:flutter/material.dart';
import 'package:talkiepal/game_page.dart';
import 'package:talkiepal/profile_page.dart';
import 'package:talkiepal/services/question_service.dart';
import 'package:talkiepal/services/speech_service.dart';
import 'package:talkiepal/practice/widgets/practice_scaffold.dart';
import 'package:talkiepal/practice/widgets/success_dialog.dart';
import 'package:talkiepal/widgets/kids_bottom_nav.dart';
import 'package:talkiepal/progress_page.dart';

/// Question-and-answer practice page for every Intermediate topic.
/// The questions come from the AI backend instead of being written in the code.
class AiQuestionPage extends StatefulWidget {
  final String topic;
  final int count;

  const AiQuestionPage({
    super.key,
    required this.topic,
    this.count = 10,
  });

  @override
  State<AiQuestionPage> createState() => _AiQuestionPageState();
}

class _AiQuestionPageState extends State<AiQuestionPage> {
  bool isLoading = true;
  bool isPlaying = false;
  int currentIndex = 0;
  List<PracticeQuestion> questions = [];

  // What is lit up during LISTEN (-1 = none).
  int highlightedWord = -1;
  int highlightedOption = -1;

  // Answer the child tapped that was not correct (-1 = none).
  int wrongOption = -1;

  // Bumped whenever the question changes, so an old highlight run stops.
  int _highlightRun = 0;

  PracticeQuestion get currentQuestion => questions[currentIndex];

  List<String> get questionWords => currentQuestion.question.split(' ');

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      isLoading = true;
      currentIndex = 0;
      _stopHighlight();
    });

    final result = await QuestionService.getQuestions(
      topic: widget.topic,
      count: widget.count,
    );

    if (!mounted) return;

    setState(() {
      questions = result.questions;
      isLoading = false;
    });

    if (result.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📴 AI is offline. Using practice questions instead.'),
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
    highlightedWord = -1;
    highlightedOption = -1;
    wrongOption = -1;
    isPlaying = false;
  }

  /// Reads the question aloud word by word, then each answer.
  /// Returns false if it was stopped because the question changed.
  Future<bool> _playHighlight() async {
    final run = ++_highlightRun;
    bool stillHere() => mounted && run == _highlightRun;

    // The question, one word at a time, each lit as it is spoken.
    await speakWordByWord(
      currentQuestion.question,
      keepGoing: stillHere,
      onWord: (i) => setState(() {
        highlightedWord = i;
        highlightedOption = -1;
      }),
    );

    // Then each answer: A..., B..., C...
    for (var i = 0; i < currentQuestion.options.length; i++) {
      if (!stillHere()) return false;
      setState(() {
        highlightedWord = -1;
        highlightedOption = i;
      });
      await SpeechService.instance.speak('${String.fromCharCode(65 + i)}. ${currentQuestion.options[i]}');
      // A short pause between answers.
      if (stillHere()) await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!stillHere()) return false;
    setState(() {
      highlightedWord = -1;
      highlightedOption = -1;
    });
    return true;
  }

  @override
  void dispose() {
    SpeechService.instance.stop();
    super.dispose();
  }

  Future<void> _onListen() async {
    if (isPlaying) return;
    setState(() {
      isPlaying = true;
    });

    final finished = await _playHighlight();

    if (!mounted || !finished) return;
    setState(() {
      isPlaying = false;
    });
  }

  void _onOptionTap(int i) {
    if (isPlaying) return;
    SpeechService.instance.stop();

    if (i == currentQuestion.correctIndex) {
      setState(() {
        wrongOption = -1;
      });
      _showResultDialog();
    } else {
      setState(() {
        wrongOption = i;
      });
      _showTryAgainDialog();
    }
  }

  void _showTryAgainDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB6B6), Color(0xFFFF6B6B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '❌ OOPS! ❌',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'That is not the right answer. Listen again and try another one!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 20),
                _buildDialogButton(
                  label: 'TRY AGAIN',
                  color: const Color(0xFFFF6B6B),
                  margin: EdgeInsets.zero,
                  onTap: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _finish() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Congratulations! You completed all questions! 🎉'),
        backgroundColor: Color(0xFFA8D5A2),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  void _goToNextQuestion() {
    if (currentIndex + 1 < questions.length) {
      setState(() {
        currentIndex++;
        _stopHighlight();
      });
    } else {
      _finish();
    }
  }

  void _showResultDialog() {
    final bool isLastQuestion = currentIndex == questions.length - 1;

    showSuccessDialog(
      context,
      detail: '"${currentQuestion.correctAnswer}"',
      nextLabel: isLastQuestion ? 'FINISH →' : 'NEXT →',
      onNext: _goToNextQuestion,
    );
  }

  Widget _buildDialogButton({
    required String label,
    required EdgeInsets margin,
    required VoidCallback onTap,
    Color color = const Color(0xFF6BCB77),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  static const PracticeLook _look = PracticeLook.intermediate;

  // Pastel colours for answers A, B and C: [background, bottom edge].
  static const List<List<Color>> _answerColors = [
    [Color(0xFFE3F2FD), Color(0xFF90CAF9)],
    [Color(0xFFE8F5E9), Color(0xFFA5D6A7)],
    [Color(0xFFFFF3D6), Color(0xFFFFCC80)],
  ];

  @override
  Widget build(BuildContext context) {
    return PracticeScaffold(
      look: _look,
      title: widget.topic,
      current: isLoading ? 0 : currentIndex + 1,
      total: questions.length,
      dinoTip: 'Listen to my question, then tap the right answer!',
      isLoading: isLoading,
      loadingText: 'Creating new questions for you... ✨',
      onRefresh: _loadQuestions,
      onNavTap: _onNavTap,
      children: isLoading || questions.isEmpty
          ? const []
          : [
              _buildQuestionCard(),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tap the right answer 👇',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF6B4C7A)),
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < currentQuestion.options.length; i++) _buildOption(i),
            ],
    );
  }

  Widget _buildQuestionCard() {
    final words = questionWords;

    return PracticeCard(
      look: _look,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: _look.lightColor, borderRadius: BorderRadius.circular(12)),
            child: Text(
              'QUESTION ❓',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _look.darkColor, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              for (var i = 0; i < words.length; i++)
                WordChip(text: words[i], isLit: i == highlightedWord, litColor: _look.color, size: 24),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 200,
            child: ChunkyButton(
              emoji: '🔊',
              label: 'LISTEN',
              color: PracticeColors.listen,
              darkColor: PracticeColors.listenDark,
              busy: isPlaying,
              small: true,
              onTap: _onListen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(int i) {
    final isLit = highlightedOption == i;
    final isWrong = !isLit && wrongOption == i;
    final colors = _answerColors[i % _answerColors.length];

    const Color wrongColor = Color(0xFFFF6B6B);
    const Color litColor = Color(0xFFFFB300);

    final Color background = isWrong ? const Color(0xFFFFEBEE) : colors[0];
    final Color edge = isWrong ? const Color(0xFFFFB3B3) : (isLit ? litColor : colors[1]);
    final Color border = isWrong ? wrongColor : (isLit ? litColor : Colors.white);

    return GestureDetector(
      onTap: () => _onOptionTap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border, width: 3),
          boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isWrong ? wrongColor : (isLit ? litColor : Colors.white),
                shape: BoxShape.circle,
              ),
              child: Text(
                String.fromCharCode(65 + i),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isWrong || isLit ? Colors.white : _look.darkColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                currentQuestion.options[i],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isWrong ? const Color(0xFFE53935) : PracticeColors.ink,
                ),
              ),
            ),
            if (isWrong) const Text('❌', style: TextStyle(fontSize: 18)),
          ],
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
