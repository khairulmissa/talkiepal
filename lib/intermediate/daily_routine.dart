import 'package:flutter/material.dart';
import 'package:talkiepal/main.dart';
import 'package:talkiepal/game_page.dart';
import 'package:talkiepal/profile_page.dart';

class PracticeDailyRoutinePage extends StatefulWidget {
  const PracticeDailyRoutinePage({super.key});

  @override
  State<PracticeDailyRoutinePage> createState() => _PracticeDailyRoutinePageState();
}

class _PracticeDailyRoutinePageState extends State<PracticeDailyRoutinePage> {
  bool _isListening = false;
  int currentIndex = 0;
  int highlightedWordIndex = -1;
  int highlightedOptionIndex = -1;
  String _userAnswer = '';
  bool _isDemoPlaying = false;

  // List of 5 questions with options and correct answer
  final List<Map<String, dynamic>> exercises = [
    {
      'question': 'What time do you wake up?',
      'questionWords': ['What', 'time', 'do', 'you', 'wake', 'up?'],
      'options': ['I wake up at 6 AM.', 'I eat breakfast.', 'I go to bed.'],
      'correctAnswer': 'I wake up at 6 AM.',
      'correctIndex': 0,
    },
    {
      'question': 'What do you eat for breakfast?',
      'questionWords': ['What', 'do', 'you', 'eat', 'for', 'breakfast?'],
      'options': ['I eat bread and milk.', 'I sleep early.', 'I play football.'],
      'correctAnswer': 'I eat bread and milk.',
      'correctIndex': 0,
    },
    {
      'question': 'How do you go to school?',
      'questionWords': ['How', 'do', 'you', 'go', 'to', 'school?'],
      'options': ['I go by bus.', 'I eat lunch.', 'I do homework.'],
      'correctAnswer': 'I go by bus.',
      'correctIndex': 0,
    },
    {
      'question': 'What do you do after school?',
      'questionWords': ['What', 'do', 'you', 'do', 'after', 'school?'],
      'options': ['I do my homework.', 'I wake up.', 'I have dinner.'],
      'correctAnswer': 'I do my homework.',
      'correctIndex': 0,
    },
    {
      'question': 'What time do you sleep?',
      'questionWords': ['What', 'time', 'do', 'you', 'sleep?'],
      'options': ['I sleep at 9 PM.', 'I go to school.', 'I eat breakfast.'],
      'correctAnswer': 'I sleep at 9 PM.',
      'correctIndex': 0,
    },
  ];

  Map<String, dynamic> get currentExercise => exercises[currentIndex];

  void _playDemo() {
    setState(() {
      _isDemoPlaying = true;
      highlightedWordIndex = -1;
      highlightedOptionIndex = -1;
    });

    final questionWords = currentExercise['questionWords'] as List<String>;
    final options = currentExercise['options'] as List<String>;
    
    for (int i = 0; i < questionWords.length; i++) {
      Future.delayed(Duration(milliseconds: i * 400), () {
        if (mounted) {
          setState(() {
            highlightedWordIndex = i;
            highlightedOptionIndex = -1;
          });
        }
      });
    }

    for (int i = 0; i < options.length; i++) {
      Future.delayed(Duration(milliseconds: (questionWords.length + i) * 400), () {
        if (mounted) {
          setState(() {
            highlightedWordIndex = -1;
            highlightedOptionIndex = i;
          });
        }
      });
    }

    Future.delayed(Duration(milliseconds: (questionWords.length + options.length) * 400 + 500), () {
      if (mounted) {
        setState(() {
          _isDemoPlaying = false;
          highlightedWordIndex = -1;
          highlightedOptionIndex = -1;
        });
      }
    });
  }

