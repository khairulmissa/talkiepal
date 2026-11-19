import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'therapist_ai_chat_screen.dart';
import 'therapist_parent_chat_screen.dart';
import 'therapist_patients_screen.dart';
import 'therapist_profile_screen.dart';
import 'therapist_schedule_screen.dart';
import 'therapist_ui.dart';

const String kTherapistDashboardApiBaseUrl = 'http://192.168.0.139:8000';

class _DashboardChildPhoto extends StatefulWidget {
  final String parentId;
  final String childId;
  const _DashboardChildPhoto({required this.parentId, required this.childId});

  @override
  State<_DashboardChildPhoto> createState() => _DashboardChildPhotoState();
}

class _DashboardChildPhotoState extends State<_DashboardChildPhoto> {
  late Future<String?> _url;

  @override
  void initState() {
    super.initState();
    _url = _load();
  }

  @override
  void didUpdateWidget(covariant _DashboardChildPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parentId != widget.parentId || oldWidget.childId != widget.childId) {
      _url = _load();
    }
  }

  Future<String?> _load() async {
    if (widget.parentId.isEmpty || widget.childId.isEmpty) return null;
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) return null;
    final client = HttpClient();
    try {
      final uri = Uri.parse('$kTherapistDashboardApiBaseUrl/therapist/parents/'
          '${Uri.encodeComponent(widget.parentId)}/children/'
          '${Uri.encodeComponent(widget.childId)}/photo');
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode != 200) {
        debugPrint('Dashboard child photo HTTP ${response.statusCode}: $body');
        return null;
      }
      final data = jsonDecode(body);
      final url = data is Map ? data['url'] : null;
      return url is String && url.startsWith('https://') ? url : null;
    } catch (error) {
      debugPrint('Dashboard child photo error: $error');
      return null;
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _url,
      builder: (context, snapshot) => CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFFFF1C9),
        backgroundImage: snapshot.data != null ? NetworkImage(snapshot.data!) : null,
        onBackgroundImageError: snapshot.data != null
            ? (error, stack) => debugPrint('Dashboard child image error: $error')
            : null,
        child: snapshot.data == null
            ? const Icon(Icons.child_care_rounded, color: TherapistColors.purple)
            : null,
      ),
    );
  }
}



