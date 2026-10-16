import 'package:flutter/material.dart';
import 'package:talkiepal/profile_page.dart';
import 'package:talkiepal/widgets/kids_bottom_nav.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/images/bg_gamepage.png'),
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
                      const SizedBox(height: 20),

                      const Text(
                        'KIDS GAME ZONE',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4C7A),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Play and learn to speak!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF8B5E9E),
                        ),
                      ),

                      const SizedBox(height: 30),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'CHOOSE YOUR GAME',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B4C7A),
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                        childAspectRatio: 1.2,
                        children: [
                          _buildGameCard(
                            title: 'SOUND\nMATCHER',
                            subtitle: 'Match the sounds',
                            imagePath: 'lib/assets/images/game_soundmatcher.png',
                            onTap: () {
                              _showComingSoon(context, 'Sound Matcher');
                            },
                          ),
                          _buildGameCard(
                            title: 'MINIMAL\nPAIRS',
                            subtitle: 'Spot the difference',
                            imagePath: 'lib/assets/images/game_minimalpairs.png',
                            onTap: () {
                              _showComingSoon(context, 'Minimal Pairs');
                            },
                          ),
                          _buildGameCard(
                            title: 'MATCH THE\nPAIR',
                            subtitle: 'Find matching cards',
                            imagePath: 'lib/assets/images/game_matchpair.png',
                            onTap: () {
                              _showComingSoon(context, 'Match the Pair');
                            },
                          ),
                          _buildGameCard(
                            title: 'YES OR NO?',
                            subtitle: 'Answer correctly',
                            imagePath: 'lib/assets/images/game_yesorno.png',
                            onTap: () {
                              _showComingSoon(context, 'Yes or No?');
                            },
                          ),
                          _buildGameCard(
                            title: 'SHADOW MATCH\nPUZZLE',
                            subtitle: 'Find the shadow',
                            imagePath: 'lib/assets/images/game_puzzle.png',
                            onTap: () {
                              _showComingSoon(context, 'Shadow Match Puzzle');
                            },
                          ),
                          _buildGameCard(
                            title: 'FIND THE\nBALL',
                            subtitle: 'Where is the ball?',
                            imagePath: 'lib/assets/images/game_findball.png',
                            onTap: () {
                              _showComingSoon(context, 'Find the Ball');
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              KidsBottomNav(selected: KidsTab.game, onTap: _onNavTap),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required String title,
    required String subtitle,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFE8D5F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  imagePath,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: Color(0xFF8B5E9E),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D3A6B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
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
        Navigator.pop(context);
        break;
      case KidsTab.game:
        // Already on this page
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  void _showComingSoon(BuildContext context, String gameName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$gameName coming soon! 🎮'),
        backgroundColor: const Color(0xFFB47CC4),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}