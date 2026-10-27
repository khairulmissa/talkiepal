import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'edit_therapist_profile_screen.dart';
import 'therapist_dashboard.dart';
import 'therapist_schedule_screen.dart';
import 'therapist_parent_chat_screen.dart';
import 'therapist_patients_screen.dart';
import 'therapist_ui.dart';

/// Therapist profile styled with the shared TalkiePal Therapist UI system.
class TherapistProfileScreen extends StatelessWidget {
  const TherapistProfileScreen({super.key});

  String _value(Map<String, dynamic> data, String key,
      [String fallback = 'Not provided']) {
    final value = (data[key] ?? '').toString().trim();
    return value.isEmpty ? fallback : value;
  }

  Future<String?> _signedUrl(String path, String bucket) async {
    if (path.trim().isEmpty) return null;
    try {
      return await Supabase.instance.client.storage
          .from(bucket)
          .createSignedUrl(path, 3600);
    } catch (_) {
      return null;
    }
  }

  void _edit(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const EditTherapistProfileScreen()));
  }

  void _navigate(BuildContext context, int index) {
    if (index == 3) return;
    Widget destination;
    switch (index) {
      case 0:
        destination = const TherapistDashboard();
        break;
      case 1:
        destination = const TherapistParentChatScreen();
        break;
      case 2:
        destination = const TherapistPatientsScreen();
        break;
      default:
        return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Do you want to log out of TalkiePal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      // '/' should be your MaterialApp home/authentication entry point.
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to log out: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please sign in.')));
    }
    return Scaffold(
      backgroundColor: TherapistColors.cream,
      bottomNavigationBar: TherapistBottomNav(
          selectedIndex: 3, onSelect: (i) => _navigate(context, i)),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('therapists').doc(uid).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Unable to load profile: ${snap.error}'),
            ));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data() ?? <String, dynamic>{};
          final name = _value(data, 'fullName', 'Therapist');
          final photoPath = _value(data, 'profileImagePath', '');
          final certificatePath = _value(data, 'certificatePath', '');
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _profileHeader(context, name),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TherapistCard(child: Column(children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: 104,
                            height: 118,
                            child: _privateImage(photoPath, 'therapist-photos',
                                fallback: const ColoredBox(
                                  color: Color(0xFFF2EAF8),
                                  child: Icon(Icons.person_rounded,
                                      size: 65, color: TherapistColors.purple),
                                )),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF7EE),
                                borderRadius: BorderRadius.circular(20)),
                              child: const Text('Therapist Profile',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                                  color: Color(0xFF368553))),
                            ),
                            const SizedBox(height: 9),
                            Text(name, style: const TextStyle(fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: TherapistColors.text)),
                            const SizedBox(height: 4),
                            Text(_value(data, 'specialization', 'Speech Therapist'),
                                style: const TextStyle(fontSize: 12,
                                    color: TherapistColors.purple,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 7),
                            Row(children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 15, color: TherapistColors.muted),
                              const SizedBox(width: 3),
                              Expanded(child: Text(
                                _value(data, 'hospital', 'Workplace not provided'),
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11,
                                    color: TherapistColors.muted))),
                            ]),
                          ],
                        )),
                      ]),
                      const SizedBox(height: 15),
                      SizedBox(width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _edit(context),
                          icon: const Icon(Icons.edit_outlined, size: 17),
                          label: const Text('Edit Profile'),
                          style: FilledButton.styleFrom(
                            backgroundColor: TherapistColors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ])),
                    const SizedBox(height: 17),
                    TherapistCard(color: TherapistColors.yellow,
                      child: Row(children: [
                        _metric(Icons.workspace_premium_outlined,
                            '${data['experienceYears'] ?? 0} Years', 'Experience'),
                        _metric(Icons.verified_outlined, 'Speech', 'Specialist'),
                        _metric(Icons.star_outline_rounded, '—', 'Rating'),
                      ])),
                    const SizedBox(height: 22),
                    const TherapistSectionTitle(title: 'Professional Information'),
                    const SizedBox(height: 10),
                    _infoCard(Icons.description_outlined, 'About Me',
                        _value(data, 'bio', 'No biography added yet.')),
                    const SizedBox(height: 12),
                    _infoCard(Icons.school_outlined, 'Qualifications',
                        _value(data, 'qualification', 'No qualification added yet.')),
                    if (certificatePath.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      TherapistCard(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel(Icons.workspace_premium_outlined, 'Certificate'),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(width: double.infinity, height: 190,
                              child: _privateImage(certificatePath,
                                  'therapist-certificates',
                                  fallback: const Center(child:
                                      Text('Certificate image unavailable'))),
                            ),
                          ),
                        ],
                      )),
                    ],
                    const SizedBox(height: 22),
                    const TherapistSectionTitle(title: 'Availability'),
                    const SizedBox(height: 10),
                    TherapistCard(child: Row(children: [
                      Container(padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2EAF8),
                          borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.calendar_month_outlined,
                            color: TherapistColors.purple)),
                      const SizedBox(width: 12),
                      const Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Manage your schedule',
                              style: TextStyle(fontWeight: FontWeight.bold,
                                  color: TherapistColors.text)),
                          SizedBox(height: 3),
                          Text('Choose working hours and days off',
                              style: TextStyle(fontSize: 11,
                                  color: TherapistColors.muted)),
                        ],
                      )),
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TherapistScheduleScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 17, color: TherapistColors.purple),
                      ),
                    ])),
                     const SizedBox(height: 22),
                     SizedBox(
                       width: double.infinity,
                       child: OutlinedButton.icon(
                         onPressed: () => _logout(context),
                         icon: const Icon(Icons.logout_rounded),
                         label: const Text('Log Out'),
                         style: OutlinedButton.styleFrom(
                           foregroundColor: Colors.red.shade700,
                           side: BorderSide(color: Colors.red.shade200),
                           padding: const EdgeInsets.symmetric(vertical: 14),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(14),
                           ),
                         ),
                       ),
                     ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _profileHeader(BuildContext context, String name) => Container(
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(20,
        MediaQuery.paddingOf(context).top + 18, 20, 25),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF966ABB), Color(0xFF65408B)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(27)),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TALKIEPAL · THERAPIST MODE',
              style: TextStyle(color: Color(0xFFEDE0F5),
                  fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('My Profile', style: TextStyle(color: Colors.white,
              fontSize: 25, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text('Your professional space, $name',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFF0E3F7), fontSize: 12)),
        ],
      )),
      CircleAvatar(radius: 23,
        backgroundColor: const Color(0xFFFFE17B),
        child: Text(name.isEmpty ? 'T' : name[0].toUpperCase(),
          style: const TextStyle(fontSize: 19,
              fontWeight: FontWeight.bold, color: TherapistColors.deepPurple)),
      ),
    ]),
  );

  Widget _metric(IconData icon, String value, String label) => Expanded(
    child: Column(children: [
      Icon(icon, color: TherapistColors.purple, size: 23),
      const SizedBox(height: 7),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800,
              color: TherapistColors.text, fontSize: 13)),
      const SizedBox(height: 3),
      Text(label, style: const TextStyle(fontSize: 10,
          color: TherapistColors.muted)),
    ]),
  );

  Widget _sectionLabel(IconData icon, String title) => Row(children: [
    Container(padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFFF2EAF8),
          borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 19, color: TherapistColors.purple)),
    const SizedBox(width: 10),
    Text(title, style: const TextStyle(fontSize: 15,
        fontWeight: FontWeight.w800, color: TherapistColors.text)),
  ]);

  Widget _infoCard(IconData icon, String title, String content) =>
      TherapistCard(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(icon, title),
          const SizedBox(height: 13),
          Text(content, style: const TextStyle(
              color: TherapistColors.text, height: 1.5, fontSize: 13)),
        ],
      ));

  Widget _privateImage(String path, String bucket,
      {required Widget fallback}) {
    if (path.isEmpty) return fallback;
    return FutureBuilder<String?>(
      future: _signedUrl(path, bucket),
      builder: (context, snap) {
        if (snap.data == null) return fallback;
        return Image.network(snap.data!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback);
      },
    );
  }
}
