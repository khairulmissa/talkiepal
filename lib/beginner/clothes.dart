import 'package:flutter/material.dart';
import 'package:talkiepal/main.dart';
import 'package:talkiepal/game_page.dart';
import 'package:talkiepal/profile_page.dart';

class PracticeClothesPage extends StatefulWidget {
  const PracticeClothesPage({super.key});

  @override
  State<PracticeClothesPage> createState() => _PracticeClothesPageState();
}

class _PracticeClothesPageState extends State<PracticeClothesPage> {
  bool isListening = false;
  int currentIndex = 0;

  // List of 10 exercises (10 Clothes)
  final List<Map<String, String>> exercises = [
    {'clothe': 'Shirt', 'word': 'SHIRT', 'focus': 'Clothes', 'image': 'lib/assets/images/clothes/shirt.png'},
    {'clothe': 'Pants', 'word': 'PANTS', 'focus': 'Clothes', 'image': 'lib/assets/images/clothes/pants.png'},
    {'clothe': 'Dress', 'word': 'DRESS', 'focus': 'Clothes', 'image': 'lib/assets/images/clothes/dress.png'},
    {'clothe': 'Skirt', 'word': 'SKIRT', 'focus': 'Clothes', 'image': 'lib/assets/images/clothes/skirt.png'},
    {'clothe': 'Jacket', 'word': 'JACKET', 'focus': 'Clothes', 'image': 'lib/assets/images/clothes/jacket.png'},
    {'clothe': 'Shoes', 'word': 'SHOES', 'focus': 'Clothes', 'image': 'lib/assets/images/clothes/shoes.png'},
    {'clothe': 'Hat', 'word': 'HAT', 'focus': 'Clothes', 'image': 'lib/assets/images/clothes/hat.png'},
    {'clothe': 'Socks', 'word': 'SOCKS', 'focus': 'Clothes', 'image': 'lib/assets/images/clothes/socks.png'},
    {'clothe': 'Gloves', 'word': 'GLOVES', 'focus': 'Clothes', 'image': 'lib/assets/images/clothes/gloves.png'},
    {'clothe': 'Scarf', 'word': 'SCARF', 'focus': 'Clothes', 'image': 'lib/assets/images/clothes/scarf.png'},
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
          content: Text('🎉 Congratulations! You completed all clothes! 🎉'),
          backgroundColor: Color(0xFFA8D5A2),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showResultDialog(BuildContext context, {required bool isSuccess}) {
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
                colors: [Color(0xFFA8D5A2), Color(0xFF8BC48A)],
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
                                color: Color(0xFF6BCB77),
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
                                content: Text('🎉 Congratulations! You completed all clothes! 🎉'),
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
                              isLastExercise ? 'FINISH →' : 'NEXT CLOTHES →',
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
                                'CLOTHES',
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
                              "Let's learn clothes today!",
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
                                  '👕',
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
                                  '👕',
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
                                          currentExercise['clothe']![0],
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
                                  Text(
                                    currentExercise['word']!,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6B4C7A),
                                      letterSpacing: 2,
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
                                        content: Text('🔊 Playing pronunciation: ${currentExercise['word']}'),
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
                      _buildNavItem(Icons.home, 'Home', false, context),
                      _buildNavItem(Icons.gamepad, 'Game', false, context),
                      _buildNavItem(Icons.bar_chart, 'Progress', false, context),
                      _buildNavItem(Icons.person, 'Profile', false, context),
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

  Widget _buildNavItem(IconData icon, String label, bool isSelected, BuildContext context) {
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
            color: isSelected ? const Color(0xFFB47CC4) : Colors.grey.shade400,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? const Color(0xFFB47CC4) : Colors.grey.shade400,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}