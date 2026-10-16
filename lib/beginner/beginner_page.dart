import 'package:flutter/material.dart';
import 'package:talkiepal/beginner/alphabets.dart';
import 'package:talkiepal/beginner/numbers_page.dart';
import 'package:talkiepal/practice/ai_practice_page.dart';
import 'package:talkiepal/widgets/dino_mascot.dart';

class BeginnerPage extends StatefulWidget {
  const BeginnerPage({super.key});

  @override
  State<BeginnerPage> createState() => _BeginnerPageState();
}

class _Topic {
  final String emoji;
  final String title;
  final Color background;
  final Color edge;

  const _Topic(this.emoji, this.title, this.background, this.edge);
}

class _BeginnerPageState extends State<BeginnerPage> {
  static const Color _cream = Color(0xFFFFF8EC);
  static const Color _levelColor = Color(0xFF4CAF50);
  static const Color _levelDark = Color(0xFF2E7D32);
  static const Color _dinoColor = Color(0xFF8BD17C);

  static const List<_Topic> _topics = [
    _Topic('🔤', 'Alphabets', Color(0xFFFFE0E6), Color(0xFFF48FB1)),
    _Topic('🔢', 'Numbers', Color(0xFFE3F2FD), Color(0xFF90CAF9)),
    _Topic('🎨', 'Colors', Color(0xFFFFF3D6), Color(0xFFFFCC80)),
    _Topic('🐾', 'Animals', Color(0xFFE8F5E9), Color(0xFFA5D6A7)),
    _Topic('🍎', 'Fruits', Color(0xFFFFEBEE), Color(0xFFEF9A9A)),
    _Topic('🖐️', 'Body Parts', Color(0xFFF3E5F5), Color(0xFFCE93D8)),
    _Topic('👕', 'Clothes', Color(0xFFE0F7FA), Color(0xFF80DEEA)),
    _Topic('🚗', 'Vehicles', Color(0xFFFFF8E1), Color(0xFFFFE082)),
  ];

  void _openTopic(_Topic topic) {
    final Widget page;

    if (topic.title == 'Alphabets') {
      page = const PracticeAlphabetsPage();
    } else if (topic.title == 'Numbers') {
      page = const PracticeNumbers1To10Page();
    } else {
      // The other topics get their practice words from the AI backend.
      page = AiPracticePage(
        level: 'beginner',
        levelLabel: 'Beginner',
        topic: topic.title,
        topicEmoji: topic.emoji,
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          // Soft coloured circles in the background
          Positioned(top: -50, right: -50, child: _buildBlob(170, const Color(0xFFDDF5E3))),
          Positioned(top: 420, left: -80, child: _buildBlob(160, const Color(0xFFFFE0F0))),
          Positioned(bottom: 60, right: -60, child: _buildBlob(170, const Color(0xFFE3EEFF))),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  _buildDinoCard(),
                  const SizedBox(height: 24),
                  const Text(
                    'What do you want to learn? 🌟',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF6B4C7A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.15,
                    children: [for (final topic in _topics) _buildTopicTile(topic)],
                  ),
                  const SizedBox(height: 20),
                  _buildTipCard(),
                ],
              ),
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

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _levelColor, width: 2.5),
              boxShadow: const [BoxShadow(color: _levelDark, offset: Offset(0, 3))],
            ),
            child: const Icon(Icons.arrow_back_rounded, color: _levelDark),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _levelColor,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _levelDark, offset: Offset(0, 3))],
          ),
          child: const Text(
            'A',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Beginner',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _levelDark),
        ),
      ],
    );
  }

  Widget _buildDinoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF81C784), _levelColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(color: _levelDark, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            height: 120,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: const DinoMascot(color: _dinoColor, size: 104),
          ),
          const SizedBox(width: 8),
          // Speech bubble
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hi! I'm Dino! 👋",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _levelDark),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Let's learn our first words together!",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5D4E6D)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicTile(_Topic topic) {
    return GestureDetector(
      onTap: () => _openTopic(topic),
      child: Container(
        decoration: BoxDecoration(
          color: topic.background,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [BoxShadow(color: topic.edge, offset: const Offset(0, 6))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Text(topic.emoji, style: const TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 8),
            Text(
              topic.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF4A3B57),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFCC80), width: 2),
      ),
      child: const Row(
        children: [
          Text('💡', style: TextStyle(fontSize: 26)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Listen first, then repeat. It's okay to make mistakes!",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8B6914)),
            ),
          ),
        ],
      ),
    );
  }
}
