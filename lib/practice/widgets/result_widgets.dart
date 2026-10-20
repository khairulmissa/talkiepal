import 'package:flutter/material.dart';
import 'package:talkiepal/practice/widgets/practice_scaffold.dart';

// Shared by the results screens of practices and games.

const Color _pink = Color(0xFFEC407A);
const Color _pinkDark = Color(0xFFC2185B);
const Color _pinkLight = Color(0xFFFFD6E8);

/// White card with a thick pink border that holds a results screen.
class ResultCard extends StatelessWidget {
  final Widget child;

  const ResultCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: _pinkLight, width: 7),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// "📋 DETAILS FOR PARENTS & THERAPIST" line above the details.
class ResultDetailsTitle extends StatelessWidget {
  const ResultDetailsTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEDE4F2), width: 2)),
      ),
      child: const Text(
        '📋 DETAILS FOR PARENTS & THERAPIST',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: PracticeColors.soft, letterSpacing: 0.5),
      ),
    );
  }
}

class ResultStatBox extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const ResultStatBox({super.key, required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFFF7F2FA), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$emoji $value',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: PracticeColors.ink),
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: PracticeColors.soft),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultStars extends StatelessWidget {
  final int count;

  const ResultStars({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Opacity(
            opacity: i < count ? 1 : 0.22,
            child: const Text('⭐', style: TextStyle(fontSize: 34)),
          ),
      ],
    );
  }
}

class ResultButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const ResultButton({super.key, required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: filled ? _pink : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _pink, width: filled ? 0 : 2.5),
          boxShadow: [BoxShadow(color: filled ? _pinkDark : _pinkLight, offset: const Offset(0, 5))],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: filled ? Colors.white : _pink),
            ),
          ),
        ),
      ),
    );
  }
}
