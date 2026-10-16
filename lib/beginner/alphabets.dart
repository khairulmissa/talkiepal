import 'package:flutter/material.dart';
import 'package:talkiepal/main.dart';
import 'package:talkiepal/game_page.dart';
import 'package:talkiepal/profile_page.dart';
import 'package:talkiepal/practice/widgets/success_dialog.dart';
import 'package:talkiepal/widgets/kids_bottom_nav.dart';

class PracticeAlphabetsPage extends StatefulWidget {
  const PracticeAlphabetsPage({super.key});

  @override
  State<PracticeAlphabetsPage> createState() => _PracticeAlphabetsPageState();
}

class _PracticeAlphabetsPageState extends State<PracticeAlphabetsPage> {
  bool isListening = false;
  int currentIndex = 0;

  // List of 26 exercises (A to Z)
  final List<Map<String, String>> exercises = [
    {'letter': 'A', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/A.png'},
    {'letter': 'B', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/B.png'},
    {'letter': 'C', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/C.png'},
    {'letter': 'D', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/D.png'},
    {'letter': 'E', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/E.png'},
    {'letter': 'F', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/F.png'},
    {'letter': 'G', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/G.png'},
    {'letter': 'H', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/H.png'},
    {'letter': 'I', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/I.png'},
    {'letter': 'J', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/J.png'},
    {'letter': 'K', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/K.png'},
    {'letter': 'L', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/L.png'},
    {'letter': 'M', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/M.png'},
    {'letter': 'N', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/N.png'},
    {'letter': 'O', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/O.png'},
    {'letter': 'P', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/P.png'},
    {'letter': 'Q', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/Q.png'},
    {'letter': 'R', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/R.png'},
    {'letter': 'S', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/S.png'},
    {'letter': 'T', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/T.png'},
    {'letter': 'U', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/U.png'},
    {'letter': 'V', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/V.png'},
    {'letter': 'W', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/W.png'},
    {'letter': 'X', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/X.png'},
    {'letter': 'Y', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/Y.png'},
    {'letter': 'Z', 'focus': 'Alphabets', 'image': 'lib/assets/images/alphabets/Z.png'},
  ];

  // Get current exercise
  Map<String, String> get currentExercise => exercises[currentIndex];

  void _goToNextExercise() {
    if (currentIndex + 1 < exercises.length) {
      setState(() {
        currentIndex++;
        isListening = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Congratulations! You completed all alphabets! 🎉'),
          backgroundColor: Color(0xFFA8D5A2),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showResultDialog(BuildContext context, {required bool isSuccess}) {
    bool isLastExercise = currentIndex == exercises.length - 1;

    showSuccessDialog(
      context,
      detail: 'You said "${currentExercise['letter']}"!',
      nextLabel: isLastExercise ? 'FINISH →' : 'NEXT LETTER →',
      onNext: _goToNextExercise,
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
                                'ALPHABETS (A-Z)',
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
                                  'Exercise ${currentIndex + 1} of ${exercises.length}',
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

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFA8D5A2), Color(0xFF8BC48A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'HELLO, KHAIRUL! 👋',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Let's learn alphabets A to Z today!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  '🔤',
                                  style: TextStyle(fontSize: 24),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Level: Beginner',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5D3A6B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.grey.shade300,
                            ),
                            Column(
                              children: [
                                const Text(
                                  '📖',
                                  style: TextStyle(fontSize: 24),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentExercise['focus']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF5D3A6B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0E0),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFFFFCC99),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Color(0xFFFFB347)),
                                SizedBox(width: 8),
                                Text(
                                  'Daily Challenge',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8B6914),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Center(
                              child: Column(
                                children: [
                                  Image.asset(
                                    currentExercise['image']!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8D5F0),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          currentExercise['letter']!,
                                          style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF8B5E9E),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'LETTER',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF8B6914),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    currentExercise['letter']!,
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6B4C7A),
                                      letterSpacing: 3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(
                                  icon: Icons.headphones,
                                  label: 'LISTEN',
                                  color: const Color(0xFFA8D5A2),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('🔊 Playing pronunciation: Letter ${currentExercise['letter']}'),
                                        backgroundColor: Color(0xFFA8D5A2),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                                _buildActionButton(
                                  icon: Icons.mic,
                                  label: 'SPEAK',
                                  color: const Color(0xFFC9B3E0),
                                  onTap: () {
                                    setState(() {
                                      isListening = true;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('🎤 Listening to your pronunciation...'),
                                        backgroundColor: Color(0xFFC9B3E0),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    Future.delayed(const Duration(seconds: 2), () {
                                      if (!context.mounted) return;
                                      setState(() {
                                        isListening = false;
                                      });
                                      _showResultDialog(context, isSuccess: true);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),

              KidsBottomNav(selected: null, onTap: _onNavTap),
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
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
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

  void _onNavTap(KidsTab tab) {
    switch (tab) {
      case KidsTab.home:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case KidsTab.game:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GamePage()),
        );
        break;
      case KidsTab.progress:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress page coming soon!'),
            duration: Duration(seconds: 1),
          ),
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