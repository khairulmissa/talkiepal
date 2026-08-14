import 'package:flutter/material.dart';
import 'package:talkiepal/beginner/alphabets.dart';
import 'package:talkiepal/beginner/numbers_page.dart';
import 'package:talkiepal/beginner/colors.dart';
import 'package:talkiepal/beginner/shapes.dart';
import 'package:talkiepal/beginner/animals.dart';
import 'package:talkiepal/beginner/fruits.dart';
import 'package:talkiepal/beginner/bodyparts.dart';
import 'package:talkiepal/beginner/clothes.dart';
import 'package:talkiepal/beginner/vehicles.dart';

class BeginnerPage extends StatefulWidget {
  const BeginnerPage({super.key});

  @override
  State<BeginnerPage> createState() => _BeginnerPageState();
}

class _BeginnerPageState extends State<BeginnerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/images/fullbg_level.png'),
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
                          const Text(
                            'BEGINNER LEVEL',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B4C7A),
                            ),
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
                              'WELCOME, LITTLE STAR! ✨',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Let's have fun\nlearning to speak",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Easy & Super Fun! 🎈',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        'What will you learn today?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4C7A),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // SUBTOPICS
                      _buildLearningItem('Alphabets (A-Z)', Icons.abc),
                      const SizedBox(height: 10),
                      _buildLearningItem('Numbers (1-10)', Icons.looks_one),
                      const SizedBox(height: 10),
                      _buildLearningItem('Colors', Icons.palette),
                      const SizedBox(height: 10),
                      _buildLearningItem('Shapes', Icons.crop_square),
                      const SizedBox(height: 10),
                      _buildLearningItem('Animals', Icons.pets),
                      const SizedBox(height: 10),
                      _buildLearningItem('Fruits', Icons.apple),
                      const SizedBox(height: 10),
                      _buildLearningItem('Body Parts', Icons.accessibility_new),
                      const SizedBox(height: 10),
                      _buildLearningItem('Clothes', Icons.checkroom),
                      const SizedBox(height: 10),
                      _buildLearningItem('Vehicles', Icons.directions_car),

                      const SizedBox(height: 25),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0E0),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFCC99),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lightbulb, color: Color(0xFFFFB347), size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'TIP FOR YOU',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Listen ',
                                  style: TextStyle(fontSize: 13, color: Colors.black),
                                ),
                                Icon(Icons.headphones, size: 16, color: Colors.black),
                                Text(
                                  ', then repeat ',
                                  style: TextStyle(fontSize: 13, color: Colors.black),
                                ),
                                Icon(Icons.music_note, size: 16, color: Colors.black),
                              ],
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "It's okay to make mistakes!",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.black),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFCC99),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'You are doing GREAT',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Text('👍', style: TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      Center(
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Starting practice session...'),
                                backgroundColor: Color(0xFFA8D5A2),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5E9E), Color(0xFFB47CC4)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              'START PRACTICE NOW',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
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

  Widget _buildLearningItem(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        // CONDITION FOR ALPHABETS
        if (title == 'Alphabets (A-Z)') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PracticeAlphabetsPage()),
          );
        } 
        // CONDITION FOR NUMBERS (1-10)
        else if (title == 'Numbers (1-10)') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PracticeNumbers1To10Page()),
          );
        }
        // CONDITION FOR COLORS
        else if (title == 'Colors') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PracticeColorsPage()),
          );
        }
        // CONDITION FOR SHAPES
        else if (title == 'Shapes') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PracticeShapesPage()),
          );
        }
        // CONDITION FOR ANIMALS
        else if (title == 'Animals') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PracticeAnimalsNewPage()),
          );
        }
        // CONDITION FOR FRUITS
        else if (title == 'Fruits') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PracticeFruitsPage()),
          );
        }
        // CONDITION FOR BODY PARTS
        else if (title == 'Body Parts') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PracticeBodyPartsPage()),
          );
        }
        // CONDITION FOR CLOTHES
        else if (title == 'Clothes') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PracticeClothesPage()),
          );
        }
        // CONDITION FOR VEHICLES
        else if (title == 'Vehicles') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PracticeVehiclesPage()),
          );
        }
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening $title...'),
              backgroundColor: const Color(0xFFA8D5A2),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFFE8D5F0),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, size: 24, color: const Color(0xFF8B5E9E)),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5D3A6B),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Color(0xFFC9B3E0),
            ),
          ],
        ),
      ),
    );
  }
}