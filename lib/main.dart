import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'beginner/beginner_page.dart';
import 'pre intermediate/pre_intermediate_page.dart';
import 'intermediate/intermediate_page.dart';
import 'special_sound/specialsound_page.dart';
import 'game_page.dart';
import 'profile_page.dart';
import 'parent/splash_screen.dart';
import 'package:talkiepal/widgets/kids_bottom_nav.dart';
import 'package:talkiepal/progress_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDFlqcIHBFaXd2rRWeAE1_-hjyki79axgY',
      appId: '1:474037018699:android:b85a8528272d731939edce',
      messagingSenderId: '474037018699',
      projectId: 'talkiepal-80191',
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TalkiePal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primarySwatch: Colors.purple,
      ),
      home: const SplashScreen(),
    );
  }
}

class HomePage extends StatefulWidget {
  final String? selectedKidName;
  
  const HomePage({super.key, this.selectedKidName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  static const Color _cream = Color(0xFFFFF8EC);
  static const Color _purple = Color(0xFF6B4C7A);
  static const Color _softPurple = Color(0xFF9A7FA8);

  @override
  Widget build(BuildContext context) {
    final kidName = widget.selectedKidName ?? "Khairulmissa";

    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          // Soft coloured circles in the background
          Positioned(top: -60, right: -40, child: _buildBlob(180, const Color(0xFFFFE0F0))),
          Positioned(top: 260, left: -70, child: _buildBlob(150, const Color(0xFFDDF5E3))),
          Positioned(bottom: 120, right: -60, child: _buildBlob(170, const Color(0xFFE3EEFF))),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(kidName),
                        const SizedBox(height: 18),
                        _buildHeroBanner(),
                        const SizedBox(height: 26),
                        const Row(
                          children: [
                            Text('🦖', style: TextStyle(fontSize: 26)),
                            SizedBox(width: 8),
                            Text(
                              'Choose Your Level',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: _purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pick a dino friend to play with!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _softPurple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildLevelCard(
                          letter: 'A',
                          title: 'Beginner',
                          subtitle: '🍎 First words',
                          imagePath: 'lib/assets/images/bg_beginner4.png',
                          color: const Color(0xFF4CAF50),
                          darkColor: const Color(0xFF2E7D32),
                          page: const BeginnerPage(),
                        ),
                        const SizedBox(height: 16),
                        _buildLevelCard(
                          letter: 'B',
                          title: 'Pre Intermediate',
                          subtitle: '💬 Short phrases',
                          imagePath: 'lib/assets/images/bg_pre_inter2.png',
                          color: const Color(0xFF42A5F5),
                          darkColor: const Color(0xFF1565C0),
                          page: const PreIntermediatePage(),
                        ),
                        const SizedBox(height: 16),
                        _buildLevelCard(
                          letter: 'C',
                          title: 'Intermediate',
                          subtitle: '❓ Fun questions',
                          imagePath: 'lib/assets/images/bg_inter2.png',
                          color: const Color(0xFFFF8A3D),
                          darkColor: const Color(0xFFD84315),
                          page: const IntermediatePage(),
                        ),
                        const SizedBox(height: 16),
                        _buildLevelCard(
                          letter: 'D',
                          title: 'Special Sound',
                          subtitle: '🎤 Tricky sounds',
                          imagePath: 'lib/assets/images/bg_ss3.png',
                          color: const Color(0xFFD81B8C),
                          darkColor: const Color(0xFF9C1361),
                          page: const SpecialSoundPage(),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                _buildBottomNav(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildHeader(String kidName) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Hello, $kidName!',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _purple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _waveController.value * 0.3,
                        child: child,
                      );
                    },
                    child: const Text('👋', style: TextStyle(fontSize: 24)),
                  ),
                ],
              ),
              const Text(
                'Ready to talk with your dino friends?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _softPurple,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Profile button (switch to parent profile)
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFE8D5F0),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: const Icon(Icons.person_rounded, size: 30, color: Color(0xFF8B5E9E)),
        ),
      ],
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 5),
        boxShadow: const [
          BoxShadow(color: Color(0xFF7E57C2), offset: Offset(0, 7)),
        ],
        image: const DecorationImage(
          image: AssetImage('lib/assets/images/background_talkiepal_kotak.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'TalkiePal',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
              shadows: [Shadow(color: Color(0x66000000), offset: Offset(0, 3), blurRadius: 6)],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Practice • Pronounce • Perfect',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF6A1B9A),
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Decoration only, not a button
          const Text(
            "✨ Let's Practice! ✨",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [Shadow(color: Color(0x88000000), offset: Offset(0, 2), blurRadius: 6)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard({
    required String letter,
    required String title,
    required String subtitle,
    required String imagePath,
    required Color color,
    required Color darkColor,
    required Widget page,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Container(
        height: 118,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [BoxShadow(color: darkColor, offset: const Offset(0, 6))],
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            // White label so the text is always easy to read
            Container(
              constraints: const BoxConstraints(maxWidth: 215),
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: darkColor, offset: const Offset(0, 3))],
                    ),
                    child: Text(
                      letter,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: darkColor,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7A6A85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return KidsBottomNav(selected: KidsTab.home, onTap: _onNavTap);
  }

  void _onNavTap(KidsTab tab) {
    switch (tab) {
      case KidsTab.home:
        // Already on this page
        break;
      case KidsTab.game:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GamePage()),
        );
        break;
      case KidsTab.progress:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProgressPage()),
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
}