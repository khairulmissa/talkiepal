import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'beginner/beginner_page.dart';
import 'pre intermediate/pre_intermediate_page.dart';
import 'intermediate/intermediate_page.dart';
import 'special_sound/specialsound_page.dart';
import 'game_page.dart';
import 'profile_page.dart';
import 'parent/splash_screen.dart';

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
  await Supabase.initialize(
    url: 'https://lnmpyghuwmvbggjvbirs.supabase.co',
    anonKey: 'sb_publishable_4kXDW835pb1iYXUv-XgQGg_TT2GeSCp',
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

  @override
  Widget build(BuildContext context) {
    final kidName = widget.selectedKidName ?? "Khairulmissa";
    
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Hello, ',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF6B4C7A),
                              ),
                            ),
                            Text(
                              kidName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6B4C7A),
                              ),
                            ),
                            const SizedBox(width: 5),
                            AnimatedBuilder(
                              animation: _waveController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _waveController.value * 0.3,
                                  child: const Text(
                                    '👋',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8D5F0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 25,
                            color: Color(0xFF8B5E9E),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        image: const DecorationImage(
                          image: AssetImage('lib/assets/images/background_talkiepal_kotak.png'),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black26,
                            BlendMode.darken,
                          ),
                        ),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5E9E), Color(0xFFB47CC4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'TalkiePal',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Practice. Pronounce. Perfect.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.amber,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: const Text(
                              "Let's go Practice!",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8B5E9E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    const Row(
                      children: [
                        Text(
                          'Choose Your Level',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B4C7A),
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFFB47CC4),
                          size: 24,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _buildLevelRowWithImage(
                      letter: 'A',
                      title: 'BEGINNER',
                      imagePath: 'lib/assets/images/bg_beginner4.png',
                      defaultColor: const Color(0xFFA8D5A2),
                    ),

                    const SizedBox(height: 15),

                    _buildLevelRowWithImage(
                      letter: 'B',
                      title: 'PRE INTERMEDIATE',
                      imagePath: 'lib/assets/images/bg_pre_inter2.png',
                      defaultColor: const Color(0xFFFFCC99),
                    ),

                    const SizedBox(height: 15),

                    _buildLevelRowWithImage(
                      letter: 'C',
                      title: 'INTERMEDIATE',
                      imagePath: 'lib/assets/images/bg_inter2.png',
                      defaultColor: const Color(0xFFC9B3E0),
                    ),

                    const SizedBox(height: 15),

                    _buildLevelRowWithImage(
                      letter: 'D',
                      title: 'SPECIAL SOUND',
                      imagePath: 'lib/assets/images/bg_ss3.png',
                      defaultColor: const Color(0xFFFFB5C0),
                    ),

                    const SizedBox(height: 30),
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
                    _buildNavItem(Icons.home, 'Home', true),
                    _buildNavItem(Icons.gamepad, 'Game', false),
                    _buildNavItem(Icons.bar_chart, 'Progress', false),
                    _buildNavItem(Icons.person, 'Profile', false),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelRowWithImage({
    required String letter,
    required String title,
    required String imagePath,
    required Color defaultColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: defaultColor.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            defaultColor.withOpacity(0.5),
            BlendMode.darken,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (title == 'BEGINNER') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BeginnerPage()),
              );
            } else if (title == 'PRE INTERMEDIATE') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PreIntermediatePage()),
              );
            } else if (title == 'INTERMEDIATE') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IntermediatePage()),
              );
            } else if (title == 'SPECIAL SOUND') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SpecialSoundPage()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title coming soon! 🌟'),
                  backgroundColor: defaultColor,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (label == 'Home') {
          // Already on Home
        } else if (label == 'Game') {
          Navigator.push(
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
          Navigator.push(
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