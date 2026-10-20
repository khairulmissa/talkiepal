import 'package:flutter/material.dart';

const Color _pink = Color(0xFFEC407A);
const Color _pinkDark = Color(0xFFC2185B);
const Color _pinkLight = Color(0xFFFFD6E8);
const Color _soft = Color(0xFF7A6A85);

/// Score bands used everywhere: 85%+ great, 70-84% almost, below 70% practice.
class ScoreBand {
  static const int great = 85;
  static const int pass = 70;

  static const Color greatColor = Color(0xFF43A047);
  static const Color almostColor = Color(0xFFFFA000);
  static const Color lowColor = Color(0xFFE53935);

  static Color colorFor(int score) => score >= great ? greatColor : (score >= pass ? almostColor : lowColor);

  static Color lightColorFor(int score) => score >= great
      ? const Color(0xFFE8F5E9)
      : (score >= pass ? const Color(0xFFFFF3D6) : const Color(0xFFFFEBEE));

  /// 5 stars from 85%, 4 from 70%, then fewer.
  static int starsFor(int score) {
    if (score >= great) return 5;
    if (score >= pass) return 4;
    if (score >= 50) return 3;
    if (score >= 25) return 2;
    return 1;
  }
}

/// Popup after the child speaks: stars, the speaking score and what to do next.
/// TRY AGAIN and NEXT are always there; when the score is low, TRY AGAIN is
/// the main (filled) button.
Future<void> showScoreDialog(
  BuildContext context, {
  required int score,
  required String target,
  required List<String> heard,
  required String nextLabel,
  required VoidCallback onNext,
  VoidCallback? onTryAgain,
}) {
  final passed = score >= ScoreBand.pass;
  final heardNothing = heard.isEmpty;

  final String emoji;
  final String title;
  final String detail;
  final String hint;

  if (heardNothing) {
    emoji = '🙉';
    title = "I Can't Hear You!";
    detail = 'Hold SPEAK and say "$target" again';
    // Short words are the hardest for the phone to hear.
    hint = target.trim().contains(' ')
        ? 'Speak a little louder, close to the phone.'
        : 'Wait for the red button, then say it a little longer and louder.';
  } else if (score >= ScoreBand.great) {
    emoji = '🎉';
    title = 'Amazing!';
    detail = 'You said "$target"!';
    hint = 'Super clear! 🌟';
  } else if (passed) {
    emoji = '👍';
    title = 'Good Job!';
    detail = 'You said "$target"!';
    hint = 'Almost perfect. Try once more for 5 stars!';
  } else {
    emoji = '💪';
    title = 'Keep Trying!';
    detail = 'Let\'s say "$target" again';
    hint = 'Listen first, then say it slowly.';
  }

  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Score',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (dialogContext, _, _) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: _pinkLight, width: 7),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 68)),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: heardNothing ? _pink : ScoreBand.colorFor(score),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!heardNothing) ...[
                    _Stars(count: ScoreBand.starsFor(score)),
                    const SizedBox(height: 14),
                    ScoreBar(score: score),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    detail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _pink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _soft),
                  ),
                  if (!heardNothing) ...[
                    const SizedBox(height: 6),
                    // What the phone heard, for parents and therapists.
                    Text(
                      'I heard: "${heard.first}"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _soft),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _DialogButton(
                          label: 'TRY AGAIN',
                          filled: !passed,
                          onTap: () {
                            Navigator.pop(dialogContext);
                            onTryAgain?.call();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DialogButton(
                          label: nextLabel,
                          filled: passed,
                          onTap: () {
                            Navigator.pop(dialogContext);
                            onNext();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, animation, _, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

/// Bar with the speaking score, coloured by band.
class ScoreBar extends StatelessWidget {
  final int score;
  final String label;

  const ScoreBar({super.key, required this.score, this.label = 'SPEAKING SCORE'});

  @override
  Widget build(BuildContext context) {
    final color = ScoreBand.colorFor(score);

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _soft, letterSpacing: 1),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 16,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(color: const Color(0xFFEDE4F2), borderRadius: BorderRadius.circular(10)),
                child: FractionallySizedBox(
                  widthFactor: (score / 100).clamp(0.0, 1.0),
                  child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('$score%', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  final int count;

  const _Stars({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Opacity(opacity: i < count ? 1 : 0.22, child: const Text('⭐', style: TextStyle(fontSize: 30))),
      ],
    );
  }
}

/// Rounded button with a darker bottom edge so it looks pressable.
class _DialogButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _DialogButton({required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
