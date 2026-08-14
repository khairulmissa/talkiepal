import 'package:flutter/material.dart';
import 'parent_home_screen.dart';
import 'kids_profile_screen.dart';  


class ChooseRoleScreen extends StatelessWidget {
  const ChooseRoleScreen({super.key});

  Widget star(double size) {
    return Icon(
      Icons.star,
      color: const Color(0xFFFFEFA8),
      size: size,
    );
  }

  Widget roleCard({
    required String image,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: 150,
        height: 220,

        decoration: BoxDecoration(
          color: const Color(0xFFDCE96B),
          borderRadius: BorderRadius.circular(5),
        ),

        child: Column(
          children: [

            // IMAGE SECTION
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFDCE96B),

                child: Padding(
                  padding: const EdgeInsets.all(8),

                  child: Image.asset(
                    image,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error, size: 50);
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // TITLE
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),

      body: SafeArea(
        child: Stack(
          children: [

            // TOP STAR
            Positioned(
              top: -35,
              right: -35,
              child: star(170),
            ),

            // LEFT STAR
            Positioned(
              left: -45,
              top: 280,
              child: star(170),
            ),

            // BOTTOM STAR
            Positioned(
              right: -45,
              bottom: 25,
              child: star(200),
            ),

            // MAIN CONTENT
            Column(
              children: [

                const SizedBox(height: 40),

                // LOGO
                Image.asset(
                  'lib/assets/images/logo.png',
                  width: 320,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, size: 120);
                  },
                ),

                const SizedBox(height: 80),

                // ROLE CARDS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [

                    // KIDS - CHANGED: Now goes to KidsProfileScreen
                    roleCard(
                      image: 'lib/assets/images/kids.png',
                      title: 'Kids',

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const KidsProfileScreen(),  // ← CHANGED to KidsProfileScreen
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 18),

                    // PARENT
                    roleCard(
                      image: 'lib/assets/images/parent.png',
                      title: 'Parent',

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ParentHomeScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}