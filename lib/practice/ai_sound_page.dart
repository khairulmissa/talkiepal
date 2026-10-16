import 'package:flutter/material.dart';
import 'package:talkiepal/main.dart';
import 'package:talkiepal/game_page.dart';
import 'package:talkiepal/profile_page.dart';
import 'package:talkiepal/services/exercise_service.dart';
import 'package:talkiepal/practice/widgets/success_dialog.dart';
import 'package:talkiepal/widgets/kids_bottom_nav.dart';
import 'package:talkiepal/progress_page.dart';

/// Special Sound practice for one target sound (R, S, TH, ...).
/// Words mode shows one word; sentence mode (Mini Challenge) shows a sentence.
/// The words and sentences come from the AI backend.
class AiSoundPage extends StatefulWidget {
  final String sound;
  final bool isSentence;
  final int count;

  const AiSoundPage({
    super.key,
    required this.sound,
    required this.isSentence,
    this.count = 5,
  });

  @override
  State<AiSoundPage> createState() => _AiSoundPageState();
}

class _AiSoundPageState extends State<AiSoundPage> {
  static const Map<String, String> _soundTips = {
    'R': 'Focus on the "R" sound - Roll your tongue!',
    'S': 'Focus on the "S" sound - Like a snake hissing!',
    'L': 'Focus on the "L" sound - Tongue touches the top of your mouth!',
    'TH': 'Stick your tongue out between your teeth for "TH"!',
    'SH': 'Pucker your lips and blow air for "SH"!',
    'CH': 'Like a train "choo choo" sound!',
    'V': 'Bite your bottom lip to say "V"!',
    'W': 'Round your lips like you are blowing a kiss for "W"!',
  };

  static const Color _targetColor = Color(0xFFFFD54F);

  bool isLoading = true;
  bool isPlaying = false;
  bool isListening = false;
  int currentIndex = 0;
  List<PracticeExercise> exercises = [];

  // Index of the letter box (words) or word (sentences) that is lit up.
  int highlightedUnit = -1;
  Color highlightColor = Colors.white;

  // Bumped whenever the item changes, so an old highlight run stops.
  int _highlightRun = 0;

  PracticeExercise get currentExercise => exercises[currentIndex];

  String get _apiLevel => widget.isSentence ? 'special_sentences' : 'special_words';

  /// Letter boxes for a word, keeping the target sound together: TH R E E.
  List<String> _splitLetters(String word) {
    final sound = widget.sound;
    final boxes = <String>[];
    var i = 0;

    while (i < word.length) {
      if (word.startsWith(sound, i)) {
        boxes.add(sound);
        i += sound.length;
      } else {
        boxes.add(word[i]);
        i++;
      }
    }
    return boxes;
  }

  /// What lights up one by one: letter boxes for a word, words for a sentence.
  List<String> get currentUnits => widget.isSentence
      ? currentExercise.word.split(' ')
      : _splitLetters(currentExercise.word);

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
      level: _apiLevel,
      topic: widget.sound,
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

  // Call inside setState.
  void _stopHighlight() {
    _highlightRun++;
    highlightedUnit = -1;
    isPlaying = false;
    isListening = false;
  }

  /// Lights up each unit one by one.
  /// Returns false if it was stopped because the item changed.
  Future<bool> _highlightUnits(Color color, Duration perUnit) async {
    final run = ++_highlightRun;
    final units = currentUnits;

    for (var i = 0; i < units.length; i++) {
      if (!mounted || run != _highlightRun) return false;
      setState(() {
        highlightColor = color;
        highlightedUnit = i;
      });
      await Future.delayed(perUnit);
    }

    if (!mounted || run != _highlightRun) return false;
    setState(() {
      highlightedUnit = -1;
    });
    return true;
  }

  Duration get _pace => Duration(milliseconds: widget.isSentence ? 600 : 500);

  Future<void> _onListen() async {
    if (isPlaying || isListening) return;
    setState(() {
      isPlaying = true;
    });

    // Audio is not connected yet; the highlight shows the reading pace.
    final finished = await _highlightUnits(Colors.white, _pace);

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

    final finished = await _highlightUnits(_targetColor, _pace);
    if (!mounted || !finished) return;

    final score = await _checkPronunciation();
    if (!mounted) return;

    setState(() {
      isListening = false;
    });
    _showResultDialog(score);
  }

  /// How close the child's pronunciation was, from 0 to 100.
  /// Speech-to-text is not connected yet, so this always returns 100.
  Future<int> _checkPronunciation() async {
    return 100;
  }

  void _finish() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Congratulations! You completed all of them! 🎉'),
        backgroundColor: Color(0xFFA8D5A2),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  void _goToNext() {
    if (currentIndex + 1 < exercises.length) {
      setState(() {
        currentIndex++;
        _stopHighlight();
      });
    } else {
      _finish();
    }
  }

