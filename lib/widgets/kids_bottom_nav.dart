import 'package:flutter/material.dart';

/// The tabs in the kids bottom menu.
enum KidsTab { home, game, progress, profile }

/// Route name of the kids Home page opened from the profile screen.
const String kidsHomeRouteName = 'kids_home';

/// Goes back to the kids Home page that is already open, so the child's
/// name stays the same, instead of opening a new Home page.
void goToKidsHome(BuildContext context) {
  Navigator.popUntil(
    context,
    (route) => route.settings.name == kidsHomeRouteName || route.isFirst,
  );
}

/// Rounded, floating bottom menu used on every kids page.
/// [selected] is the current page (null on practice pages).
/// Each page decides what happens on tap through [onTap].
class KidsBottomNav extends StatelessWidget {
  final KidsTab? selected;
  final void Function(KidsTab tab) onTap;

  const KidsBottomNav({super.key, this.selected, required this.onTap});

  static const Color _selectedColor = Color(0xFF8E24AA);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildItem(KidsTab.home, Icons.home_rounded, 'Home'),
          _buildItem(KidsTab.game, Icons.sports_esports_rounded, 'Game'),
          _buildItem(KidsTab.progress, Icons.bar_chart_rounded, 'Progress'),
          _buildItem(KidsTab.profile, Icons.person_rounded, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildItem(KidsTab tab, IconData icon, String label) {
    final isSelected = tab == selected;

    return GestureDetector(
      onTap: () => onTap(tab),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3E5F5) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? _selectedColor : Colors.grey.shade400, size: 26),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900, color: _selectedColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
