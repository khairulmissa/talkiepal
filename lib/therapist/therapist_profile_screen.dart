import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'edit_therapist_profile_screen.dart';
import 'therapist_dashboard.dart';

class TherapistProfileScreen extends StatelessWidget {
  const TherapistProfileScreen({super.key});

  static const cream = Color(0xFFFFFBF4);
  static const yellow = Color(0xFFF5E5A0);

  String _value(Map<String, dynamic> data, String key, [String fallback = 'Not provided']) {
    final value = (data[key] ?? '').toString().trim();
    return value.isEmpty ? fallback : value;
  }

  Future<String?> _photoUrl(Map<String, dynamic> data, String key, String bucket) async {
    final path = (data[key] ?? '').toString();
    if (path.isEmpty) return null;
    try {
      // Both buckets are private by default. Generate short-lived signed URLs.
      return await Supabase.instance.client.storage.from(bucket).createSignedUrl(path, 3600);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Please sign in.')));
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('Therapist Profile'),
        backgroundColor: cream,
        actions: [TextButton(onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const EditTherapistProfileScreen())),
          child: const Text('Edit', style: TextStyle(color: Colors.redAccent)))],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 3,
        selectedItemColor: const Color(0xFF8B5E9E),
        unselectedItemColor: Colors.black87,
        backgroundColor: const Color(0xFFD9D9D9),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const TherapistDashboard()),
              (route) => false,
            );
          } else if (index == 1 || index == 2) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(index == 1
                    ? 'Chat page is not connected yet.'
                    : 'Patients page is not connected yet.'),
              ),
            );
          }
          // index 3: already on Profile.
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Patients'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('therapists').doc(uid).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Unable to load profile: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!.data() ?? {};
          return ListView(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)),
                    child: const Text('⭐ Rating: Not yet available', style: TextStyle(fontSize: 11))),
                  const SizedBox(height: 24),
                  Text(_value(data, 'fullName', 'Therapist'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  Text(_value(data, 'specialization', 'Speech Therapist'), style: const TextStyle(fontSize: 12)),
                  Text(_value(data, 'hospital', 'Workplace not provided'), style: const TextStyle(fontSize: 11)),
                ])),
                FutureBuilder<String?>(
                  future: _photoUrl(data, 'profileImagePath', 'therapist-photos'),
                  builder: (context, imageSnap) => Container(
                    width: 138, height: 165, color: Colors.grey.shade200,
                    child: imageSnap.data == null
                      ? const Icon(Icons.person, size: 92, color: Colors.grey)
                      : Image.network(imageSnap.data!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 92)),
                  ),
                ),
              ]),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
              decoration: const BoxDecoration(color: yellow,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Doctor Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 16),
                Row(children: [
                  _metric(Icons.access_time, '${data['experienceYears'] ?? 0} Years', 'Experience'),
                  const SizedBox(width: 8),
                  _metric(Icons.people_alt_outlined, '—', 'Patients'),
                  const SizedBox(width: 8),
                  _metric(Icons.workspace_premium, '—', 'Award'),
                ]),
                const SizedBox(height: 22),
                const Text('About 📝', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 7),
                Container(width: double.infinity, padding: const EdgeInsets.all(12), color: Colors.white,
                  child: Text(_value(data, 'bio', 'No biography added yet.'))),
                const SizedBox(height: 22),
                const Text('Qualification 🎓', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(width: double.infinity, padding: const EdgeInsets.all(12), color: Colors.white,
                  child: Text(_value(data, 'qualification', 'No qualification added yet.'))),
                const SizedBox(height: 12),
                if ((data['certificatePath'] ?? '').toString().isNotEmpty)
                  FutureBuilder<String?>(future: _photoUrl(data, 'certificatePath', 'therapist-certificates'),
                    builder: (context, imageSnap) => imageSnap.data == null
                      ? const Text('Certificate image unavailable', style: TextStyle(fontSize: 12))
                      : Image.network(imageSnap.data!, height: 180, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Text('Unable to display certificate'))),
                const SizedBox(height: 22),
                Text('Availability: ${_value(data, 'availability', 'Not set')}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            ),
          ]);
        },
      ),
    );
  }

  Widget _metric(IconData icon, String value, String caption) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Column(children: [Icon(icon, size: 21, color: const Color(0xFF6C74D9)),
      const SizedBox(height: 5), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      Text(caption, style: const TextStyle(fontSize: 10, color: Colors.grey))]),
  ));
}
