import 'package:flutter/material.dart';
import 'package:talkiepal/practice/widgets/practice_scaffold.dart';
import 'package:talkiepal/widgets/dino_mascot.dart';

/// Colours for one game.
class GameLook {
  final Color color;
  final Color darkColor;
  final Color lightColor;
  final Color edgeColor;
  final Color dinoColor;

  const GameLook(this.color, this.darkColor, this.lightColor, this.edgeColor, this.dinoColor);

  static const soundMatcher = GameLook(
      Color(0xFF1E88E5), Color(0xFF1565C0), Color(0xFFE3F2FD), Color(0xFF90CAF9), Color(0xFF7EC3F2));
  static const yesOrNo = GameLook(
      Color(0xFF43A047), Color(0xFF2E7D32), Color(0xFFE8F5E9), Color(0xFFA5D6A7), Color(0xFF8BD17C));
  static const minimalPairs = GameLook(
      Color(0xFFD81B60), Color(0xFFAD1457), Color(0xFFFFE0E6), Color(0xFFF48FB1), Color(0xFFE77BC3));
}

/// Full-screen layout for every game: header with stars, progress and
/// dino tip. No bottom menu, so the child can focus on the game.
class GameScaffold extends StatelessWidget {
  final GameLook look;
  final String title;
  final int stars;
  final int current;
  final int total;
  final String dinoTip;
  final bool isLoading;
  final String loadingText;
  final List<Widget> children;

  const GameScaffold({
    super.key,
    required this.look,
    required this.title,
    required this.stars,
    required this.current,
    required this.total,
    required this.dinoTip,
    required this.children,
    this.isLoading = false,
    this.loadingText = 'Getting the game ready... ✨',
  });

  static const Color _cream = Color(0xFFFFF8EC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          // Soft coloured circles in the background
          Positioned(top: -50, right: -50, child: _buildBlob(170, look.lightColor)),
          Positioned(top: 520, left: -80, child: _buildBlob(160, const Color(0xFFFFE0F0))),
          Positioned(bottom: 40, right: -60, child: _buildBlob(170, const Color(0xFFE3EEFF))),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 14),
                  if (!isLoading && total > 0) ...[
                    _buildProgress(),
                    const SizedBox(height: 14),
                  ],
                  _buildDinoTip(),
                  const SizedBox(height: 16),
                  if (isLoading) _buildLoadingCard() else ...children,
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
              border: Border.all(color: look.color, width: 2.5),
              boxShadow: [BoxShadow(color: look.edgeColor, offset: const Offset(0, 3))],
            ),
            child: Icon(Icons.arrow_back_rounded, color: look.color),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: look.color),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: look.edgeColor, offset: const Offset(0, 3))],
          ),
          child: Text(
            '⭐ $stars',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: PracticeColors.ink),
          ),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    return Row(
      children: [
        for (var i = 0; i < total; i++)
          Expanded(
            child: Container(
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i < current ? look.color : const Color(0xFFEDE4F2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        const SizedBox(width: 8),
        Text(
          '$current / $total',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: look.color),
        ),
      ],
    );
  }

  Widget _buildDinoTip() {
    return Row(
      children: [
        Container(
          width: 70,
          height: 70,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: look.lightColor, width: 3),
          ),
          child: DinoMascot(color: look.dinoColor, size: 60),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0xFFE6DCEB), offset: Offset(0, 4))],
            ),
            child: Text(
              dinoTip,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: PracticeColors.ink),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: look.color, width: 4),
        boxShadow: [BoxShadow(color: look.darkColor, offset: const Offset(0, 7))],
      ),
      child: Column(
        children: [
          CircularProgressIndicator(color: look.color),
          const SizedBox(height: 16),
          Text(
            loadingText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: PracticeColors.ink),
          ),
        ],
      ),
    );
  }
}