/// Therapist dashboard backed by the collections currently used in TalkiePal:
/// chats (therapistId) and appointments (therapistId).
/// A chat is a temporary patient-list source, NOT proof of clinical assignment.
class TherapistDashboard extends StatelessWidget {
  const TherapistDashboard({super.key});

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
        if (accountSnapshot.hasError) {
          return _notice('Unable to load therapist account. Check Firestore permissions.');
        }
        if (!accountSnapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final account = accountSnapshot.data!.data();
        final role = (account?['role'] ?? '').toString().trim().toLowerCase();
        final status = (account?['verificationStatus'] ?? 'pending')
            .toString().trim().toLowerCase();
        final isActive = account?['isActive'] == true;
        final accountStatus = (account?['accountStatus'] ?? 'active')
            .toString().trim().toLowerCase();

        if (role != 'therapist') {
          return _notice('This account is not registered as a therapist.');
        }
        if (!isActive || accountStatus == 'suspended') {
          return _notice('Therapist account is inactive or suspended.');
        }
        if (status != 'pending' && status != 'verified') {
          return _notice('Therapist account status is unavailable.');
        }
        if (status == 'pending') {
          return Scaffold(
            backgroundColor: TherapistColors.background,
            appBar: AppBar(
              title: const Text('Therapist Verification'),
              backgroundColor: TherapistColors.background,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_outlined,
                        size: 58, color: TherapistColors.purple),
                    const SizedBox(height: 16),
                    const Text('Your account is awaiting approval',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text(
                      'You can complete your professional profile and upload your certificate while Admin reviews your account.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _open(context, const TherapistProfileScreen()),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('View / Edit Profile'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: db.collection('therapists').doc(uid).snapshots(),
          builder: (context, profileSnapshot) {
            final profileName = (profileSnapshot.data?.data()?['fullName'] ?? '').toString().trim();
            final accountName = (account?['username'] ?? account?['name'] ?? '').toString().trim();
            final authName = user.displayName?.trim() ?? '';
            final name = profileName.isNotEmpty
                ? profileName
                : accountName.isNotEmpty
                    ? accountName
                    : authName.isNotEmpty
                        ? authName
                        : (user.email?.split('@').first ?? 'Therapist');
            return Scaffold(
              backgroundColor: TherapistColors.background,
              body: ListView(
                padding: EdgeInsets.zero,
                children: [
                  TherapistHeader(
                    name: name,
                    onProfile: () => _open(context, const TherapistProfileScreen()),
                    onNotification: () => _toast(context, 'Notifications will be connected next.'),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _aiCard(context),
                        const SizedBox(height: 13),
                        _overview(uid),
                        const SizedBox(height: 16),
                        const TherapistSectionTitle(title: 'Quick access'),
                        const SizedBox(height: 10),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.65,
                          children: [
                            TherapistShortcut(
                              title: 'Schedule',
                              subtitle: 'Manage availability',
                              icon: Icons.calendar_month_outlined,
                              iconBackground: const Color(0xFFF2E7FA),
                              onTap: () => _open(context, const TherapistScheduleScreen()),
                            ),
                            TherapistShortcut(
                              title: 'Patients',
                              subtitle: 'View assigned children',
                              icon: Icons.child_care_rounded,
                              iconBackground: const Color(0xFFE3F2FF),
                              onTap: () => _open(context, const TherapistPatientsScreen()),
                            ),
                            TherapistShortcut(
                              title: 'Tasks',
                              subtitle: 'Homework & activities',
                              icon: Icons.assignment_outlined,
                              iconBackground: const Color(0xFFE1F5EE),
                              onTap: () => _toast(context, 'Tasks page will be connected next.'),
                            ),
                            TherapistShortcut(
                              title: 'Profile',
                              subtitle: 'Edit your information',
                              icon: Icons.person_outline_rounded,
                              iconBackground: const Color(0xFFFFEEDD),
                              onTap: () => _open(context, const TherapistProfileScreen()),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const TherapistSectionTitle(title: 'Upcoming sessions'),
                        const SizedBox(height: 9),
                        _appointments(uid),
                        const SizedBox(height: 20),
                        TherapistSectionTitle(
                          title: 'My patients',
                          onSeeAll: () => _open(context, const TherapistPatientsScreen()),
                        ),
                        const SizedBox(height: 9),
                        _patients(uid),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: TherapistBottomNav(
                selectedIndex: 0,
                onSelect: (index) {
                  if (index == 1) _open(context, const TherapistParentChatScreen());
                  if (index == 2) _open(context, const TherapistPatientsScreen());
                  if (index == 3) _open(context, const TherapistProfileScreen());
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _notice(String message) => Scaffold(
        backgroundColor: TherapistColors.background,
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        )),
      );

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _aiCard(BuildContext context) => TherapistCard(
        color: TherapistColors.yellow,
        child: Row(children: [
          const CircleAvatar(
            radius: 29,
            backgroundColor: Colors.white,
            child: Icon(Icons.smart_toy_outlined, color: TherapistColors.purple, size: 31),
          ),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Free Talk (AI)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: TherapistColors.text)),
            const SizedBox(height: 3),
            const Text('Ask about speech activities and therapy suggestions.',
                style: TextStyle(fontSize: 11, color: TherapistColors.text)),
            const SizedBox(height: 9),
            FilledButton.icon(
              onPressed: () => _open(context, const TherapistAiChatScreen()),
              style: FilledButton.styleFrom(
                backgroundColor: TherapistColors.text,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                minimumSize: const Size(0, 32),
              ),
              icon: const Icon(Icons.chat_bubble, size: 14),
              label: const Text('Start chat', style: TextStyle(fontSize: 11)),
            ),
          ])),
        ]),
      );

  /// Chat-linked children are used until a dedicated trusted assignment index exists.
  /// Appointment and chat reads are isolated so one failing stream cannot hide everything.
  Widget _overview(String uid) {
    final db = FirebaseFirestore.instance;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: db.collection('chats').where('therapistId', isEqualTo: uid).snapshots(),
      builder: (context, chatsSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: db.collection('appointments').where('therapistId', isEqualTo: uid).snapshots(),
          builder: (context, appointmentsSnapshot) {
            final chatError = chatsSnapshot.hasError;
            final appointmentError = appointmentsSnapshot.hasError;
            if (!chatError && !appointmentError &&
                (!chatsSnapshot.hasData || !appointmentsSnapshot.hasData)) {
              return const TherapistCard(child: Center(child: CircularProgressIndicator()));
            }
            final patientKeys = <String>{};
            if (chatsSnapshot.hasData) {
              for (final doc in chatsSnapshot.data!.docs) {
                final d = doc.data();
                final parent = (d['parentId'] ?? '').toString();
                final child = (d['childId'] ?? '').toString();
                if (parent.isNotEmpty && child.isNotEmpty) patientKeys.add('$parent/$child');
              }
            }
            final now = DateTime.now();
            var today = 0;
            if (appointmentsSnapshot.hasData) {
              for (final doc in appointmentsSnapshot.data!.docs) {
                final d = doc.data();
                final timestamp = d['startAt'];
                if (timestamp is! Timestamp || d['status'] == 'cancelled') continue;
                final date = timestamp.toDate().toLocal();
                if (date.year == now.year && date.month == now.month && date.day == now.day) today++;
              }
            }
            return TherapistCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Practice overview',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 14),
                Row(children: [
                  _metric(chatError ? '—' : '${patientKeys.length}', 'patients'),
                  _metric(appointmentError ? '—' : '$today', 'sessions today'),
                  _metric('—', 'pending tasks'),
                  _metric('—', 'avg. progress'),
                ]),
                if (chatError || appointmentError) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Some statistics are unavailable. Check Firestore permissions.',
                    style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                  ),
                ],
              ]),
            );
          },
        );
      },
    );
  }