  void _speakAnswer() {
    if (_isDemoPlaying) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for the demo to finish...'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() {
      _isListening = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isListening = false;
      });
      
      bool isRandomCorrect = DateTime.now().millisecondsSinceEpoch % 10 < 7;
      
      if (isRandomCorrect) {
        _userAnswer = currentExercise['correctAnswer'];
        _showResultDialog(true);
      } else {
        List<String> options = List<String>.from(currentExercise['options']);
        int wrongIndex = (currentExercise['correctIndex'] + 1) % options.length;
        _userAnswer = options[wrongIndex];
        _showResultDialog(false);
      }
    });
  }

  void _showResultDialog(bool isCorrectAnswer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: isCorrectAnswer
                  ? const LinearGradient(colors: [Color(0xFFA8D5A2), Color(0xFF6BCB77)])
                  : const LinearGradient(colors: [Color(0xFFFFB6B6), Color(0xFFFF6B6B)]),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCorrectAnswer) ...[
                  const Text('🎉 CORRECT! 🎉', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 15),
                  Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) => const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.star, size: 40, color: Colors.amber)))),
                  const SizedBox(height: 20),
                  const Text('Great job! Keep it up! 🌟', style: TextStyle(fontSize: 16, color: Colors.white)),
                ] else ...[
                  const Text('❌ OOPS! ❌', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 15),
                  const Icon(Icons.sentiment_very_dissatisfied, size: 60, color: Colors.white),
                  const SizedBox(height: 15),
                  Text('You said: "$_userAnswer"', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.white)),
                  const SizedBox(height: 10),
                  Text('Try saying: "${currentExercise['correctAnswer']}"', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (isCorrectAnswer && currentIndex + 1 < exercises.length) {
                      _goToNextQuestion();
                    } else if (isCorrectAnswer && currentIndex + 1 == exercises.length) {
                      _showCompletionDialog();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: isCorrectAnswer ? const Color(0xFF6BCB77) : const Color(0xFFFF6B6B),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _goToNextQuestion() {
    setState(() {
      currentIndex++;
      _userAnswer = '';
      highlightedWordIndex = -1;
      highlightedOptionIndex = -1;
      _isDemoPlaying = false;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]), borderRadius: BorderRadius.circular(25)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 50)),
                const SizedBox(height: 10),
                const Text('CONGRATULATIONS!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                const Text('You completed all questions!', style: TextStyle(fontSize: 14, color: Colors.white)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: const Text('Back to Menu', style: TextStyle(color: Colors.orange)),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final questionWords = currentExercise['questionWords'] as List<String>;
    final options = currentExercise['options'] as List<String>;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fullbg_beginnerpractice.png'),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Color(0xFFE8D5F0), shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_back, size: 24, color: Color(0xFF8B5E9E)),
                            ),
                          ),
                          Column(
                            children: [
                              const Text('DAILY ROUTINE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF6B4C7A))),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFE8D5F0), borderRadius: BorderRadius.circular(20)),
                                child: Text('${currentIndex + 1} of ${exercises.length}', style: const TextStyle(fontSize: 10, color: Color(0xFF8B5E9E))),
                              ),
                            ],
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFC9B3E0), Color(0xFF9C27B0)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          children: [
                            const Text('QUESTION', style: TextStyle(fontSize: 12, letterSpacing: 2, color: Colors.white70)),
                            const SizedBox(height: 10),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              children: List.generate(questionWords.length, (index) {
                                bool isHighlighted = highlightedWordIndex == index;
                                return Container(
                                  decoration: BoxDecoration(
                                    color: isHighlighted ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(
                                    questionWords[index],
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isHighlighted ? const Color(0xFF9C27B0) : Colors.white,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: _isDemoPlaying ? null : _playDemo,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: _isDemoPlaying ? Colors.grey : const Color(0xFFC9B3E0),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_arrow, size: 20, color: _isDemoPlaying ? Colors.white60 : Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  _isDemoPlaying ? 'PLAYING...' : '🔊 LISTEN TO QUESTION & ANSWERS',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _isDemoPlaying ? Colors.white60 : Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Text('POSSIBLE ANSWERS (Say one of these):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF6B4C7A))),
                      const SizedBox(height: 15),
                      for (int i = 0; i < options.length; i++)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: highlightedOptionIndex == i ? const Color(0xFFFFB347).withOpacity(0.3) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: highlightedOptionIndex == i ? const Color(0xFFFFB347) : Colors.grey.shade300, width: highlightedOptionIndex == i ? 2 : 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 35, height: 35,
                                decoration: BoxDecoration(
                                  color: highlightedOptionIndex == i ? const Color(0xFFFFB347) : const Color(0xFFE8D5F0),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + i),
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: highlightedOptionIndex == i ? Colors.white : const Color(0xFF8B5E9E)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  options[i],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: highlightedOptionIndex == i ? FontWeight.bold : FontWeight.normal,
                                    color: highlightedOptionIndex == i ? const Color(0xFFE67E22) : const Color(0xFF5D3A6B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: _isListening ? null : _speakAnswer,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                            decoration: BoxDecoration(
                              gradient: _isListening ? const LinearGradient(colors: [Colors.grey, Colors.grey]) : const LinearGradient(colors: [Color(0xFFA8D5A2), Color(0xFF6BCB77)]),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.white, size: 30),
                                const SizedBox(width: 12),
                                Text(_isListening ? 'WAIT...' : 'SPEAK YOUR ANSWER', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_userAnswer.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                            child: Column(
                              children: [
                                const Text('YOU SAID:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 5),
                                Text(_userAnswer, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF6BCB77))),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFE8F4FD), borderRadius: BorderRadius.circular(15)),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lightbulb, size: 20, color: Color(0xFF9C27B0)),
                            SizedBox(width: 8),
                            Text('💡 Click SPEAK and say your answer!', style: TextStyle(fontSize: 12, color: Color(0xFF6B4C7A))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavItem(Icons.home, 'Home', context),
                      _buildNavItem(Icons.gamepad, 'Game', context),
                      _buildNavItem(Icons.bar_chart, 'Progress', context),
                      _buildNavItem(Icons.person, 'Profile', context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (label == 'Home') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
        } else if (label == 'Game') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GamePage()));
        } else if (label == 'Progress') {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress page coming soon!')));
        } else if (label == 'Profile') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}