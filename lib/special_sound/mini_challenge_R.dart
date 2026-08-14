import 'package:flutter/material.dart';
import 'package:talkiepal/main.dart';
import 'package:talkiepal/game_page.dart';
import 'package:talkiepal/profile_page.dart';

class MiniChallengeRPage extends StatefulWidget {
  const MiniChallengeRPage({super.key});

  @override
  State<MiniChallengeRPage> createState() => _MiniChallengeRPageState();
}

class _MiniChallengeRPageState extends State<MiniChallengeRPage> {
  bool _isDemoPlaying = false;
  bool _isSpeaking = false;
  int currentIndex = 0;
  int highlightedWordIndex = -1;

  final List<Map<String, dynamic>> exercises = [
    {
      'sentence': 'The red robot runs in the rain',
      'words': ['The', 'red', 'robot', 'runs', 'in', 'the', 'rain'],
      'focus': 'R',
    },
    {
      'sentence': 'Round and round the rugged rocks',
      'words': ['Round', 'and', 'round', 'the', 'rugged', 'rocks'],
      'focus': 'R',
    },
    {
      'sentence': 'Rabbits love to run on the road',
      'words': ['Rabbits', 'love', 'to', 'run', 'on', 'the', 'road'],
      'focus': 'R',
    },
  ];

  Map<String, dynamic> get currentExercise => exercises[currentIndex];

  void _listenToSentence() {
    if (_isDemoPlaying) return;

    setState(() {
      _isDemoPlaying = true;
      highlightedWordIndex = -1;
    });

    final words = currentExercise['words'] as List<String>;
    
    for (int i = 0; i < words.length; i++) {
      Future.delayed(Duration(milliseconds: i * 400), () {
        if (mounted) {
          setState(() {
            highlightedWordIndex = i;
          });
        }
      });
    }

    Future.delayed(Duration(milliseconds: words.length * 400 + 200), () {
      if (mounted) {
        setState(() {
          _isDemoPlaying = false;
          highlightedWordIndex = -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔊 Now try to say the sentence!'),
            backgroundColor: Color(0xFF6BCB77),
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }

  void _speakSentence() {
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
      _isSpeaking = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isSpeaking = false;
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
                    'Try saying: "${currentExercise['sentence']}"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
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
                      _goToNextSentence();
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

  void _goToNextSentence() {
    setState(() {
      currentIndex++;
      highlightedWordIndex = -1;
      _isDemoPlaying = false;
      _isSpeaking = false;
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
                const Text('You completed all R challenges!', style: TextStyle(fontSize: 14, color: Colors.white)),
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
    final words = currentExercise['words'] as List<String>;

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
                                'MINI CHALLENGE - SOUND R',
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

                      // Sentence Card with Highlight
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(25),
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
                              'SAY THIS SENTENCE',
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 2,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Highlighted Words
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(words.length, (index) {
                                bool isHighlighted = highlightedWordIndex == index;
                                return Container(
                                  decoration: BoxDecoration(
                                    color: isHighlighted ? Colors.white : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(
                                    words[index],
                                    style: TextStyle(
                                      fontSize: 22,
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

                      // LISTEN Button
                      Center(
                        child: GestureDetector(
                          onTap: _isDemoPlaying ? null : _listenToSentence,
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
                                  Icons.headphones,
                                  size: 24,
                                  color: _isDemoPlaying ? Colors.white60 : Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isDemoPlaying ? 'LISTENING...' : 'LISTEN',
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

                      // OR divider
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

                      // SPEAK Button
                      Center(
                        child: GestureDetector(
                          onTap: _isSpeaking ? null : _speakSentence,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                            decoration: BoxDecoration(
                              gradient: _isSpeaking
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
                                  _isSpeaking ? Icons.mic_off : Icons.mic,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isSpeaking ? 'WAIT...' : 'SPEAK',
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
                              '💡 Focus on the "R" sound - Roll your tongue!',
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