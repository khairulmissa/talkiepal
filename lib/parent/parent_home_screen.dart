import 'parent_upcoming_appointments.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:talkiepal/practice/widgets/score_dialog.dart';
import 'package:talkiepal/progress_page.dart';
import 'package:talkiepal/services/parent_report.dart';
import 'package:talkiepal/services/parent_store.dart';
import 'package:talkiepal/services/progress_store.dart';

import 'add_child_profile_screen.dart';
import 'parent_ai_chat_screen.dart';
import 'parent_progress_screen.dart';
import 'widgets/therapist_feedback_report.dart';
import 'widgets/parent_ui.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  ParentInfo? parent;
  List<ChildProfile> children = [];
  ChildProfile? child;
  ParentReport? report;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? pick}) async {
    try {
      final results = await Future.wait([ParentStore.instance.me(), ProgressStore.instance.children()]);
      if (!mounted) return;
      final list = results[1] as List<ChildProfile>;
      setState(() {
        parent = results[0] as ParentInfo;
        children = list;
        error = null;
      });
      final picked = list.where((c) => c.id == (pick ?? child?.id)).firstOrNull ?? list.firstOrNull;
      if (picked != null) {
        await _open(picked);
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Unable to load your children: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _open(ChildProfile picked) async {
    setState(() {
      child = picked;
      report = null;
    });
    List<SessionRecord> sessions;
    try {
      sessions = await ProgressStore.instance.sessions(childId: picked.id);
    } catch (e) {
      debugPrint('[Parent] could not load sessions: $e');
      sessions = const [];
    }
    if (!mounted || child != picked) return;
    setState(() {
      report = ParentReport(sessions);
      isLoading = false;
    });
  }

  Future<void> _addChild() async {
    if (children.length >= 5) {
      _tell('You can add up to 5 children.');
      return;
    }
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddChildProfileScreen()),
    );
    if (!mounted || result == null) return;
    final childId = result['childId'];
    await _load(pick: childId is String ? childId : null);
    if (!mounted) return;
    if (result['findTherapist'] == true) openParentTab(context, ParentTab.therapist, from: ParentTab.home);
  }

  void _tell(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  static String _tipFor(String? sound) {
    switch (sound) {
      case 'S':
        return 'Practice the /s/ sound with words such as sun, sock and snake. Keep practice playful and short.';
      case 'R':
        return 'Try gentle /r/ practice with red, rain and rabbit. Praise each attempt.';
      case 'L':
        return 'Try /l/ words like lion, leaf and lamp. Model the sound without pressuring your child.';
      case 'TH':
        return 'Model the /th/ sound using think and thumb. Practice together in front of a mirror.';
      case 'SH':
        return 'Practice /sh/ with shoe, ship and sheep. Try making a quiet "shhh" sound together.';
      default:
        return 'Spend 5–10 minutes playing with sounds, naming pictures and praising your child\'s efforts.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = parent?.name ?? '';

    return ParentPage(
      tab: ParentTab.home,
      header: ParentHeader(
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
            Text(
              name.isEmpty ? 'Welcome 👋' : '$name 👋',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ],
        ),
        trailing: Row(
          children: [
            ParentHeaderButton(Icons.notifications_none_rounded, onTap: () => _tell('No new notifications.')),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => openParentTab(context, ParentTab.profile, from: ParentTab.home),
              child: _ParentHomePhoto(name: name),
            ),
          ],
        ),
        below: children.isEmpty && isLoading
            ? null
            : ParentChildPicker(children: children, selectedId: child?.id, onSelect: _open, onAdd: _addChild),
      ),
      children: [
        _FreeTalkCard(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentAiChatScreen())),
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator(color: ParentColors.purple)),
          )
        else if (error != null)
          ParentCard(
            child: Text(error!, style: const TextStyle(color: Colors.red)),
          )
        else if (child == null)
          _NoChildCard(onAdd: _addChild)
        else
          _ChildCard(child: child!, report: report),
        _buildActions(),
        _buildUpcoming(),
        ParentCard(
          color: ParentColors.yellowLight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child?.targetSound == null ? 'Practice tip' : 'Tip for /${child!.targetSound}/',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: ParentColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _tipFor(child?.targetSound),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: ParentColors.ink,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'General suggestion, not a diagnosis.',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: ParentColors.soft),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _generateReport() async {
    final selectedChild = child;
    if (selectedChild == null) {
      _tell('Please select a child first.');
      return;
    }

    try {
      // Reload sessions so the PDF includes the latest completed practices.
      final sessions = await ProgressStore.instance.sessions(
        childId: selectedChild.id,
      );
      if (!mounted) return;
      await generateChildProgressPdf(
        childId: selectedChild.id,
        childName: selectedChild.name,
        targetSound: selectedChild.targetSound,
        report: ParentReport(sessions),
      );
    } catch (e) {
      if (!mounted) return;
      _tell('Unable to generate progress report: $e');
    }
  }

  Widget _buildActions() {
    Widget action(IconData icon, String title, String sub, Color color, VoidCallback onTap) => Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ParentColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ParentIconBox(icon, color, size: 36),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: ParentColors.ink),
              ),
              Text(
                sub,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ParentColors.soft),
              ),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              action(
                Icons.insights_rounded,
                'Progress',
                'Scores & details',
                ParentColors.purple,
                () => openParentTab(context, ParentTab.progress, from: ParentTab.home),
              ),
              const SizedBox(width: 10),
              action(Icons.child_care_rounded, 'Children', 'Add a child', const Color(0xFF1E88E5), _addChild),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              action(
                Icons.medical_services_rounded,
                'Therapist',
                'Find & book',
                const Color(0xFF00897B),
                () => openParentTab(context, ParentTab.therapist, from: ParentTab.home),
              ),
              const SizedBox(width: 10),
              action(
                Icons.picture_as_pdf_rounded,
                'Report',
                'Generate PDF',
                const Color(0xFFF57C00),
                _generateReport,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcoming() {
    return ParentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ParentSectionTitle('Upcoming sessions', icon: Icons.event_rounded),
          const SizedBox(height: 8),
          ParentUpcomingAppointments(childId: child?.id),
        ],
      ),
    );
  }

  static String _sessionTime(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${d.day} ${months[d.month - 1]} ${d.year} · $hour:${d.minute.toString().padLeft(2, '0')} '
        '${d.hour >= 12 ? 'PM' : 'AM'}';
  }
}

