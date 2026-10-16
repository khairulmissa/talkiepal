import 'package:flutter/material.dart';
import 'package:talkiepal/game_page.dart';
import 'package:talkiepal/profile_page.dart';
import 'package:talkiepal/services/question_service.dart';
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
    this.count = 5,
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
    _highlightRun++;
    highlightedWord = -1;
    highlightedOption = -1;
    wrongOption = -1;
    isPlaying = false;
  }

  /// Lights up the question word by word, then each answer.
  /// Returns false if it was stopped because the question changed.
  Future<bool> _playHighlight() async {
    final run = ++_highlightRun;

    Future<bool> step(int word, int option, Duration wait) async {
      if (!mounted || run != _highlightRun) return false;
      setState(() {
        highlightedWord = word;
        highlightedOption = option;
      });
      await Future.delayed(wait);
      return mounted && run == _highlightRun;
    }

    for (var i = 0; i < questionWords.length; i++) {
      if (!await step(i, -1, const Duration(milliseconds: 500))) return false;
    }
    for (var i = 0; i < currentQuestion.options.length; i++) {
      if (!await step(-1, i, const Duration(milliseconds: 1500))) return false;
    }
    return step(-1, -1, Duration.zero);
  }

  Future<void> _onListen() async {
    if (isPlaying) return;
    setState(() {
      isPlaying = true;
    });

    // Audio is not connected yet; the highlight shows the reading pace.
    final finished = await _playHighlight();

    if (!mounted || !finished) return;
    setState(() {
      isPlaying = false;
    });
  }

  void _onOptionTap(int i) {
    if (isPlaying) return;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/images/fullbg_beginnerpractice.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      _buildHeader(),
                      const SizedBox(height: 20),
                      if (isLoading) _buildLoadingCard() else ..._buildQuestionContent(),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCircleButton(Icons.arrow_back, () => Navigator.pop(context)),
        Flexible(
          child: Column(
          children: [
            Text(
              widget.topic.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4C7A),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8D5F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isLoading ? 'Loading...' : '${currentIndex + 1} of ${questions.length}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF8B5E9E)),
              ),
            ),
          ],
          ),
        ),
        // New questions button
        _buildCircleButton(Icons.refresh, isLoading ? null : _loadQuestions),
      ],
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFE8D5F0),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 24, color: const Color(0xFF8B5E9E)),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E0),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFFFCC99),
          width: 1.5,
        ),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: Color(0xFF8B5E9E)),
          SizedBox(height: 15),
          Text(
            'Creating new questions for you... ✨',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B4C7A),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildQuestionContent() {
    return [
      _buildQuestionCard(),
      const SizedBox(height: 20),
      _buildListenButton(),
      const SizedBox(height: 25),
      const Text(
        'CHOOSE THE CORRECT ANSWER:',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6B4C7A),
        ),
      ),
      const SizedBox(height: 15),
      for (var i = 0; i < currentQuestion.options.length; i++) _buildOption(i),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F4FD),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb, size: 20, color: Color(0xFF9C27B0)),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Listen, then tap the correct answer!',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B4C7A)),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildQuestionCard() {
    final words = questionWords;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC9B3E0), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'QUESTION',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: List.generate(words.length, (i) {
              final isLit = highlightedWord == i;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isLit ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  words[i],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isLit ? const Color(0xFF9C27B0) : Colors.white,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildListenButton() {
    return Center(
      child: GestureDetector(
        onTap: _onListen,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isPlaying ? Colors.grey : const Color(0xFFC9B3E0),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_arrow,
                size: 20,
                color: isPlaying ? Colors.white60 : Colors.white,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isPlaying ? 'PLAYING...' : '🔊 LISTEN TO QUESTION & ANSWERS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPlaying ? Colors.white60 : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(int i) {
    final isLit = highlightedOption == i;
    final isWrong = !isLit && wrongOption == i;

    final Color accent = isLit
        ? const Color(0xFFFFB347)
        : isWrong
            ? const Color(0xFFFF6B6B)
            : const Color(0xFFE8D5F0);

    return GestureDetector(
      onTap: () => _onOptionTap(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isLit || isWrong ? accent.withValues(alpha: 0.2) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isLit || isWrong ? accent : Colors.grey.shade300,
            width: isLit || isWrong ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + i),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isLit || isWrong ? Colors.white : const Color(0xFF8B5E9E),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                currentQuestion.options[i],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isLit || isWrong ? FontWeight.bold : FontWeight.normal,
                  color: isLit
                      ? const Color(0xFFE67E22)
                      : isWrong
                          ? const Color(0xFFFF6B6B)
                          : const Color(0xFF5D3A6B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return KidsBottomNav(selected: null, onTap: _onNavTap);
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
