import 'package:flutter/material.dart';

import 'add_child_profile_screen.dart';
import '../main.dart';
import '../services/current_kid.dart';
import '../services/progress_store.dart';
import '../widgets/hello_dino.dart';
import '../widgets/kids_bottom_nav.dart';
import 'widgets/entry_ui.dart';

/// "Who is playing today?": the child taps their own profile. Profiles
/// belong to the signed-in parent's account.
class KidsProfileSelectionScreen extends StatefulWidget {
  const KidsProfileSelectionScreen({super.key});

  @override
  State<KidsProfileSelectionScreen> createState() => _KidsProfileSelectionScreenState();
}

class _KidsProfileSelectionScreenState extends State<KidsProfileSelectionScreen> {
  // Card colours, one per child: [background, bottom edge].
  static const List<List<Color>> _colors = [
    [Color(0xFFFBE08A), Color(0xFFDDA92A)],
    [Color(0xFFB5E3DC), Color(0xFF5FAFA6)],
    [Color(0xFFFFCBA8), Color(0xFFE8793A)],
    [Color(0xFFF8C8DC), Color(0xFFD9779F)],
    [Color(0xFFC9DDF9), Color(0xFF6E9BD8)],
  ];

  List<ChildProfile> children = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ProgressStore.instance.children();
      if (!mounted) return;
      setState(() {
        children = list;
        isLoading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Unable to load profiles: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _addChild() async {
    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(builder: (_) => const AddChildProfileScreen()),
    );
    if (!mounted) return;
    if (result is Map && result['findTherapist'] == true) {
      showEntryMessage(context, 'Child saved. Therapist search is available from the parent area.', error: false);
    }
    _load();
  }

  /// Dino says hello in the card's colour, then the kids Home opens.
  void _openChild(ChildProfile child, Color dinoColor) {
    CurrentKid.select(name: child.name, id: child.id, photo: child.photo);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HelloDinoScreen(
          name: child.name.trim(),
          color: dinoColor,
          next: () => PageRouteBuilder(
            settings: const RouteSettings(name: kidsHomeRouteName),
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, _, _) => HomePage(selectedKidName: child.name),
            transitionsBuilder: (_, animation, _, page) => FadeTransition(opacity: animation, child: page),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EntryColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: EntryColors.ink),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Image.asset(EntryLogo.icon, height: 46),
                  const SizedBox(width: 4),
                ],
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi there! 👋',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: EntryColors.orange),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Who is playing today?',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: EntryColors.ink, height: 1.15),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap your picture to start.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: EntryColors.soft),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator(color: EntryColors.orange)),
                )
              else if (error != null)
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                )
              else if (children.isEmpty)
                _NoProfiles(onAdd: _addChild)
              else
                LayoutBuilder(
                  builder: (context, constraints) => GridView.count(
                    crossAxisCount: constraints.maxWidth >= 620 ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.8,
                    children: [
                      for (var i = 0; i < children.length; i++)
                        _KidCard(
                          child: children[i],
                          colors: _colors[i % _colors.length],
                          onTap: () => _openChild(children[i], _colors[i % _colors.length][1]),
                        ),
                      if (children.length < 5) _AddCard(onTap: _addChild),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KidCard extends StatelessWidget {
  final ChildProfile child;
  final List<Color> colors;
  final VoidCallback onTap;

  const _KidCard({required this.child, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = child.name.trim();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
        decoration: BoxDecoration(
          color: colors[0],
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: colors[1], offset: const Offset(0, 6))],
        ),
        child: Column(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: ClipOval(
                    child: child.photo != null
                        ? Image.memory(
                            child.photo!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _Initial(name: name, color: colors[1]),
                          )
                        : _Initial(name: name, color: colors[1]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name.isEmpty ? 'Child' : name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: EntryColors.ink),
            ),
            if (child.age != null)
              Text(
                '${child.age} years old',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EntryColors.soft),
              ),
          ],
        ),
      ),
    );
  }
}

/// First letter of the name when there is no photo.
class _Initial extends StatelessWidget {
  final String name;
  final Color color;

  const _Initial({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            name.isEmpty ? '?' : name[0].toUpperCase(),
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: color),
          ),
        ),
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: EntryColors.line, width: 2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFFFF0DE),
              child: Icon(Icons.add_rounded, size: 34, color: EntryColors.orange),
            ),
            SizedBox(height: 10),
            Text(
              'Add child',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: EntryColors.ink),
            ),
            Text(
              'for parents',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: EntryColors.soft),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoProfiles extends StatelessWidget {
  final VoidCallback onAdd;

  const _NoProfiles({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: EntryColors.line, width: 1.5),
      ),
      child: Column(
        children: [
          const Text('🧒', style: TextStyle(fontSize: 54)),
          const SizedBox(height: 8),
          const Text(
            'No profiles yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: EntryColors.ink),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ask your parent to add your profile, then you can start playing!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: EntryColors.soft, height: 1.4),
          ),
          const SizedBox(height: 18),
          EntryButton(label: 'Add a child', onPressed: onAdd),
        ],
      ),
    );
  }
}