/// Free Talk (AI): the first thing on Home.
class _FreeTalkCard extends StatelessWidget {
  final VoidCallback onTap;

  const _FreeTalkCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFE9A3), Color(0xFFFFD45C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x33F5B700), blurRadius: 14, offset: Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 34))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Free Talk (AI)',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ParentColors.ink),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Ask anything about your child\'s speech, any time.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5A4A2E)),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: ParentColors.ink, borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 15),
                        SizedBox(width: 6),
                        Text(
                          'Start chat',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
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

class _NoChildCard extends StatelessWidget {
  final VoidCallback onAdd;

  const _NoChildCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return ParentCard(
      child: Row(
        children: [
          const ParentIconBox(Icons.child_care_rounded, Color(0xFF1E88E5), size: 48),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add your child',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ParentColors.ink),
                ),
                Text(
                  'Create a profile to start practicing and see their progress.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ParentColors.soft),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_rounded, color: ParentColors.purple, size: 32),
          ),
        ],
      ),
    );
  }
}

/// The picked child's day at a glance, from their saved sessions.
class _ChildCard extends StatelessWidget {
  final ChildProfile child;
  final ParentReport? report;

  const _ChildCard({required this.child, required this.report});

  @override
  Widget build(BuildContext context) {
    final r = report;
    final now = DateTime.now();
    final today = r?.sessions.where((s) => DateUtils.isSameDay(s.finishedAt, now)).toList() ?? const [];
    final minutes = today.fold(Duration.zero, (sum, s) => sum + s.time).inMinutes;
    final week = r?.thisWeek;
    final streak = r == null ? 0 : ProgressData.fromSessions(r.sessions).dayStreak;
    final weak = r?.needsAttention.firstOrNull;

    Widget stat(String value, String label, {Color? color}) => Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color ?? ParentColors.ink),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: ParentColors.soft),
          ),
        ],
      ),
    );

    final details = [
      if (child.age != null) '${child.age} years',
      child.targetSound == null ? 'No target sound' : 'Target sound /${child.targetSound}/',
    ].join(' · ');

    return ParentCard(
      child: Column(
        children: [
          Row(
            children: [
              _HomeChildPhoto(child: child, radius: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ParentColors.ink),
                    ),
                    Text(
                      details,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ParentColors.soft),
                    ),
                  ],
                ),
              ),
              if (streak > 0) ParentPill('🔥 $streak ${streak == 1 ? 'day' : 'days'}', const Color(0xFFF57C00)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: ParentColors.line),
          ),
          if (r == null)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(color: ParentColors.purple),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                stat('${today.length}', 'sessions\ntoday'),
                stat(minutes < 1 && today.isNotEmpty ? '<1 min' : '$minutes min', 'practice\ntoday'),
                stat(
                  week?.speaking == null ? '—' : '${week!.speaking}%',
                  'speaking\nthis week',
                  color: week?.speaking == null ? null : ScoreBand.colorFor(week!.speaking!),
                ),
                stat(
                  week?.games == null ? '—' : '${week!.games}%',
                  'games\nthis week',
                  color: week?.games == null ? null : ScoreBand.colorFor(week!.games!),
                ),
              ],
            ),
          if (weak != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProgressDetailScreen(
                    report: r!.detail(level: weak.level, topic: weak.level == 'Game' ? weak.topic : null),
                    childName: child.name,
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.priority_high_rounded, color: ScoreBand.lowColor, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Needs attention: ${weak.label.split(' · ').last} (${weak.score}%)',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: ParentColors.ink),
                      ),
                    ),
                    const Text(
                      'View',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: ParentColors.purple),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


