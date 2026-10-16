import 'package:flutter/material.dart';
import 'package:talkiepal/widgets/dino_mascot.dart';

/// One topic tile on a level menu.
class LevelTopic {
  final String emoji;
  final String title;
  final void Function(BuildContext context) onTap;

  const LevelTopic({required this.emoji, required this.title, required this.onTap});
}

/// A group of topic tiles, with an optional heading (e.g. "Level 1").
class LevelSection {
  final String? heading;
  final List<LevelTopic> topics;

  const LevelSection({this.heading, required this.topics});
}

/// Colours that make each level look different.
class LevelTheme {
  final String letter;
  final String title;
  final Color color;
  final Color darkColor;
  final Color lightColor;
  final Color dinoColor;

  const LevelTheme({
    required this.letter,
    required this.title,
    required this.color,
    required this.darkColor,
    required this.lightColor,
    required this.dinoColor,
  });
}

/// Shared dino-themed menu used by every level page.
class LevelMenuPage extends StatelessWidget {
  final LevelTheme theme;
  final String dinoMessage;
  final String question;
  final List<LevelSection> sections;
  final String tip;

  const LevelMenuPage({
    super.key,
    required this.theme,
    required this.dinoMessage,
    required this.sections,
    this.question = 'What do you want to learn? 🌟',
    this.tip = "Listen first, then repeat. It's okay to make mistakes!",
  });

  static const Color _cream = Color(0xFFFFF8EC);
  static const Color _purple = Color(0xFF6B4C7A);

  // Pastel tile colours: [background, bottom edge].
  static const List<List<Color>> _tileColors = [
    [Color(0xFFFFE0E6), Color(0xFFF48FB1)],
    [Color(0xFFE3F2FD), Color(0xFF90CAF9)],
    [Color(0xFFFFF3D6), Color(0xFFFFCC80)],
    [Color(0xFFE8F5E9), Color(0xFFA5D6A7)],
    [Color(0xFFFFEBEE), Color(0xFFEF9A9A)],
    [Color(0xFFF3E5F5), Color(0xFFCE93D8)],
    [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
    [Color(0xFFFFF8E1), Color(0xFFFFE082)],
  ];

  @override
  Widget build(BuildContext context) {
    var tileIndex = 0;

    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          // Soft coloured circles in the background
          Positioned(top: -50, right: -50, child: _buildBlob(170, theme.lightColor.withValues(alpha: 0.35))),
          Positioned(top: 420, left: -80, child: _buildBlob(160, const Color(0xFFFFE0F0))),
          Positioned(bottom: 60, right: -60, child: _buildBlob(170, const Color(0xFFE3EEFF))),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 18),
                  _buildDinoCard(),
                  const SizedBox(height: 24),
                  Text(
                    question,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _purple),
                  ),
                  for (final section in sections) ...[
                    if (section.heading != null) ...[
                      const SizedBox(height: 18),
                      _buildSectionHeading(section.heading!),
                    ],
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.15,
                      children: [
                        for (final topic in section.topics)
                          _buildTopicTile(context, topic, _tileColors[tileIndex++ % _tileColors.length]),
                      ],
                    ),
                  ],
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

  Widget _buildHeader(BuildContext context) {
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
              border: Border.all(color: theme.color, width: 2.5),
              boxShadow: [BoxShadow(color: theme.darkColor, offset: const Offset(0, 3))],
            ),
            child: Icon(Icons.arrow_back_rounded, color: theme.darkColor),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: theme.darkColor, offset: const Offset(0, 3))],
          ),
          child: Text(
            theme.letter,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            theme.title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: theme.darkColor),
          ),
        ),
      ],
    );
  }

  Widget _buildDinoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.lightColor, theme.color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [BoxShadow(color: theme.darkColor, offset: const Offset(0, 6))],
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
            child: DinoMascot(color: theme.dinoColor, size: 104),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hi! I'm Dino! 👋",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: theme.darkColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dinoMessage,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5D4E6D)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String heading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: theme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: theme.darkColor, offset: const Offset(0, 3))],
      ),
      child: Text(
        heading,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
      ),
    );
  }

  Widget _buildTopicTile(BuildContext context, LevelTopic topic, List<Color> colors) {
    return GestureDetector(
      onTap: () => topic.onTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: colors[0],
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [BoxShadow(color: colors[1], offset: const Offset(0, 6))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Text(topic.emoji, style: const TextStyle(fontSize: 34)),
            ),
            const SizedBox(height: 8),
            Text(
              topic.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF4A3B57),
                height: 1.15,
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
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF8B6914)),
            ),
          ),
        ],
      ),
    );
  }
}
