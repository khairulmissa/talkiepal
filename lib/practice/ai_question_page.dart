import 'package:flutter/material.dart';
import 'package:talkiepal/game_page.dart';
import 'package:talkiepal/profile_page.dart';
import 'package:talkiepal/services/question_service.dart';
import 'package:talkiepal/services/speech_service.dart';
import 'package:talkiepal/practice/practice_session.dart';
import 'package:talkiepal/practice/result_page.dart';
import 'package:talkiepal/practice/speak_check.dart';
import 'package:talkiepal/practice/widgets/practice_scaffold.dart';
import 'package:talkiepal/practice/widgets/success_dialog.dart';
import 'package:talkiepal/widgets/kids_bottom_nav.dart';
import 'package:talkiepal/progress_page.dart';

class AiQuestionPage extends StatefulWidget {
  final String topic;
  final int count;

  final List<PracticeQuestion>? initialQuestions;

  const AiQuestionPage({
    super.key,
    required this.topic,
    this.count = 10,
    this.initialQuestions,
  });

  @override
  State<AiQuestionPage> createState() => _AiQuestionPageState();
}

class _AiQuestionPageState extends State<AiQuestionPage> with HoldToSpeak {
  bool isLoading = true;
  bool isPlaying = false;
  int currentIndex = 0;
  List<PracticeQuestion> questions = [];

  PracticeSession session = PracticeSession(isQuiz: true);

  int highlightedWord = -1;
  int highlightedOption = -1;

  int _highlightRun = 0;

  PracticeQuestion get currentQuestion => questions[currentIndex];

  List<String> get questionWords => currentQuestion.question.split(' ');

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    _stopHighlight();
    setState(() {
      isLoading = true;
      currentIndex = 0;
    });

    final given = widget.initialQuestions;
    final result = given != null
        ? QuestionResult(questions: given, isOffline: false)
        : await QuestionService.getQuestions(topic: widget.topic, count: widget.count);

    if (!mounted) return;

    setState(() {
      questions = result.questions;
      isLoading = false;
      session = PracticeSession(isQuiz: true);
      for (final q in questions) {
        session.addItem(q.question);
      }
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

  void _stopHighlight() {
    SpeechService.instance.stop();
    _highlightRun++;
    highlightedWord = -1;
    highlightedOption = -1;
    isPlaying = false;
    cancelSpeaking();
  }

  Future<bool> _playHighlight() async {
    final run = ++_highlightRun;
    bool stillHere() => mounted && run == _highlightRun;

    await speakWordByWord(
      currentQuestion.question,
      keepGoing: stillHere,
      onWord: (i) => setState(() {
        highlightedWord = i;
        highlightedOption = -1;
      }),
    );

    for (var i = 0; i < currentQuestion.options.length; i++) {
      if (!stillHere()) return false;
      setState(() {
        highlightedWord = -1;
        highlightedOption = i;
      });
      await SpeechService.instance.speak('${String.fromCharCode(65 + i)}. ${currentQuestion.options[i]}');
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
    if (isPlaying || isListening) return;
    setState(() {
      isPlaying = true;
    });

    final finished = await _playHighlight();

    if (!mounted || !finished) return;
    setState(() {
      isPlaying = false;
    });
  }

  @override
  void onSpeechChecked(SpeechCheck check) {
    final heardText = check.heard.join(' ').toLowerCase().trim();
    final correctAnswer = currentQuestion.options[currentQuestion.correctIndex].toLowerCase().trim();

    final bool isCorrect = heardText.isNotEmpty &&
        (check.score >= 60 ||
            heardText.contains(correctAnswer) ||
            correctAnswer.contains(heardText));

    session.recordAnswer(currentQuestion.question, correct: isCorrect);

    if (isCorrect) {
      _showResultDialog();
    } else {
      _showTryAgainDialog();
    }
  }

  @override
  String get speakTarget => currentQuestion.options[currentQuestion.correctIndex];

  @override
  bool get speakBlocked => isPlaying;

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
                  'That is not the right answer. Listen again and try speaking another one!',
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
    final all = questions;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          session: session,
          look: PracticeLook.intermediate,
          title: widget.topic,
          practiceAgain: (labels) => AiQuestionPage(
            topic: widget.topic,
            initialQuestions: all.where((q) => labels.contains(q.question)).toList(),
          ),
        ),
      ),
    );
  }

  void _goToNextQuestion() {
    if (!mounted) return;
    if (currentIndex + 1 < questions.length) {
      setState(() {
        currentIndex++;
      });
      _stopHighlight();
      setState(() {});
    } else {
      _finish();
    }
  }

  void _showResultDialog() {
    final bool isLastQuestion = currentIndex == questions.length - 1;

    showSuccessDialog(
      context,
      detail: '"${currentQuestion.options[currentQuestion.correctIndex]}"',
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
      dinoTip: 'Listen to my question, then hold SPEAK and say the full answer!',
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
                  'Hold SPEAK and say the answer 👇',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF6B4C7A)),
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < currentQuestion.options.length; i++) _buildOptionDisplay(i),
              const SizedBox(height: 20),
              
              // BUTANG SPEAK SAHAJA (TEKAN DAN TAHAN)
              Center(
                child: GestureDetector(
                  onTapDown: (_) => onSpeakDown(),
                  onTapUp: (_) => onSpeakUp(),
                  onTapCancel: () => onSpeakUp(),
                  child: Container(
                    width: 150,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isListening ? const Color(0xFF6BCB77) : const Color(0xFF4A90E2),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: (isListening ? const Color(0xFF6BCB77) : const Color(0xFF4A90E2)).withOpacity(0.4),
                          offset: const Offset(0, 5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isListening ? '...' : 'SPEAK',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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

  Widget _buildOptionDisplay(int i) {
    final isLit = highlightedOption == i;
    final colors = _answerColors[i % _answerColors.length];

    const Color litColor = Color(0xFFFFB300);

    final Color background = colors[0];
    final Color edge = isLit ? litColor : colors[1];
    final Color border = isLit ? litColor : Colors.white;

    return IgnorePointer(
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
                color: isLit ? litColor : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Text(
                String.fromCharCode(65 + i),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isLit ? Colors.white : _look.darkColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                currentQuestion.options[i],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: PracticeColors.ink,
                ),
              ),
            ),
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