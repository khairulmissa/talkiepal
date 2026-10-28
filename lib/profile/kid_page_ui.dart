import 'package:flutter/material.dart';

/// Colours of the kids Profile pages.
class KidColors {
  static const Color cream = Color(0xFFFFF8EC);
  static const Color plum = Color(0xFF8E5CD9);
  static const Color plumDark = Color(0xFF5E35B1);
  static const Color ink = Color(0xFF4A3B57);
  static const Color soft = Color(0xFF7A6A85);
}

/// Page opened from the kids Profile: cream background, back button and a title.
class KidSubPage extends StatelessWidget {
  final String emoji;
  final String title;
  final List<Widget> children;
  final Widget? bottom;

  const KidSubPage({super.key, required this.emoji, required this.title, required this.children, this.bottom});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KidColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: KidColors.plumDark, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: KidColors.plumDark),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: children,
              ),
            ),
            if (bottom != null) Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 16), child: bottom),
          ],
        ),
      ),
    );
  }
}

/// White rounded card used on the kids Profile pages.
class KidCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const KidCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0xFFE6DCEB), offset: Offset(0, 5))],
      ),
      child: child,
    );
  }
}

/// Big purple button with a darker bottom edge.
class KidButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  const KidButton({super.key, required this.label, required this.onPressed, this.busy = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: enabled ? KidColors.plum : const Color(0xFFC9B3E0),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: KidColors.plumDark, offset: Offset(0, 5))],
        ),
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
              )
            : Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
      ),
    );
  }
}
