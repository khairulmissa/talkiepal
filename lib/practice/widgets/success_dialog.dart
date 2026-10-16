import 'dart:math';

import 'package:flutter/material.dart';

const Color _pink = Color(0xFFEC407A);
const Color _pinkDark = Color(0xFFC2185B);
const Color _pinkLight = Color(0xFFFFD6E8);
const Color _green = Color(0xFF2BB673);

const List<String> _titles = ['Great Job!', 'Awesome!', 'Well Done!', 'Super Star!', 'Amazing!'];

/// Cheerful popup shown when the child gets it right.
/// [detail] is optional extra text, e.g. the answer or a score.
Future<void> showSuccessDialog(
  BuildContext context, {
  required String nextLabel,
  required VoidCallback onNext,
  String? detail,
}) {
  final title = _titles[Random().nextInt(_titles.length)];

  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Success',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (dialogContext, _, _) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: _pinkLight, width: 7),
                boxShadow: [
                  BoxShadow(
                    color: _pink.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _BouncingEmoji(),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: _green,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '⭐ ⭐ ⭐ ⭐ ⭐',
                    style: TextStyle(fontSize: 24),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      detail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _pink,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _ChunkyButton(
                          label: 'TRY AGAIN',
                          filled: false,
                          onTap: () => Navigator.pop(dialogContext),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ChunkyButton(
                          label: nextLabel,
                          filled: true,
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

/// Big party emoji that pops in and gently wiggles.
class _BouncingEmoji extends StatefulWidget {
  const _BouncingEmoji();

  @override
  State<_BouncingEmoji> createState() => _BouncingEmojiState();
}

class _BouncingEmojiState extends State<_BouncingEmoji> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.translate(
          offset: Offset(0, -6 * t),
          child: Transform.rotate(angle: (t - 0.5) * 0.2, child: child),
        );
      },
      child: const Text('🎉', style: TextStyle(fontSize: 80)),
    );
  }
}

/// Rounded button with a darker bottom edge so it looks pressable.
class _ChunkyButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ChunkyButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

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
          boxShadow: [
            BoxShadow(
              color: filled ? _pinkDark : _pinkLight,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: filled ? Colors.white : _pink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
