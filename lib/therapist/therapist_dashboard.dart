import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../parent/parent_ai_chat_screen.dart';
import 'therapist_profile_screen.dart';

/// Therapist dashboard shares the Parent AI chat page and visual assets.
class TherapistDashboard extends StatelessWidget {
  const TherapistDashboard({super.key});

  static const Color cream = Color(0xFFF5EFE8);
  static const Color purple = Color(0xFF8B5E9E);
  static const Color yellow = Color(0xFFFFEFA8);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in first.')));
    }
    final uid = user.uid;
    final db = FirebaseFirestore.instance;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: db.collection('users').doc(uid).snapshots(),
      builder: (context, accountSnapshot) {
        if (accountSnapshot.hasError) return _notice('Unable to load account permissions.');
        if (!accountSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final account = accountSnapshot.data!.data();
        if (account?['role'] != 'therapist' ||
            account?['isActive'] != true ||
            (account?['verificationStatus'] ?? '').toString().trim().toLowerCase() != 'verified') {
          return _notice('Therapist account is awaiting approval.');
        }
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: db.collection('therapists').doc(uid).snapshots(),
          builder: (context, profileSnapshot) {
            final profileName = (profileSnapshot.data?.data()?['fullName'] ?? '').toString().trim();
            final accountName = (account?['username'] ?? account?['name'] ?? '').toString().trim();
            final authName = user.displayName?.trim() ?? '';
            final name = profileName.isNotEmpty ? profileName : accountName.isNotEmpty ? accountName : authName.isNotEmpty ? authName : (user.email?.split('@').first ?? 'Therapist');
            return Scaffold(
              backgroundColor: cream,
              body: SafeArea(
                child: ListView(
                  children: [
                    _header(context),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _welcome(name),
                        const SizedBox(height: 18),
                        _stats(uid),
                        const SizedBox(height: 24),
                        _appointments(uid),
                        const SizedBox(height: 24),
                        _patients(uid),
                      ]),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: purple,
                unselectedItemColor: Colors.black54,
                backgroundColor: const Color(0xFFECECEC),
                onTap: (index) {
                  if (index == 0) return;
                  if (index == 3) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TherapistProfileScreen()));
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${['Home', 'Chat', 'Patients', 'Profile'][index]} page will be connected next.'),
                  ));
                },
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
                  BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Patients'),
                  BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _notice(String text) => Scaffold(
    backgroundColor: cream,
    body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(text, textAlign: TextAlign.center))),
  );

  Widget _header(BuildContext context) => Column(children: [
    Container(
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: purple,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset(
          'lib/assets/images/robot.png',
          width: 100,
          height: 100,
          errorBuilder: (_, __, ___) => const Icon(Icons.android, size: 100),
        ),
        const SizedBox(width: 12),
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ParentAiChatScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5E9E),
              border: Border.all(color: Colors.black87, width: 1.5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text('Free Talk (AI)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ),
      ]),
    ),
    const SizedBox(height: 12),
    Image.asset(
      'lib/assets/images/mylogo.png',
      width: 300,
      height: 150,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(Icons.error, size: 100),
    ),
    const Divider(thickness: 1),
  ]);

  Widget _welcome(String name) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(16)),
    child: Text('👋 Hello, $name\nWelcome back!', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
  );

  Widget _stats(String uid) {
    final db = FirebaseFirestore.instance;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('therapist_assignments').where('therapistUid', isEqualTo: uid).snapshots(),
      builder: (context, a) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('appointments').where('therapistUid', isEqualTo: uid).snapshots(),
        builder: (context, b) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: db.collection('therapy_tasks').where('therapistUid', isEqualTo: uid).snapshots(),
          builder: (context, c) {
            if (a.hasError || b.hasError || c.hasError) return const Text('Unable to load statistics. Check Firestore rules.');
            if (!a.hasData || !b.hasData || !c.hasData) return const Center(child: CircularProgressIndicator());
            final active = a.data!.docs.where((d) => d.data()['status'] == 'active').toList();
            final now = DateTime.now();
            final today = b.data!.docs.where((d) {
              final data = d.data();
              final t = data['startAt'];
              if (t is! Timestamp || data['status'] == 'cancelled') return false;
              final date = t.toDate().toLocal();
              return date.year == now.year && date.month == now.month && date.day == now.day;
            }).length;
            final pending = c.data!.docs.where((d) => d.data()['status'] == 'pending').length;
            final progress = active.map((d) => d.data()['progressPercent']).whereType<num>().toList();
            final average = progress.isEmpty ? '—' : '${(progress.fold<double>(0, (sum, p) => sum + p.toDouble()) / progress.length).round()}%';
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.65,
              children: [
                _stat('Patients', '${active.length}', Icons.people_outline, const Color(0xFFBCE6FF)),
                _stat('Today Session', '$today', Icons.calendar_month_outlined, const Color(0xFFFFF59D)),
                _stat('Task Pending', '$pending', Icons.assignment_outlined, const Color(0xFFFFD98E)),
                _stat('Average Progress', average, Icons.pie_chart_outline, const Color(0xFFFFC2D1)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)]),
    child: Row(children: [
      CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.black87)),
      const SizedBox(width: 8),
      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, maxLines: 2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ])),
    ]),
  );

  Widget _appointments(String uid) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance.collection('appointments').where('therapistUid', isEqualTo: uid).snapshots(),
    builder: (context, snapshot) {
      final upcoming = (snapshot.data?.docs ?? []).where((d) {
        final data = d.data();
        return data['startAt'] is Timestamp &&
            (data['startAt'] as Timestamp).toDate().isAfter(DateTime.now()) &&
            data['status'] != 'cancelled';
      }).toList()..sort((x, y) => (x.data()['startAt'] as Timestamp).compareTo(y.data()['startAt'] as Timestamp));
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Upcoming Appointment', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (snapshot.hasError) _empty('Unable to load appointments')
        else if (!snapshot.hasData) const Center(child: CircularProgressIndicator())
        else if (upcoming.isEmpty) _empty('No upcoming appointments yet')
        else Container(
          decoration: BoxDecoration(color: const Color(0xFF2B2B2B), borderRadius: BorderRadius.circular(16)),
          child: Column(children: upcoming.take(3).map((d) {
            final data = d.data();
            final date = (data['startAt'] as Timestamp).toDate().toLocal();
            return ListTile(
              leading: const CircleAvatar(backgroundColor: yellow, child: Icon(Icons.person, color: Colors.black87)),
              title: Text((data['childName'] ?? 'Therapy Session').toString(), style: const TextStyle(color: Colors.white)),
              subtitle: Text('${date.day}/${date.month}/${date.year} • ${TimeOfDay.fromDateTime(date).format(context)}', style: const TextStyle(color: Colors.white70)),
              trailing: const Icon(Icons.videocam_outlined, color: Colors.white),
            );
          }).toList()),
        ),
      ]);
    },
  );

  Widget _patients(String uid) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance.collection('therapist_assignments').where('therapistUid', isEqualTo: uid).snapshots(),
    builder: (context, snapshot) {
      final patients = (snapshot.data?.docs ?? []).where((d) => d.data()['status'] == 'active').take(5).toList();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Patient List', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (snapshot.hasError) _empty('Unable to load patients')
        else if (!snapshot.hasData) const Center(child: CircularProgressIndicator())
        else if (patients.isEmpty) _empty('No patients assigned yet')
        else ...patients.map((d) {
          final data = d.data();
          final progress = data['progressPercent'];
          return Card(color: Colors.white, child: ListTile(
            leading: const CircleAvatar(backgroundColor: yellow, child: Icon(Icons.child_care)),
            title: Text((data['childName'] ?? 'Child').toString()),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((data['speechProblem'] ?? 'Speech practice').toString()),
              if (progress is num) ...[
                const SizedBox(height: 6),
                LinearProgressIndicator(value: (progress.toDouble() / 100).clamp(0.0, 1.0), color: purple),
                Text('${progress.round()}% progress'),
              ],
            ]),
          ));
        }),
      ]);
    },
  );

  Widget _empty(String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
    child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
  );
}
