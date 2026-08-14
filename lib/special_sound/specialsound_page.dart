import 'package:flutter/material.dart';
import 'R_words.dart';
import 'S_words.dart';
import 'L_words.dart';
import 'TH_words.dart';
import 'SH_words.dart';
import 'CH_words.dart';
import 'V_words.dart';
import 'W_words.dart';
import 'mini_challenge_r.dart';
import 'mini_challenge_s.dart';
import 'mini_challenge_l.dart';
import 'mini_challenge_th.dart';
import 'mini_challenge_sh.dart';
import 'mini_challenge_ch.dart';
import 'mini_challenge_v.dart';
import 'mini_challenge_w.dart';

class SpecialSoundPage extends StatefulWidget {
  const SpecialSoundPage({super.key});

  @override
  State<SpecialSoundPage> createState() => _SpecialSoundPageState();
}

class _SpecialSoundPageState extends State<SpecialSoundPage> {
  
  void _showLevelOptions(BuildContext context, String level, List<String> sounds) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: level == 'LEVEL 1'
                  ? const LinearGradient(
                      colors: [Color(0xFF6BCB77), Color(0xFF4CAF50)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFFFB5C0), Color(0xFFE91E63)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    level == 'LEVEL 1' ? '🌟' : '🚀',
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  level,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Choose your activity!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 20),
                
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 20),
                
                // WORDS TO PRACTICE
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showSoundSelection(context, level, sounds, 'words');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: level == 'LEVEL 1' 
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFE0E0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.menu_book,
                              size: 28,
                              color: level == 'LEVEL 1' 
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFE91E63),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'WORDS TO PRACTICE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5D3A6B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Learn and repeat words',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: level == 'LEVEL 1' 
                              ? const Color(0xFF6BCB77)
                              : const Color(0xFFFFB5C0),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // MINI CHALLENGE
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showSoundSelection(context, level, sounds, 'challenge');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: level == 'LEVEL 1' 
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFE0E0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.emoji_events,
                              size: 28,
                              color: level == 'LEVEL 1' 
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFE91E63),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'MINI CHALLENGE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5D3A6B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Test your listening skills',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: level == 'LEVEL 1' 
                              ? const Color(0xFF6BCB77)
                              : const Color(0xFFFFB5C0),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'CLOSE',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSoundSelection(BuildContext context, String level, List<String> sounds, String type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: level == 'LEVEL 1' 
                        ? const Color(0xFF6BCB77).withOpacity(0.1)
                        : const Color(0xFFE91E63).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    type == 'words' ? Icons.menu_book : Icons.emoji_events,
                    size: 40,
                    color: level == 'LEVEL 1' 
                        ? const Color(0xFF6BCB77)
                        : const Color(0xFFE91E63),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  type == 'words' ? 'Choose a Sound' : 'Choose a Challenge',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5D3A6B),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  level == 'LEVEL 1' 
                      ? 'Select which sound you want to practice'
                      : 'Select which advanced sound to practice',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                
                Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                const SizedBox(height: 15),
                
                // SCROLLABLE AREA FOR SOUND OPTIONS
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: sounds.map((sound) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            if (type == 'words') {
                              _goToWordsPractice(context, level, sound);
                            } else {
                              _goToMiniChallenge(context, level, sound);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: level == 'LEVEL 1'
                                    ? [const Color(0xFF6BCB77).withOpacity(0.1), const Color(0xFF4CAF50).withOpacity(0.05)]
                                    : [const Color(0xFFFFB5C0).withOpacity(0.1), const Color(0xFFE91E63).withOpacity(0.05)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: level == 'LEVEL 1' 
                                    ? const Color(0xFF6BCB77).withOpacity(0.3)
                                    : const Color(0xFFE91E63).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: level == 'LEVEL 1' 
                                        ? const Color(0xFF6BCB77).withOpacity(0.2)
                                        : const Color(0xFFE91E63).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      sound,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: level == 'LEVEL 1' 
                                            ? const Color(0xFF4CAF50)
                                            : const Color(0xFFE91E63),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sound $sound',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF5D3A6B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        level == 'LEVEL 1'
                                            ? _getSoundDescription(sound)
                                            : _getAdvancedSoundDescription(sound),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 18,
                                  color: level == 'LEVEL 1' 
                                      ? const Color(0xFF6BCB77)
                                      : const Color(0xFFFFB5C0),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'BACK',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getSoundDescription(String sound) {
    switch (sound) {
      case 'R':
        return 'The Basic Tricky Sound - Roll your tongue';
      case 'S':
        return 'The Hissing Sound - Like a snake';
      case 'L':
        return 'The Light Sound - Tongue touches top';
      default:
        return 'Practice this sound';
    }
  }

  String _getAdvancedSoundDescription(String sound) {
    switch (sound) {
      case 'TH':
        return 'The Biting Sound - Tongue between teeth';
      case 'SH':
        return 'The Quiet Sound - Like "shhh"';
      case 'CH':
        return 'The Train Sound - Like a choo-choo train';
      case 'V':
        return 'The Buzzing Sound - Teeth on lip';
      case 'W':
        return 'The Woo Sound - Round your lips';
      default:
        return 'Practice this advanced sound';
    }
  }

  void _goToWordsPractice(BuildContext context, String level, String sound) {
    // Navigate to words practice page based on selected sound
    if (sound == 'R') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PracticeWordsRPage()),
      );
    } else if (sound == 'S') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PracticeWordsSPage()),
      );
    } else if (sound == 'L') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PracticeWordsLPage()),
      );
    } else if (sound == 'TH') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PracticeWordsTHPage()),
      );
    } else if (sound == 'SH') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PracticeWordsSHPage()),
      );
    } else if (sound == 'CH') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PracticeWordsCHPage()),
      );
    } else if (sound == 'V') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PracticeWordsVPage()),
      );
    } else if (sound == 'W') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PracticeWordsWPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Coming soon: Words Practice for Sound $sound'),
          backgroundColor: level == 'LEVEL 1' ? const Color(0xFF6BCB77) : const Color(0xFFE91E63),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _goToMiniChallenge(BuildContext context, String level, String sound) {
    // Navigate to mini challenge page based on selected sound
    if (sound == 'R') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MiniChallengeRPage()),
      );
    } else if (sound == 'S') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MiniChallengeSPage()),
      );
    } else if (sound == 'L') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MiniChallengeLPage()),
      );
    } else if (sound == 'TH') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MiniChallengeTHPage()),
      );
    } else if (sound == 'SH') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MiniChallengeSHPage()),
      );
    } else if (sound == 'CH') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MiniChallengeCHPage()),
      );
    } else if (sound == 'V') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MiniChallengeVPage()),
      );
    } else if (sound == 'W') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MiniChallengeWPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Coming soon: Mini Challenge for Sound $sound'),
          backgroundColor: level == 'LEVEL 1' ? const Color(0xFF6BCB77) : const Color(0xFFE91E63),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

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
                                color: const Color(0xFFFFE0E0),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                size: 24,
                                color: Color(0xFFE91E63),
                              ),
                            ),
                          ),
                          const Text(
                            'SPECIAL SOUND',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE91E63),
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
                            colors: [Color(0xFFFFB5C0), Color(0xFFE91E63)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Master the Tricky Sounds! 🎯',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Let's fix your sound",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'R - S - L - TH - SH - CH - V - W',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Choose your level and start!',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // LEVEL 1 CARD (R, S, L)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color.fromARGB(255, 103, 138, 98), Color.fromARGB(255, 72, 148, 82)],
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
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    'LEVEL 1',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              'R',
                                              style: TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'The Basic\nTricky Sound',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              'S',
                                              style: TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'The Hissing\nSound',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              'L',
                                              style: TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'The Light\nSound',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _showLevelOptions(context, 'LEVEL 1', ['R', 'S', 'L']);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'CHOOSE LEVEL 1',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6BCB77),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // LEVEL 2 CARD (TH, SH, CH, V, W)
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFB5C0), Color(0xFFE91E63)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                    'LEVEL 2',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      Text(
                                        'TH',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'SH',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'CH',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'V',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'W',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '"The Advanced Mouth Movers"',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _showLevelOptions(context, 'LEVEL 2', ['TH', 'SH', 'CH', 'V', 'W']);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'CHOOSE LEVEL 2',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE91E63),
                                    ),
                                  ),
                                ),
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
                          color: const Color(0xFFFFF0E0),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFB5C0),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lightbulb, color: Color(0xFFE91E63), size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'TIP FROM PIP THE PARROT 🦜',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFFE91E63),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              '"Start with Level 1 if you\'re new!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Level 2 has trickier sounds like TH and V.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Take your time!"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),
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
}