import 'package:flutter/material.dart';
import 'package:talkiepal/main.dart';
import 'package:talkiepal/game_page.dart';
import 'package:talkiepal/profile_page.dart';

class PracticeMorningRoutinePage extends StatefulWidget {
  const PracticeMorningRoutinePage({super.key});

  @override
  State<PracticeMorningRoutinePage> createState() => _PracticeMorningRoutinePageState();
}

class _PracticeMorningRoutinePageState extends State<PracticeMorningRoutinePage> {
  bool isListening = false;
  int currentIndex = 0;
  int highlightedWordIndex = -1;

  // List of 3 exercises
  final List<Map<String, dynamic>> exercises = [
    {
      'sentence': 'I wake up',
      'words': ['I', 'wake', 'up'],
      'image': 'lib/assets/images/morning_routine/wake_up.png',
    },
    {
      'sentence': 'I brush my teeth',
      'words': ['I', 'brush', 'my', 'teeth'],
      'image': 'lib/assets/images/morning_routine/brush_teeth.png',
    },
    {
      'sentence': 'I eat breakfast',
      'words': ['I', 'eat', 'breakfast'],
      'image': 'lib/assets/images/morning_routine/eat_breakfast.png',
    },
  ];

  Map<String, dynamic> get currentExercise => exercises[currentIndex];

  void _playListenWithHighlight() {
    setState(() {
      isListening = true;
      highlightedWordIndex = -1;
    });

    final words = currentExercise['words'] as List<String>;
    
    for (int i = 0; i < words.length; i++) {
      Future.delayed(Duration(milliseconds: i * 500), () {
        if (mounted) {
          setState(() {
            highlightedWordIndex = i;
          });
          // Play sound effect for each word (simulate pronunciation)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🔊 ${words[i]}'),
              backgroundColor: Color(0xFFA8D5A2),
              duration: Duration(milliseconds: 400),
            ),
          );
        }
      });
    }

    Future.delayed(Duration(milliseconds: words.length * 500), () {
      if (mounted) {
        setState(() {
          isListening = false;
          highlightedWordIndex = -1;
        });
      }
    });
  }

  void _goToNextExercise() {
    if (currentIndex + 1 < exercises.length) {
      setState(() {
        currentIndex++;
        highlightedWordIndex = -1;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Congratulations! You completed morning routine! 🎉'),
          backgroundColor: Color(0xFFA8D5A2),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showResultDialog(BuildContext context) {
    bool isLastExercise = currentIndex == exercises.length - 1;

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
              gradient: const LinearGradient(
                colors: [Color(0xFFFFCC99), Color(0xFFFFB347)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PERFECT!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                    (index) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.star,
                        size: 35,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '🌟 You did great! 🌟',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Center(
                            child: Text(
                              'TRY AGAIN',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE67E22),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          if (isLastExercise) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🎉 Congratulations! You completed morning routine! 🎉'),
                                backgroundColor: Color(0xFFA8D5A2),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            Navigator.pop(context);
                          } else {
                            _goToNextExercise();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                            child: Text(
                              isLastExercise ? 'FINISH →' : 'NEXT →',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B5E9E),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8D5F0),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                size: 24,
                                color: Color(0xFF8B5E9E),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              const Text(
                                'MY MORNING ROUTINE',
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
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF8B5E9E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Welcome Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFCC99), Color(0xFFFFB347)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '🌅 GOOD MORNING! 🌅',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "Let's learn what you do in the morning!",
                              style: TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Sentence Card with Highlight
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Image
                            Image.asset(
                              currentExercise['image']!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE0B3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.brightness_5,
                                    size: 50,
                                    color: const Color(0xFFFFB347),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            // Highlighted Sentence
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              children: List.generate(words.length, (index) {
                                bool isHighlighted = highlightedWordIndex == index;
                                return Container(
                                  decoration: BoxDecoration(
                                    color: isHighlighted ? const Color(0xFFFFB347) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(
                                    words[index],
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: isHighlighted ? Colors.white : const Color(0xFF5D3A6B),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.headphones,
                            label: 'LISTEN',
                            color: const Color(0xFFA8D5A2),
                            onTap: _playListenWithHighlight,
                          ),
                          _buildActionButton(
                            icon: Icons.mic,
                            label: 'SPEAK',
                            color: const Color(0xFFC9B3E0),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🎤 Listening to your pronunciation...'),
                                  backgroundColor: Color(0xFFC9B3E0),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              Future.delayed(const Duration(seconds: 2), () {
                                _showResultDialog(context);
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Tip
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0E0),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lightbulb, size: 20, color: Color(0xFFFFB347)),
                            SizedBox(width: 8),
                            Text(
                              '💡 Listen and repeat each word!',
                              style: TextStyle(fontSize: 12, color: Colors.black54),
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (label == 'Home') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else if (label == 'Game') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const GamePage()),
          );
        } else if (label == 'Progress') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Progress page coming soon!'),
              duration: Duration(seconds: 1),
            ),
          );
        } else if (label == 'Profile') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.grey.shade400,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}