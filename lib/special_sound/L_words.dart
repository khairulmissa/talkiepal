import 'package:flutter/material.dart';
import 'package:talkiepal/main.dart';
import 'package:talkiepal/game_page.dart';
import 'package:talkiepal/profile_page.dart';

class PracticeWordsLPage extends StatefulWidget {
  const PracticeWordsLPage({super.key});

  @override
  State<PracticeWordsLPage> createState() => _PracticeWordsLPageState();
}

class _PracticeWordsLPageState extends State<PracticeWordsLPage> {
  bool _isListening = false;
  bool _isDemoPlaying = false;
  int currentIndex = 0;
  int highlightedLetterIndex = -1;

  final List<Map<String, dynamic>> exercises = [
    {
      'word': 'LION',
      'letters': ['L', 'I', 'O', 'N'],
    },
    {
      'word': 'LEG',
      'letters': ['L', 'E', 'G'],
    },
    {
      'word': 'LEAF',
      'letters': ['L', 'E', 'A', 'F'],
    },
    {
      'word': 'LOVE',
      'letters': ['L', 'O', 'V', 'E'],
    },
  ];

  Map<String, dynamic> get currentExercise => exercises[currentIndex];

  void _playDemo() {
    setState(() {
      _isDemoPlaying = true;
      highlightedLetterIndex = -1;
    });

    final letters = currentExercise['letters'] as List<String>;
    
    for (int i = 0; i < letters.length; i++) {
      Future.delayed(Duration(milliseconds: i * 500), () {
        if (mounted) {
          setState(() {
            highlightedLetterIndex = i;
          });
        }
      });
    }

    Future.delayed(Duration(milliseconds: letters.length * 500 + 200), () {
      if (mounted) {
        setState(() {
          _isDemoPlaying = false;
          highlightedLetterIndex = -1;
        });
      }
    });
  }

  void _speakAnswer() {
    if (_isDemoPlaying) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for the pronunciation to finish...'),
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
        _showResultDialog(true);
      } else {
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
                    'Try saying: "${currentExercise['word']}"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Listen again and repeat!',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (isCorrectAnswer && currentIndex + 1 < exercises.length) {
                      _goToNextWord();
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
                  child: Text(
                    isCorrectAnswer ? 'CONTINUE' : 'TRY AGAIN',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _goToNextWord() {
    setState(() {
      currentIndex++;
      highlightedLetterIndex = -1;
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
                const Text('You completed all L words!', style: TextStyle(fontSize: 14, color: Colors.white)),
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
    final letters = currentExercise['letters'] as List<String>;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/images/bg_wordpractices.png'),
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
                                'SOUND L - WORDS',
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

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(35),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFC9B3E0), Color(0xFF9C27B0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
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
                              'SAY THE WORD',
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 2,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(letters.length, (index) {
                                bool isHighlighted = highlightedLetterIndex == index;
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: isHighlighted ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Text(
                                    letters[index],
                                    style: TextStyle(
                                      fontSize: 48,
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

                      const SizedBox(height: 25),

                      Center(
                        child: GestureDetector(
                          onTap: _isDemoPlaying ? null : _playDemo,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            decoration: BoxDecoration(
                              color: _isDemoPlaying ? Colors.grey : const Color(0xFFC9B3E0),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  size: 24,
                                  color: _isDemoPlaying ? Colors.white60 : Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isDemoPlaying ? 'PLAYING...' : '🔊 LISTEN TO THE WORD',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _isDemoPlaying ? Colors.white60 : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('OR', style: TextStyle(color: Colors.grey)),
                          ),
                          Expanded(child: Divider(color: Colors.grey)),
                        ],
                      ),

                      const SizedBox(height: 20),

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
                                  _isListening ? 'WAIT...' : 'SPEAK THE WORD',
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
                            Text(
                              '💡 Listen first, then say the word clearly!',
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