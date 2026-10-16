import 'package:flutter/material.dart';
import 'package:talkiepal/main.dart';
import 'package:talkiepal/game_page.dart';
import 'package:talkiepal/profile_page.dart';
import 'package:talkiepal/services/exercise_service.dart';
import 'package:talkiepal/practice/widgets/success_dialog.dart';

/// One practice page for every topic. The words come from the AI backend
/// instead of being written in the code.
class AiPracticePage extends StatefulWidget {
  final String level;
  final String levelLabel;
  final String topic;
  final String topicEmoji;
  final int count;

  const AiPracticePage({
    super.key,
    required this.level,
    required this.levelLabel,
    required this.topic,
    this.topicEmoji = '⭐',
    this.count = 5,
  });

  @override
  State<AiPracticePage> createState() => _AiPracticePageState();
}

class _AiPracticePageState extends State<AiPracticePage> {
  bool isLoading = true;
  bool isListening = false;
  bool isPlaying = false;
  int currentIndex = 0;

  // Index of the word that is lit up while LISTEN or SPEAK runs (-1 = none).
  int highlightedWord = -1;
  Color highlightColor = const Color(0xFFA8D5A2);

  // Bumped whenever the exercise changes, so an old highlight run stops.
  int _highlightRun = 0;
  List<PracticeExercise> exercises = [];

  PracticeExercise get currentExercise => exercises[currentIndex];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() {
      isLoading = true;
      currentIndex = 0;
      _stopHighlight();
    });

    final result = await ExerciseService.getExercises(
      level: widget.level,
      topic: widget.topic,
      count: widget.count,
    );

    if (!mounted) return;

    setState(() {
      exercises = result.exercises;
      isLoading = false;
    });

    if (result.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📴 AI is offline. Using practice words instead.'),
          backgroundColor: Color(0xFFFFB347),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _finish() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Congratulations! You completed ${widget.topic.toLowerCase()}! 🎉'),
        backgroundColor: const Color(0xFFA8D5A2),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  List<String> get currentWords => currentExercise.word.split(' ');

  /// Lights up each word of the current exercise one by one.
  /// Returns false if it was stopped because the exercise changed.
  Future<bool> _highlightWords(Color color, Duration perWord) async {
    final run = ++_highlightRun;
    final words = currentWords;

    for (var i = 0; i < words.length; i++) {
      if (!mounted || run != _highlightRun) return false;
      setState(() {
        highlightColor = color;
        highlightedWord = i;
      });
      await Future.delayed(perWord);
    }

    if (!mounted || run != _highlightRun) return false;
    setState(() {
      highlightedWord = -1;
    });
    return true;
  }

  // Call inside setState.
  void _stopHighlight() {
    _highlightRun++;
    highlightedWord = -1;
    isListening = false;
    isPlaying = false;
  }

  Future<void> _onListen() async {
    if (isPlaying || isListening) return;
    setState(() {
      isPlaying = true;
    });

    // Audio is not connected yet; the highlight shows the reading pace.
    final finished = await _highlightWords(const Color(0xFFA8D5A2), const Duration(milliseconds: 700));

    if (!mounted || !finished) return;
    setState(() {
      isPlaying = false;
    });
  }

  Future<void> _onSpeak() async {
    if (isPlaying || isListening) return;
    setState(() {
      isListening = true;
    });

    // Speech checking is not connected yet, so this always passes.
    final finished = await _highlightWords(const Color(0xFFB47CC4), const Duration(milliseconds: 900));

    if (!mounted || !finished) return;
    setState(() {
      isListening = false;
    });
    _showResultDialog();
  }

  void _goToNextExercise() {
    if (currentIndex + 1 < exercises.length) {
      setState(() {
        currentIndex++;
        _stopHighlight();
      });
    } else {
      _finish();
    }
  }

  void _showResultDialog() {
    final bool isLastExercise = currentIndex == exercises.length - 1;

    showSuccessDialog(
      context,
      detail: 'You said "${currentExercise.word}"!',
      nextLabel: isLastExercise ? 'FINISH →' : 'NEXT →',
      onNext: _goToNextExercise,
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
            image: AssetImage('lib/assets/images/fullbg_beginnerpractice.png'),
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
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildGreeting(),
                      const SizedBox(height: 20),
                      _buildInfoBar(),
                      const SizedBox(height: 20),
                      isLoading ? _buildLoadingCard() : _buildChallengeCard(),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFE8D5F0),
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
            Text(
              widget.topic.toUpperCase(),
              style: const TextStyle(
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
                isLoading ? 'Loading...' : 'Exercise ${currentIndex + 1} of ${exercises.length}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF8B5E9E),
                ),
              ),
            ),
          ],
        ),
        // New words button
        GestureDetector(
          onTap: isLoading ? null : _loadExercises,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFE8D5F0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.refresh,
              size: 24,
              color: Color(0xFF8B5E9E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return Container(
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
            color: Colors.green.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'HELLO! 👋',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Let's learn ${widget.topic.toLowerCase()} today!",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: _buildInfoItem(widget.topicEmoji, 'Level: ${widget.levelLabel}')),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade300,
          ),
          Expanded(child: _buildInfoItem(widget.topicEmoji, widget.topic)),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF5D3A6B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E0),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFFFCC99),
          width: 1.5,
        ),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: Color(0xFF8B5E9E)),
          SizedBox(height: 15),
          Text(
            'Creating new practice for you... ✨',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B4C7A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard() {
    return Container(
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
                _buildPicture(),
                const SizedBox(height: 10),
                _buildWords(),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.headphones,
                label: isPlaying ? '...' : 'LISTEN',
                color: const Color(0xFFA8D5A2),
                onTap: _onListen,
              ),
              _buildActionButton(
                icon: Icons.mic,
                label: isListening ? '...' : 'SPEAK',
                color: const Color(0xFFC9B3E0),
                onTap: _onSpeak,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWords() {
    final words = currentWords;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: List.generate(words.length, (i) {
        final isLit = i == highlightedWord;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isLit ? highlightColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            words[i],
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isLit ? Colors.white : const Color(0xFF6B4C7A),
              letterSpacing: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPicture() {
    return Container(
      width: 100,
      height: 100,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFE8D5F0),
        shape: BoxShape.circle,
      ),
      child: Text(
        currentExercise.emoji,
        style: const TextStyle(fontSize: 50),
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
              color: color.withValues(alpha: 0.3),
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

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
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
            _buildNavItem(Icons.home, 'Home'),
            _buildNavItem(Icons.gamepad, 'Game'),
            _buildNavItem(Icons.bar_chart, 'Progress'),
            _buildNavItem(Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label) {
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
          Icon(icon, color: Colors.grey.shade400, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