  Widget _metric(String value, String label) => Expanded(
        child: Column(children: [
          Text(value, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: TherapistColors.text)),
          const SizedBox(height: 5),
          Text(label, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: TherapistColors.muted)),
        ]),
      );

  Widget _appointments(String uid) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('therapistId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _empty('Unable to load appointments. Check Firestore rules and therapistId.');
          }
          if (!snapshot.hasData) {
            return const TherapistCard(child: Center(child: CircularProgressIndicator()));
          }
          final upcoming = snapshot.data!.docs.where((doc) {
            final d = doc.data();
            return d['startAt'] is Timestamp &&
                (d['startAt'] as Timestamp).toDate().isAfter(DateTime.now()) &&
                d['status'] != 'cancelled';
          }).toList()
            ..sort((a, b) => (a.data()['startAt'] as Timestamp)
                .compareTo(b.data()['startAt'] as Timestamp));
          if (upcoming.isEmpty) return _empty('No upcoming appointments yet.');
          return TherapistCard(
            child: Column(children: [
              for (final doc in upcoming.take(3))
                Builder(builder: (context) {
                  final d = doc.data();
                  final date = (d['startAt'] as Timestamp).toDate().toLocal();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _DashboardChildPhoto(
                      parentId: (d['parentId'] ?? d['parentUid'] ?? '').toString(),
                      childId: (d['childId'] ?? '').toString(),
                    ),
                    title: Text((d['childName'] ?? 'Therapy Session').toString(),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${date.day}/${date.month}/${date.year} • ${TimeOfDay.fromDateTime(date).format(context)}',
                      style: const TextStyle(fontSize: 12, color: TherapistColors.muted),
                    ),
                    trailing: const Icon(Icons.videocam_outlined, color: TherapistColors.purple),
                  );
                }),
            ]),
          );
        },
      );

  Widget _patients(String uid) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('therapistId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _empty('Unable to load patients. Check chat permissions.');
          if (!snapshot.hasData) {
            return const TherapistCard(child: Center(child: CircularProgressIndicator()));
          }
          final seen = <String>{};
          final patients = <Map<String, dynamic>>[];
          for (final doc in snapshot.data!.docs) {
            final d = doc.data();
            final parent = (d['parentId'] ?? '').toString();
            final child = (d['childId'] ?? '').toString();
            if (parent.isEmpty || child.isEmpty || !seen.add('$parent/$child')) continue;
            patients.add(d);
          }
          if (patients.isEmpty) return _empty('No chat-linked patients yet.');
          return TherapistCard(
            child: Column(children: [
              for (final d in patients.take(5))
                InkWell(
                  onTap: () => _showPatients(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      _DashboardChildPhoto(
                        parentId: (d['parentId'] ?? '').toString(),
                        childId: (d['childId'] ?? '').toString(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((d['childName'] ?? 'Child').toString(),
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text('Parent: ${(d['parentName'] ?? 'Not specified')}',
                              style: const TextStyle(fontSize: 11, color: TherapistColors.muted)),
                        ],
                      )),
                      const Icon(Icons.chevron_right, color: TherapistColors.purple),
                    ]),
                  ),
                ),
            ]),
          );
        },
      );

  Widget _empty(String message) => TherapistCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(message, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: TherapistColors.muted)),
        ),
      );

  void _showPatients(BuildContext context) =>
      _open(context, const TherapistPatientsScreen());
}