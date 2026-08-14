import 'package:flutter/material.dart';
import 'about_me.dart';  
import 'daily_routine.dart';  
import 'my_school.dart';  

class IntermediatePage extends StatefulWidget {
  const IntermediatePage({super.key});

  @override
  State<IntermediatePage> createState() => _IntermediatePageState();
}

class _IntermediatePageState extends State<IntermediatePage> {
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
                            'INTERMEDIATE',
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

                      // YOU'RE A STAR SPEAKER CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "YOU'RE A STAR SPEAKER! ⭐",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Now let's go further\nAdventure awaits!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Intermediate Level',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Sentences - Stories - Feelings 📖',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        'Some existing topics for you!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4C7A),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // NEW SUBTOPICS - AT THE TOP
                      _buildLearningItem('About Me', Icons.person, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PracticeAboutMePage()),
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
                      
                      _buildLearningItem('My School', Icons.school, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PracticeMySchoolPage()),
                        );
                      }),
                      const SizedBox(height: 10),

                      // EXISTING SUBTOPICS (KEPT AS IS)
                      _buildLearningItem('Travel & Holiday', Icons.flight_takeoff, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening Travel & Holiday...'),
                            backgroundColor: Color(0xFFC9B3E0),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      _buildLearningItem('Weather & Seasons', Icons.wb_sunny, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening Weather & Seasons...'),
                            backgroundColor: Color(0xFFC9B3E0),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      _buildLearningItem('Feelings & Emotion', Icons.emoji_emotions, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening Feelings & Emotion...'),
                            backgroundColor: Color(0xFFC9B3E0),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      _buildLearningItem('Places Around Town', Icons.location_city, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening Places Around Town...'),
                            backgroundColor: Color(0xFFC9B3E0),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      _buildLearningItem('Mini Stories', Icons.menu_book, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening Mini Stories...'),
                            backgroundColor: Color(0xFFC9B3E0),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }),

                      const SizedBox(height: 25),

                      // TIP FROM DINA THE DOLPHIN CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F4FD),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF9C27B0),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lightbulb, color: Color(0xFF9C27B0), size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'TIP FROM DINA THE DOLPHIN 🐬',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF6B4C7A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'You can make full sentences now!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B4C7A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8D5F0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Try roleplay with a friend! 🎭',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF8B5E9E),
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
                                backgroundColor: Color(0xFFC9B3E0),
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