  void _showResultDialog(int score) {
    if (score >= 100) {
      final bool isLast = currentIndex == exercises.length - 1;

      showSuccessDialog(
        context,
        detail: 'You scored $score%!',
        nextLabel: isLast ? 'FINISH →' : 'NEXT →',
        onNext: _goToNext,
      );
      return;
    }

    const Color mainColor = Color(0xFFFF6B6B);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB6B6), mainColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '❌ OOPS! ❌',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$score%',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Almost there! Listen again and repeat!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 20),
                _buildDialogButton(
                  label: 'TRY AGAIN',
                  color: mainColor,
                  onTap: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
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
            image: AssetImage('lib/assets/images/bg_wordpractices.png'),
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
                    children: [
                      const SizedBox(height: 10),
                      _buildHeader(),
                      const SizedBox(height: 20),
                      if (isLoading) _buildLoadingCard() else ..._buildPracticeContent(),
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
    final title = widget.isSentence
        ? 'MINI CHALLENGE - SOUND ${widget.sound}'
        : 'SOUND ${widget.sound} - WORDS';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildCircleButton(Icons.arrow_back, () => Navigator.pop(context)),
        Flexible(
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
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
                  isLoading ? 'Loading...' : '${currentIndex + 1} of ${exercises.length}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF8B5E9E)),
                ),
              ),
            ],
          ),
        ),
        // New words button
        _buildCircleButton(Icons.refresh, isLoading ? null : _loadExercises),
      ],
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFE8D5F0),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 24, color: const Color(0xFF8B5E9E)),
      ),
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
      child: Column(
        children: [
          const CircularProgressIndicator(color: Color(0xFF8B5E9E)),
          const SizedBox(height: 15),
          Text(
            widget.isSentence
                ? 'Creating new sentences for you... ✨'
                : 'Creating new words for you... ✨',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B4C7A),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPracticeContent() {
    return [
      _buildPracticeCard(),
      const SizedBox(height: 25),
      _buildListenButton(),
      const SizedBox(height: 20),
      const Row(
        children: [
          Expanded(child: Divider(color: Colors.grey)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('OR', style: TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Divider(color: Colors.grey)),
        ],
      ),
      const SizedBox(height: 20),
      _buildSpeakButton(),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F4FD),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lightbulb, size: 20, color: Color(0xFF9C27B0)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _soundTips[widget.sound] ?? 'Listen first, then say it clearly!',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B4C7A)),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildPracticeCard() {
    final units = currentUnits;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC9B3E0), Color(0xFF9C27B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(currentExercise.emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text(
            widget.isSentence ? 'SAY THIS SENTENCE' : 'SAY THE WORD',
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: widget.isSentence ? 6 : 4,
            runSpacing: 8,
            children: List.generate(units.length, (i) {
              return widget.isSentence
                  ? _buildSentenceWord(units[i], i == highlightedUnit)
                  : _buildLetterBox(units[i], i == highlightedUnit, units.length);
            }),
          ),
        ],
      ),
    );
  }

  /// One letter box. The target sound is yellow with an underline.
  Widget _buildLetterBox(String text, bool isLit, int boxCount) {
    final isTarget = text == widget.sound;
    final double fontSize = boxCount <= 4 ? 44 : (boxCount <= 6 ? 36 : 28);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isLit ? highlightColor : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: isTarget && !isLit
            ? Border.all(color: _targetColor, width: 2)
            : Border.all(color: Colors.transparent, width: 2),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: isLit
              ? const Color(0xFF9C27B0)
              : (isTarget ? _targetColor : Colors.white),
        ),
      ),
    );
  }

  /// One word of a sentence. The target sound letters are yellow.
  Widget _buildSentenceWord(String word, bool isLit) {
    final baseColor = isLit ? const Color(0xFF9C27B0) : Colors.white;
    final targetColor = isLit ? const Color(0xFFE67E22) : _targetColor;

    final spans = <TextSpan>[];
    final parts = word.split(widget.sound);
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(text: parts[i], style: TextStyle(color: baseColor)));
      }
      if (i < parts.length - 1) {
        spans.add(TextSpan(text: widget.sound, style: TextStyle(color: targetColor)));
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isLit ? highlightColor : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          children: spans,
        ),
      ),
    );
  }

  Widget _buildListenButton() {
    return Center(
      child: GestureDetector(
        onTap: _onListen,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          decoration: BoxDecoration(
            color: isPlaying ? Colors.grey : const Color(0xFFC9B3E0),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.play_arrow,
                size: 24,
                color: isPlaying ? Colors.white60 : Colors.white,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isPlaying
                      ? 'PLAYING...'
                      : (widget.isSentence ? '🔊 LISTEN' : '🔊 LISTEN TO THE WORD'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isPlaying ? Colors.white60 : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeakButton() {
    return Center(
      child: GestureDetector(
        onTap: _onSpeak,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          decoration: BoxDecoration(
            gradient: isListening
                ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                : const LinearGradient(
                    colors: [Color(0xFFA8D5A2), Color(0xFF6BCB77)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isListening ? Icons.mic_off : Icons.mic,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  isListening
                      ? 'WAIT...'
                      : (widget.isSentence ? 'SPEAK' : 'SPEAK THE WORD'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return KidsBottomNav(selected: null, onTap: _onNavTap);
  }

  void _onNavTap(KidsTab tab) {
    switch (tab) {
      case KidsTab.home:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case KidsTab.game:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GamePage()),
        );
        break;
      case KidsTab.progress:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProgressPage()),
        );
        break;
      case KidsTab.profile:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }
}
