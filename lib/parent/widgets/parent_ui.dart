import 'package:flutter/material.dart';
import 'package:talkiepal/parent/parent_home_screen.dart';
import 'package:talkiepal/parent/parent_profile_screen.dart';
import 'package:talkiepal/parent/parent_progress_screen.dart';
import 'package:talkiepal/parent/therapist_screen.dart';
import 'package:talkiepal/services/progress_store.dart';

/// Colours of the parent area.
class ParentColors {
  static const Color background = Color(0xFFF7F4F9);
  static const Color purple = Color(0xFF7E57A6);
  static const Color purpleDark = Color(0xFF5E3C85);
  static const Color purpleLight = Color(0xFFF1EAF7);
  static const Color yellow = Color(0xFFFFE27A);
  static const Color yellowLight = Color(0xFFFFF6D6);
  static const Color ink = Color(0xFF2E2538);
  static const Color soft = Color(0xFF7B7186);
  static const Color line = Color(0xFFECE6F1);
  static const Color muted = Color(0xFFB8AFC2);
}

/// The tabs in the parent bottom menu.
enum ParentTab { home, progress, therapist, profile }

/// Route name of the parent Home page, so the menu can go back to it.
const String parentHomeRouteName = 'parent_home';

/// Opens a tab of the parent menu from [from]. Home goes back to the Home
/// page that is already open; the other tabs replace the current tab page
/// (or open on top of Home), so Back always returns to Home.
void openParentTab(BuildContext context, ParentTab tab, {required ParentTab from}) {
  if (tab == from) return;
  if (tab == ParentTab.home) {
    Navigator.popUntil(context, (route) => route.settings.name == parentHomeRouteName || route.isFirst);
    return;
  }
  final Widget page = switch (tab) {
    ParentTab.progress => const ParentProgressScreen(),
    ParentTab.therapist => const TherapistScreen(),
    _ => const ParentProfileScreen(),
  };
  final route = MaterialPageRoute(builder: (_) => page);
  if (from == ParentTab.home) {
    Navigator.push(context, route);
  } else {
    Navigator.pushReplacement(context, route);
  }
}

/// Opens the parent Home page, named so the menu can find it again.
Route<void> parentHomeRoute() => MaterialPageRoute(
  settings: const RouteSettings(name: parentHomeRouteName),
  builder: (_) => const ParentHomeScreen(),
);

/// Rounded, floating bottom menu on every parent page, like the kids one.
class ParentBottomNav extends StatelessWidget {
  final ParentTab selected;

  const ParentBottomNav({super.key, required this.selected});

  static const List<(ParentTab, IconData, String)> _items = [
    (ParentTab.home, Icons.home_rounded, 'Home'),
    (ParentTab.progress, Icons.insights_rounded, 'Progress'),
    (ParentTab.therapist, Icons.medical_services_rounded, 'Therapist'),
    (ParentTab.profile, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Color(0x222E2538), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Row(
          children: [
            for (final (tab, icon, label) in _items)
              // The selected tab gets more room; its label shrinks on small phones.
              Flexible(
                flex: tab == selected ? 3 : 1,
                child: GestureDetector(
                  onTap: () => openParentTab(context, tab, from: selected),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: tab == selected ? 14 : 6, vertical: 9),
                      decoration: BoxDecoration(
                        color: tab == selected ? ParentColors.purpleLight : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: tab == selected ? ParentColors.purple : ParentColors.muted, size: 25),
                          if (tab == selected) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: ParentColors.purple,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A parent page: purple header, scrolling content and, for tab pages,
/// the bottom menu.
class ParentPage extends StatelessWidget {
  final Widget header;
  final List<Widget> children;

  /// The tab to show as selected; null hides the menu (e.g. detail pages).
  final ParentTab? tab;

  /// Something fixed above the menu, e.g. the chat box.
  final Widget? bottom;

  /// Content that is not scrolled by the page, e.g. a chat list.
  final Widget? body;

  const ParentPage({super.key, required this.header, this.children = const [], this.tab, this.bottom, this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ParentColors.background,
      body: Column(
        children: [
          Expanded(
            child: body != null
                ? Column(
                    children: [
                      header,
                      Expanded(child: body!),
                    ],
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(children: [header, ...children]),
                  ),
          ),
          ?bottom,
          if (tab != null) ParentBottomNav(selected: tab!),
        ],
      ),
    );
  }
}

/// Purple header with rounded bottom corners, used on every parent page.
class ParentHeader extends StatelessWidget {
  final String? title;

  /// Used instead of [title], e.g. a greeting.
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? trailing;

  /// Shown under the title, e.g. the child picker.
  final Widget? below;

  /// Shows a back arrow.
  final bool back;

  const ParentHeader({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.trailing,
    this.below,
    this.back = false,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(back ? 8 : 20, top + 16, 20, 18),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8E68B8), ParentColors.purpleDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (back)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              Expanded(
                child:
                    titleWidget ??
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title ?? '',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white70),
                          ),
                      ],
                    ),
              ),
              ?trailing,
            ],
          ),
          if (below != null) ...[
            const SizedBox(height: 14),
            Padding(
              padding: EdgeInsets.only(left: back ? 12 : 0),
              child: below!,
            ),
          ],
        ],
      ),
    );
  }
}

/// White card with a thin border and a soft shadow.
class ParentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;

  const ParentCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ParentColors.line),
        boxShadow: const [BoxShadow(color: Color(0x0D2E2538), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }
}

/// Icon in a softly coloured rounded square.
class ParentIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const ParentIconBox(this.icon, this.color, {super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}

/// Title of a card, with an optional icon and action on the right.
class ParentSectionTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  final String? action;
  final VoidCallback? onAction;

  const ParentSectionTitle(this.text, {super.key, this.icon, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 18, color: ParentColors.purple), const SizedBox(width: 6)],
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: ParentColors.ink),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: ParentColors.purple),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small round button in the purple header, e.g. the bell.
class ParentHeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const ParentHeaderButton(this.icon, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

/// Child photo, or a friendly icon when there is none.
class ParentChildAvatar extends StatelessWidget {
  final ChildProfile child;
  final double radius;

  const ParentChildAvatar(this.child, {super.key, this.radius = 13});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: ParentColors.yellowLight,
      backgroundImage: child.photo != null ? MemoryImage(child.photo!) : null,
      child: child.photo == null
          ? Icon(Icons.child_care_rounded, size: radius * 1.15, color: ParentColors.purple)
          : null,
    );
  }
}

/// The parent's children as chips in the purple header; tap one to pick it.
class ParentChildPicker extends StatelessWidget {
  final List<ChildProfile> children;
  final String? selectedId;
  final void Function(ChildProfile child) onSelect;

  /// Shows a + button to add a child.
  final VoidCallback? onAdd;

  const ParentChildPicker({
    super.key,
    required this.children,
    required this.selectedId,
    required this.onSelect,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final child in children)
            GestureDetector(
              onTap: () => onSelect(child),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                decoration: BoxDecoration(
                  color: child.id == selectedId ? Colors.white : Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    ParentChildAvatar(child),
                    const SizedBox(width: 6),
                    Text(
                      child.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: child.id == selectedId ? ParentColors.purpleDark : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (onAdd != null)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}

/// Coloured pill, e.g. "58%" or "🔥 5 days".
class ParentPill extends StatelessWidget {
  final String text;
  final Color color;

  const ParentPill(this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 46),
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
