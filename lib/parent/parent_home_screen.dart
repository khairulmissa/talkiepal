import 'package:flutter/material.dart';
import 'parent_profile_screen.dart';
// FIXED Imports - use full path from lib folder
import 'package:talkiepal/beginner/beginner_page.dart';
import 'package:talkiepal/pre intermediate/pre_intermediate_page.dart';
import 'package:talkiepal/intermediate/intermediate_page.dart';
import 'package:talkiepal/special_sound/specialsound_page.dart';

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE8),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // TOP HEADER
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFEFA8),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'lib/assets/images/robot.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.android, size: 100);
                            },
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            decoration: ShapeDecoration(
                              color: Color(0xFFFFEFA8),
                              shape: BubbleBorder(),
                            ),
                            child: const Text(
                              "Free Talk (AI)",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Image.asset(
                      'lib/assets/images/logo.png',
                      width: 300,
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error, size: 150);
                      },
                    ),
                    const Divider(thickness: 1),
                    homeCard(
                      child: const Row(
                        children: [
                          Text("👋", style: TextStyle(fontSize: 30)),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hello, Adam",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                "Welcome back!",
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    homeCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "👶 My Children",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          childTile(
                            name: "Khairulmissa",
                            color: const Color(0xFFC8C9E8),
                            onTap: () => _showLearningLevels(context),
                          ),
                          const SizedBox(height: 12),
                          childTile(
                            name: "Sof",
                            color: const Color(0xFFE8A7D1),
                            onTap: () => _showLearningLevels(context),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Add child feature coming soon!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Text(
                              "+ Add child",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    homeCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "💡 Tips",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "More >>",
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Your child is struggling with /s/ sounds. Try words like 'snake', 'sun', 'sock' this week.",
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    homeCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "🗓️ Upcoming sessions",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          sessionText("Friday, 10 April 2026 - 3:00 PM"),
                          sessionText("Therapist: Dr Lim"),
                          sessionText("Kid: Khairulmissa"),
                          const SizedBox(height: 14),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                "[ Reschedule ]",
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                "[ Cancel ]",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    homeCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "📚 Learning Levels",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildLevelButton(
                            title: "BEGINNER",
                            color: const Color(0xFFA8D5A2),
                            icon: Icons.abc,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BeginnerPage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildLevelButton(
                            title: "PRE INTERMEDIATE",
                            color: const Color(0xFFFFCC99),
                            icon: Icons.trending_up,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PreIntermediatePage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildLevelButton(
                            title: "INTERMEDIATE",
                            color: const Color(0xFFC9B3E0),
                            icon: Icons.school,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const IntermediatePage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildLevelButton(
                            title: "SPECIAL SOUND",
                            color: const Color(0xFFFFB5C0),
                            icon: Icons.record_voice_over,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SpecialSoundPage(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Container(
              height: 68,
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  navItem(Icons.home, "Home", true),
                  navItem(Icons.bar_chart, "Progress", false),
                  navItem(Icons.medical_services, "Therapist", false),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ParentProfileScreen(),
                        ),
                      );
                    },
                    child: navItem(Icons.person, "Profile", false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLearningLevels(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Learning Level',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _buildLevelButton(
                title: "BEGINNER",
                color: const Color(0xFFA8D5A2),
                icon: Icons.abc,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BeginnerPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildLevelButton(
                title: "PRE INTERMEDIATE",
                color: const Color(0xFFFFCC99),
                icon: Icons.trending_up,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PreIntermediatePage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildLevelButton(
                title: "INTERMEDIATE",
                color: const Color(0xFFC9B3E0),
                icon: Icons.school,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IntermediatePage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildLevelButton(
                title: "SPECIAL SOUND",
                color: const Color(0xFFFFB5C0),
                icon: Icons.record_voice_over,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SpecialSoundPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelButton({
    required String title,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  static Widget navItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 29,
          color: isSelected ? const Color(0xFF8B5E9E) : Colors.grey,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF8B5E9E) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget homeCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Widget childTile({
    required String name,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        color: color,
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              color: Colors.white54,
              child: const Icon(Icons.child_care, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Last active 4hr ago",
                    style: TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            const Text(
              "view",
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sessionText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          letterSpacing: 1.5,
          fontSize: 12,
        ),
      ),
    );
  }
}

class BubbleBorder extends ShapeBorder {
  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.only(bottom: 12);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final bubbleRect = Rect.fromLTWH(
      rect.left,
      rect.top,
      rect.width,
      rect.height - 12,
    );

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          bubbleRect,
          const Radius.circular(24),
        ),
      );

    path.moveTo(rect.left + 25, rect.bottom - 12);
    path.lineTo(rect.left + 15, rect.bottom);
    path.lineTo(rect.left + 45, rect.bottom - 12);
    path.close();

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final borderPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(getOuterPath(rect), borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return this;
  }
}