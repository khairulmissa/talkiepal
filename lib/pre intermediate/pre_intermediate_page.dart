import 'package:flutter/material.dart';
import 'morning_routine.dart';
import 'my_feelings.dart';
import 'things_i_like.dart';
import 'school_classroom.dart';
import 'hobbies.dart';  
import 'daily_routine.dart';
import 'home_room.dart';  
import 'shopping_toys.dart';  

class PreIntermediatePage extends StatefulWidget {
  const PreIntermediatePage({super.key});

  @override
  State<PreIntermediatePage> createState() => _PreIntermediatePageState();
}

class _PreIntermediatePageState extends State<PreIntermediatePage> {
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
                            'PRE INTERMEDIATE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B4C7A),
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // GREAT JOB CARD
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'GREAT JOB, SUPER LEARNER! ✨',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "You're getting better\nEvery day!",
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
                                'Pre Intermediate Level',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'More Word - More Fun! 🎉',
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
                        'New topics waiting for you!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4C7A),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // NEW SUBTOPICS - ADDED AT THE TOP
                      _buildLearningItem('My Morning Routine', Icons.brightness_5, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PracticeMorningRoutinePage()),
                        );
                      }),
                      const SizedBox(height: 10),
                      _buildLearningItem('My Feelings', Icons.emoji_emotions, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PracticeFeelingsPage()),
                        );
                      }),
                      const SizedBox(height: 10),
                      _buildLearningItem('Things I Like', Icons.favorite, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PracticeThingsILikePage()),
                        );
                      }),
                      const SizedBox(height: 10),
                      
                      // EXISTING SUBTOPICS (KEPT AS IS)
                      _buildLearningItem('School & Classroom', Icons.school, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PracticeSchoolPage()),
                        );
                      }),
                      const SizedBox(height: 10),
                      _buildLearningItem('Hobbies & Free Time', Icons.sports_esports, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PracticeHobbiesPage()),
                        );
                      }),
                      const SizedBox(height: 10),
                      _buildLearningItem('Daily Routine', Icons.schedule, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PracticeDailyRoutinePage()),
                        );
                      }),
                      const SizedBox(height: 10),
                      _buildLearningItem('Home & Rooms', Icons.home, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PracticeHomeRoomsPage()),
                        );
                      }),
                      const SizedBox(height: 10),
                      _buildLearningItem('Shopping & Toys', Icons.shopping_bag, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PracticeShoppingToysPage()),
                        );
                      }),

                      const SizedBox(height: 25),

                      // TIP FROM FREDDIE THE FOX CARD
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
                                  'TIP FROM FREDDIE THE FOX 🦊',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'You already know the basics',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: Colors.black),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "Now let's make SENTENCES!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFCC99),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Try: "I go to school by bus 🚌"',
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

                      Center(
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Starting practice session...'),
                                backgroundColor: Color(0xFFFFCC99),
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

  Widget _buildLearningItem(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
                color: const Color(0xFFFFE0B3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, size: 24, color: const Color(0xFFE67E22)),
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
              color: Color(0xFFFFCC99),
            ),
          ],
        ),
      ),
    );
  }
}