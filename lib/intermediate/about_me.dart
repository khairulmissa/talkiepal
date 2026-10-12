import 'package:flutter/material.dart';
import 'package:talkiepal/main.dart';
import 'package:talkiepal/game_page.dart';
import 'package:talkiepal/profile_page.dart';

class PracticeAboutMePage extends StatefulWidget {
  const PracticeAboutMePage({super.key});

  @override
  State<PracticeAboutMePage> createState() => _PracticeAboutMePageState();
}

class _PracticeAboutMePageState extends State<PracticeAboutMePage> {
  bool _isListening = false;
  int currentIndex = 0;
  int highlightedWordIndex = -1;
  int highlightedOptionIndex = -1;
  String _userAnswer = '';
  bool _isDemoPlaying = false;

  // List of 5 questions with options and correct answer
  final List<Map<String, dynamic>> exercises = [
    {
      'question': 'What is your name?',
      'questionWords': ['What', 'is', 'your', 'name?'],
      'options': ['My name is Ahmad.', 'I am 9 years old.', 'I like blue.'],
      'correctAnswer': 'My name is Ahmad.',
      'correctIndex': 0,
    },
    {
      'question': 'How old are you?',
      'questionWords': ['How', 'old', 'are', 'you?'],
      'options': ['I am 8 years old.', 'I am fine.', 'My name is Ali.'],
      'correctAnswer': 'I am 8 years old.',
      'correctIndex': 0,
    },
    {
      'question': 'Where do you live?',
      'questionWords': ['Where', 'do', 'you', 'live?'],
      'options': ['I live in Kuala Lumpur.', 'I go to school.', 'I eat rice.'],
      'correctAnswer': 'I live in Kuala Lumpur.',
      'correctIndex': 0,
    },
    {
      'question': 'What is your favorite color?',
      'questionWords': ['What', 'is', 'your', 'favorite', 'color?'],
      'options': ['My favorite color is red.', 'I am happy.', 'I have a cat.'],
      'correctAnswer': 'My favorite color is red.',
      'correctIndex': 0,
    },
    {
      'question': 'When is your birthday?',
      'questionWords': ['When', 'is', 'your', 'birthday?'],
      'options': ['My birthday is in May.', 'I am 10 years old.', 'I like cake.'],
      'correctAnswer': 'My birthday is in May.',
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
    
    // Highlight question words one by one
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

    // After question, highlight each option one by one
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

    // After all highlights, stop demo mode
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

    // Wait 2 seconds then show popup
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isListening = false;
      });
      
      // For demo: randomly pick correct or wrong (70% correct, 30% wrong)
      bool isRandomCorrect = DateTime.now().millisecondsSinceEpoch % 10 < 7;
      
      if (isRandomCorrect) {
        _userAnswer = currentExercise['correctAnswer'];
        _showResultDialog(true);
      } else {
        // Pick wrong answer randomly from options
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: isCorrectAnswer
                  ? const LinearGradient(
                      colors: [Color(0xFFA8D5A2), Color(0xFF6BCB77)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFFFB6B6), Color(0xFFFF6B6B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCorrectAnswer) ...[
                  const Text(
                    '🎉 CORRECT! 🎉',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.star,
                          size: 40,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Great job! Keep it up! 🌟',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ] else ...[
                  const Text(
                    '❌ OOPS! ❌',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Icon(
                    Icons.sentiment_very_dissatisfied,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'You said: "$_userAnswer"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Try saying: "${currentExercise['correctAnswer']}"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
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
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
              borderRadius: BorderRadius.circular(25),
            ),
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

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8D5F0),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back, size: 24, color: Color(0xFF8B5E9E)),
                            ),
                          ),
                          Column(
                            children: [
                              const Text(
                                'ABOUT ME',
                                style: TextStyle(
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
                                  '${currentIndex + 1} of ${exercises.length}',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF8B5E9E)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Question Card with Highlight
                      Container(
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
                              color: Colors.purple.withOpacity(0.15),
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
                            // Highlighted Question Words
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

                      // Play Demo Button
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
                                Icon(
                                  Icons.play_arrow,
                                  size: 20,
                                  color: _isDemoPlaying ? Colors.white60 : Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isDemoPlaying ? 'PLAYING...' : '🔊 LISTEN TO QUESTION & ANSWERS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _isDemoPlaying ? Colors.white60 : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Possible Answers Title
                      const Text(
                        'POSSIBLE ANSWERS (Say one of these):',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4C7A),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Answer Options with Highlight
                      for (int i = 0; i < options.length; i++)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: highlightedOptionIndex == i 
                                ? const Color(0xFFFFB347).withOpacity(0.3)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: highlightedOptionIndex == i 
                                  ? const Color(0xFFFFB347)
                                  : Colors.grey.shade300,
                              width: highlightedOptionIndex == i ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: highlightedOptionIndex == i 
                                      ? const Color(0xFFFFB347)
                                      : const Color(0xFFE8D5F0),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + i),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: highlightedOptionIndex == i 
                                          ? Colors.white
                                          : const Color(0xFF8B5E9E),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  options[i],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: highlightedOptionIndex == i 
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: highlightedOptionIndex == i 
                                        ? const Color(0xFFE67E22)
                                        : const Color(0xFF5D3A6B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Speak Button
                      Center(
                        child: GestureDetector(
                          onTap: _isListening ? null : _speakAnswer,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                            decoration: BoxDecoration(
                              gradient: _isListening
                                  ? const LinearGradient(
                                      colors: [Colors.grey, Colors.grey],
                                    )
                                  : const LinearGradient(
                                      colors: [Color(0xFFA8D5A2), Color(0xFF6BCB77)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isListening ? Icons.mic_off : Icons.mic,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isListening ? 'WAIT...' : 'SPEAK YOUR ANSWER',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
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
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'YOU SAID:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _userAnswer,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6BCB77),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Tip Card
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
                            Text(
                              '💡 Click SPEAK and say your answer!',
                              style: TextStyle(fontSize: 12, color: Color(0xFF6B4C7A)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),

              // Bottom Navigation
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                    ),
                  ],
                ),
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