/// Reads the parent's private photo using their own authenticated session.
class _ParentHomePhoto extends StatelessWidget {
  final String name;
  const _ParentHomePhoto({required this.name});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    Widget fallback() => CircleAvatar(
      radius: 19,
      backgroundColor: ParentColors.yellow,
      child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ParentColors.purpleDark)),
    );
    if (uid == null) return fallback();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        final path = (snapshot.data?.data()?['parentPhotoPath'] ?? '').toString().trim();
        if (path.isEmpty) return fallback();
        return FutureBuilder<String>(
          key: ValueKey('parent-$path'),
          future: Supabase.instance.client.storage.from('parent-photos').createSignedUrl(path, 3600),
          builder: (context, signed) {
            if (!signed.hasData) return fallback();
            return CircleAvatar(
              radius: 19,
              backgroundColor: ParentColors.yellow,
              backgroundImage: NetworkImage(signed.data!),
              onBackgroundImageError: (_, __) {},
            );
          },
        );
      },
    );
  }
}

/// Shows the selected child's Supabase photo, with the existing avatar as fallback.
class _HomeChildPhoto extends StatelessWidget {
  final ChildProfile child;
  final double radius;
  const _HomeChildPhoto({required this.child, required this.radius});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    Widget fallback() => ParentChildAvatar(child, radius: radius);
    if (uid == null) return fallback();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      key: ValueKey('child-doc-${child.id}'),
      stream: FirebaseFirestore.instance.collection('users').doc(uid)
          .collection('children').doc(child.id).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final path = (data['childPhotoPath'] ?? '').toString().trim();
        if (path.isEmpty) return fallback();
        return FutureBuilder<String>(
          key: ValueKey('child-photo-$path'),
          future: Supabase.instance.client.storage.from('child-photos').createSignedUrl(path, 3600),
          builder: (context, signed) {
            if (!signed.hasData) return fallback();
            return CircleAvatar(
              radius: radius,
              backgroundColor: ParentColors.yellow,
              backgroundImage: NetworkImage(signed.data!),
              onBackgroundImageError: (_, __) {},
            );
          },
        );
      },
    );
  }
}
