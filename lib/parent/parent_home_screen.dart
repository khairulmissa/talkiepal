import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'add_child_profile_screen.dart';
import 'parent_ai_chat_screen.dart';
import 'parent_profile_screen.dart';
import 'parent_progress_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  static const cream = Color(0xFFF5EFE8);
  static const yellow = Color(0xFFFFEFA8);
  static const purple = Color(0xFF8B5E9E);

  final FirebaseFirestore db = FirebaseFirestore.instance;
  String? selectedChildId;
  User? get user => FirebaseAuth.instance.currentUser;

  String _parentName(Map<String, dynamic>? data) {
    final fromDb = (data?['username'] ?? data?['name'] ?? '').toString().trim();
    if (fromDb.isNotEmpty) return fromDb;
    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;
    return user?.email?.split('@').first ?? 'Parent';
  }

  String _tipFor(String sound) {
    switch (sound.toUpperCase().replaceAll('/', '').trim()) {
      case 'S':
        return 'Practise the /s/ sound with words such as sun, sock and snake. Keep practice playful and short.';
      case 'R':
        return 'Try gentle /r/ practice with red, rain and rabbit. Praise each attempt.';
      case 'L':
        return 'Try /l/ words like lion, leaf and lamp. Model the sound without pressuring your child.';
      case 'TH':
        return 'Model the /th/ sound using think and thumb. Practise together in front of a mirror.';
      case 'SH':
        return 'Practise /sh/ with shoe, ship and sheep. Try making a quiet “shhh” sound together.';
      default:
        return 'Spend 5–10 minutes playing with sounds, naming pictures and praising your child’s efforts.';
    }
  }

  Future<void> _addChild() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const AddChildProfileScreen()),
    );
    if (!mounted || result == null) return;
    final childId = result['childId'];
    if (childId is String) setState(() => selectedChildId = childId);
    if (result['findTherapist'] == true) {
      // Connect this to your real Find Therapist screen once its class is available.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Child saved. Open the Therapist tab to find a therapist.'),
      ));
    }
  }

  Widget _card(Widget child) => Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F2F2),
      borderRadius: BorderRadius.circular(18),
    ),
    child: child,
  );

  Widget _heading(String title) => Text(title,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold));

  int? _childAge(Map<String, dynamic> data) {
    final birthday = data['birthDate'];
    if (birthday is Timestamp) {
      final birth = birthday.toDate();
      final now = DateTime.now();
      var age = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) age--;
      return age;
    }
    final age = data['age'];
    return age is int ? age : int.tryParse('$age');
  }

  Uint8List? _childPhotoBytes(Map<String, dynamic> data) {
    final encoded = data['photoBase64'];
    if (encoded is! String || encoded.isEmpty) return null;
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }

  Widget _childrenSection(String uid) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: db.collection('users').doc(uid).collection('children')
        .orderBy('createdAt').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _card(Text('Unable to load children: ${snapshot.error}'));
      }
      if (!snapshot.hasData) {
        return _card(const Center(child: CircularProgressIndicator()));
      }
      final children = snapshot.data!.docs;
      QueryDocumentSnapshot<Map<String, dynamic>>? selected;
      for (final child in children) {
        if (child.id == selectedChildId) selected = child;
      }
      if (selected == null && children.isNotEmpty) selected = children.first;
      final tip = _tipFor(selected?.data()['targetSound']?.toString() ?? '');

      return Column(children: [
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _heading('👶 My Children'),
          const SizedBox(height: 12),
          if (children.isEmpty)
            const Padding(padding: EdgeInsets.only(bottom: 12),
              child: Text('No children added yet.')),
          for (final child in children) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Builder(builder: (context) {
                final bytes = _childPhotoBytes(child.data());
                final legacyUrl = child.data()['photoUrl'];
                return CircleAvatar(
                  backgroundColor: yellow,
                  backgroundImage: bytes != null
                      ? MemoryImage(bytes)
                      : (legacyUrl is String && legacyUrl.isNotEmpty
                          ? NetworkImage(legacyUrl) : null),
                  child: bytes == null &&
                          (legacyUrl is! String || legacyUrl.isEmpty)
                      ? const Icon(Icons.child_care)
                      : null,
                );
              }),
              title: Text(child.data()['name']?.toString() ?? 'Child'),
              subtitle: Text('Age ${_childAge(child.data()) ?? '-'} · '
                  'Target ${child.data()['targetSound'] == null ? 'Not selected' : '/${child.data()['targetSound']}/'}'),
              trailing: Icon(selected?.id == child.id
                  ? Icons.check_circle : Icons.chevron_right,
                color: selected?.id == child.id ? purple : Colors.grey),
              onTap: () => setState(() => selectedChildId = child.id),
            ),
            const Divider(height: 1),
          ],
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: children.length >= 5 ? null : _addChild,
            icon: const Icon(Icons.add),
            label: Text(children.length >= 5
                ? 'Maximum 5 children' : 'Add child'),
          ),
        ])),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _heading('💡 Tips'),
          const SizedBox(height: 10),
          Text(tip, style: const TextStyle(fontSize: 13, height: 1.4)),
          const SizedBox(height: 8),
          const Text('General practice suggestion, not a diagnosis or personalised AI advice.',
            style: TextStyle(fontSize: 11, color: Colors.black54)),
        ])),
      ]);
    },
  );

  String _formatDate(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} · '
        '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  Widget _sessionsSection(String uid) => _card(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading('🗓️ Upcoming Sessions'),
      const SizedBox(height: 12),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // Filter and sort on-device to avoid the composite index required
        // by the previous parentId + scheduledAt Firestore query.
        stream: db.collection('sessions')
            .where('parentId', isEqualTo: uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Unable to load sessions. Please check Firestore permissions.');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final now = DateTime.now();
          final sessions = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            final date = data['scheduledAt'];
            final status = data['status']?.toString().toLowerCase();
            return date is Timestamp && !date.toDate().isBefore(now) &&
                status != 'cancelled' && status != 'completed';
          }).toList()
            ..sort((a, b) => (a.data()['scheduledAt'] as Timestamp)
                .compareTo(b.data()['scheduledAt'] as Timestamp));
          if (sessions.isEmpty) {
            return const Text('No upcoming therapy sessions booked.');
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final session in sessions.take(10)) ...[
              Text(_formatDate(
                  (session.data()['scheduledAt'] as Timestamp).toDate()),
                style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Therapist: ${session.data()['therapistName'] ?? 'To be assigned'}'),
              Text('Child: ${session.data()['childName'] ?? 'Not specified'}'),
              const Divider(),
            ],
          ]);
        },
      ),
    ],
  ));

  Widget _navItem(IconData icon, String title,
      {bool selected = false, VoidCallback? onTap}) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 27, color: selected ? purple : Colors.grey),
        Text(title, style: TextStyle(fontSize: 11,
          fontWeight: FontWeight.bold,
          color: selected ? purple : Colors.grey)),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final currentUser = user;
    if (currentUser == null) {
      return const Scaffold(body: Center(
        child: Text('Please sign in to view your dashboard.')));
    }
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(child: Column(children: [
        Expanded(child: SingleChildScrollView(child: Column(children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(color: yellow,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(25))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Image.asset('lib/assets/images/robot.png',
                width: 100, height: 100,
                errorBuilder: (_, __, ___) => const Icon(Icons.android, size: 100)),
              const SizedBox(width: 12),
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ParentAiChatScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5C7),
                    border: Border.all(color: Colors.black87, width: 1.5),
                    borderRadius: BorderRadius.circular(24)),
                  child: const Text('Free Talk (AI)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Image.asset('lib/assets/images/logo.png',
            width: 300, height: 150, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.error, size: 100)),
          const Divider(thickness: 1),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: db.collection('users').doc(currentUser.uid).snapshots(),
            builder: (context, snapshot) => _card(Row(children: [
              const Text('👋', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello, ${_parentName(snapshot.data?.data())}',
                    style: const TextStyle(fontSize: 24,
                      fontWeight: FontWeight.bold)),
                  const Text('Welcome back!'),
                  if (snapshot.hasError)
                    const Text('Profile unavailable; showing account name.',
                      style: TextStyle(fontSize: 11, color: Colors.red)),
                ],
              )),
            ])),
          ),
          _childrenSection(currentUser.uid),
          _sessionsSection(currentUser.uid),
          const SizedBox(height: 20),
        ]))),
        Container(
          height: 68,
          color: Colors.white,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home, 'Home', selected: true),
              _navItem(Icons.bar_chart, 'Progress', onTap: () => ParentProgressScreen.open(context)),
              _navItem(Icons.medical_services, 'Therapist'),
              _navItem(Icons.person, 'Profile', onTap: () =>
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ParentProfileScreen()))),
            ],
          ),
        ),
      ])),
    );
  }
}
