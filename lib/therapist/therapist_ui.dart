import 'package:flutter/material.dart';

/// Shared TalkiePal visual system for every Therapist Mode page.
class TherapistColors {
  static const cream = Color(0xFFFFFBF4);
  static const background = Color(0xFFF8F6FA);
  static const purple = Color(0xFF8256A8);
  static const deepPurple = Color(0xFF65408B);
  static const yellow = Color(0xFFFFE18A);
  static const text = Color(0xFF352D3D);
  static const muted = Color(0xFF837A8B);
  static const border = Color(0xFFECE7EF);
}

class TherapistCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  const TherapistCard({super.key, required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: TherapistColors.border.withOpacity(.7)),
      boxShadow: const [BoxShadow(color: Color(0x0B3D2852), blurRadius: 16, offset: Offset(0, 5))],
    ),
    child: child,
  );
}

class TherapistHeader extends StatelessWidget {
  final String name;
  final VoidCallback? onProfile;
  final VoidCallback? onNotification;
  const TherapistHeader({super.key, required this.name, this.onProfile, this.onNotification});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF966ABB), Color(0xFF65408B)],
        begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(27)),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_greeting(), style: const TextStyle(color: Color(0xFFEDE0F5), fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        const Text('Helping little voices grow ✨', style: TextStyle(color: Color(0xFFF0E3F7), fontSize: 12)),
      ])),
      IconButton(onPressed: onNotification, icon: const Icon(Icons.notifications_none_rounded, color: Colors.white)),
      GestureDetector(onTap: onProfile,
        child: CircleAvatar(radius: 20, backgroundColor: const Color(0xFFFFE17B),
          child: Text(name.trim().isEmpty ? 'T' : name.trim()[0].toUpperCase(),
            style: const TextStyle(color: TherapistColors.deepPurple, fontWeight: FontWeight.w800)))),
    ]),
  );
}

class TherapistSectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const TherapistSectionTitle({super.key, required this.title, this.onSeeAll});
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: TherapistColors.text))),
    if (onSeeAll != null) TextButton(onPressed: onSeeAll,
      child: const Text('See all', style: TextStyle(color: TherapistColors.purple))),
  ]);
}

class TherapistShortcut extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBackground;
  final VoidCallback? onTap;
  const TherapistShortcut({super.key, required this.title, required this.subtitle,
    required this.icon, required this.iconBackground, this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(17),
          border: Border.all(color: TherapistColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: iconBackground, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: TherapistColors.purple, size: 20)),
          const Spacer(),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: TherapistColors.text)),
          const SizedBox(height: 3),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: TherapistColors.muted)),
        ]),
      ),
    ),
  );
}

class TherapistBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const TherapistBottomNav({super.key, required this.selectedIndex, required this.onSelect});
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40),
          boxShadow: const [BoxShadow(color: Color(0x1B5B3C73), blurRadius: 20, offset: Offset(0, 5))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _item(0, Icons.home_rounded, 'Home'),
          _item(1, Icons.chat_bubble_outline_rounded, 'Parent Chat'),
          _item(2, Icons.people_alt_rounded, 'Patients'),
          _item(3, Icons.person_rounded, 'Profile'),
        ]),
      ),
    ),
  );

  Widget _item(int index, IconData icon, String title) {
    final active = selectedIndex == index;
    return InkWell(
      onTap: () => onSelect(index),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: active ? 13 : 10, vertical: 10),
        decoration: BoxDecoration(color: active ? const Color(0xFFF1E8F8) : Colors.transparent,
          borderRadius: BorderRadius.circular(28)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: active ? TherapistColors.purple : const Color(0xFFB7A9C1), size: 21),
          if (active) ...[
            const SizedBox(width: 5),
            Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: TherapistColors.purple)),
          ],
        ]),
      ),
    );
  }
}
