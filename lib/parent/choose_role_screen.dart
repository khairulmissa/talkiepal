import 'package:flutter/material.dart';
import 'package:talkiepal/parent/widgets/parent_ui.dart';
import 'package:talkiepal/services/parent_store.dart';

import 'kids_profile_selection_screen.dart';
import 'login_screen.dart';
import 'widgets/entry_ui.dart';

/// After signing in: is a child or a parent using the app?
class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({super.key});

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  String name = '';

  @override
  void initState() {
    super.initState();
    ParentStore.instance
        .me()
        .then((me) {
          if (mounted) setState(() => name = me.name);
        })
        .catchError((Object e) {
          debugPrint('[ChooseRole] could not load name: $e');
        });
  }

  Future<void> _logOut() async {
    await ParentStore.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EntryColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Image.asset(EntryLogo.icon, height: 46),
                  const Spacer(),
                  GestureDetector(
                    onTap: _logOut,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: EntryColors.line),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 16, color: EntryColors.soft),
                          SizedBox(width: 5),
                          Text(
                            'Log out',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: EntryColors.soft),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                name.isEmpty ? 'Hello! 👋' : 'Hi $name! 👋',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: EntryColors.orange),
              ),
              const SizedBox(height: 2),
              const Text(
                'Who is using\nTalkiePal today?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: EntryColors.ink, height: 1.15),
              ),
              const SizedBox(height: 24),
              _RoleCard(
                title: 'I\'m a Kid',
                text: 'Practice words and play fun games with Dino',
                image: 'lib/assets/images/kids.png',
                colors: const [Color(0xFFFBE08A), EntryColors.yellow],
                edge: const Color(0xFFDDA92A),
                textColor: EntryColors.ink,
                onTap: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const KidsProfileSelectionScreen())),
              ),
              const SizedBox(height: 18),
              _RoleCard(
                title: 'I\'m a Parent',
                text: 'See progress, scores and get tips',
                image: 'lib/assets/images/parent.png',
                colors: const [Color(0xFF8ED0C7), EntryColors.teal],
                edge: const Color(0xFF3F8D85),
                textColor: Colors.white,
                onTap: () => Navigator.push(context, parentHomeRoute()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String text;
  final String image;
  final List<Color> colors;
  final Color edge;
  final Color textColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.text,
    required this.image,
    required this.colors,
    required this.edge,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 196,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 6))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 4,
              top: 10,
              bottom: 0,
              child: Image.asset(
                image,
                width: 165,
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
                errorBuilder: (_, _, _) => const SizedBox(width: 165),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 0, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 140,
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Start',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: EntryColors.ink),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 16, color: EntryColors.ink),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
