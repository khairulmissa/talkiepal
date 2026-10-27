import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'parent_video_call_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talkiepal/services/progress_store.dart';
import 'widgets/parent_ui.dart';
import 'parent_therapist_chat_screen.dart';
import 'parent_book_appointment_screen.dart';
import 'parent_upcoming_appointments.dart';

class ParentTherapistScreen extends StatefulWidget {
  const ParentTherapistScreen({super.key});

  @override
  State<ParentTherapistScreen> createState() => _ParentTherapistScreenState();
}

class _ParentTherapistScreenState extends State<ParentTherapistScreen> {
  static const purple = ParentColors.purple;
  static const yellow = ParentColors.yellowLight;
  static const cream = ParentColors.background;
  final _search = TextEditingController();
  String _filter = 'All';
  bool _saving = false;
  String? _selectedChildId;
  late final Future<List<ChildProfile>> _childrenFuture;

  @override
  void initState() {
    super.initState();
    _childrenFuture = ProgressStore.instance.children();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  DocumentReference<Map<String, dynamic>>? get _childRef {
    final parentId = _uid;
    final childId = _selectedChildId;
    if (parentId == null || childId == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(parentId)
        .collection('children')
        .doc(childId);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _value(Map<String, dynamic> data, String field, String fallback) {
    final value = data[field]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  String _therapistValue(Map<String, dynamic> data, List<String> keys,
      String fallback) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  String _therapistName(Map<String, dynamic> t) =>
      _therapistValue(t, ['fullName', 'name', 'username'], 'Speech Therapist');

  String _therapistClinic(Map<String, dynamic> t) =>
      _therapistValue(t, ['hospital', 'clinicName'], 'Clinic not specified');

  String _therapistExperience(Map<String, dynamic> t) =>
      _therapistValue(t, ['experienceYears', 'yearsOfExperience'], 'Not provided');

  String? _photoUrl(Map<String, dynamic> data) {
    final path = (data['profileImagePath'] ?? data['photoUrl'] ?? '').toString().trim();
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('https://')) return path;
    return Supabase.instance.client.storage.from('therapist-photos').getPublicUrl(path);
  }

  Widget _avatar(Map<String, dynamic> data, {double size = 58}) {
    final url = _photoUrl(data);
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: size, height: size, color: const Color(0xFFF0EAF7),
        child: url == null
            ? const Icon(Icons.person, color: purple, size: 35)
            : Image.network(url, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person, color: purple)),
      ),
    );
  }

  Widget _panel(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(22)),
        child: child,
      );

  Future<void> _assign(String therapistId, String therapistName) async {
    final ref = _childRef;
    if (ref == null || _saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign therapist?'),
        content: Text('Assign $therapistName to this child?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Assign')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      // This simple assignment is suitable only when Firestore rules permit
      // parents to assign a verified therapist to their own child.
      await ref.update({
        'assignedTherapistId': therapistId,
        'assignedTherapistName': therapistName,
        'therapistAssignedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Therapist assigned successfully.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to assign therapist: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showTherapist(Map<String, dynamic> therapist, String therapistId,
      {bool assigned = false}) {
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true,
      backgroundColor: cream, showDragHandle: true,
      builder: (sheetContext) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 25),
        child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _avatar(therapist, size: 110)),
            const SizedBox(height: 14),
            Center(child: Text(_therapistName(therapist),
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold))),
            Center(child: Text(_value(therapist, 'specialization', 'Speech therapy'))),
            const SizedBox(height: 18),
            _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Clinic: ${_therapistClinic(therapist)}'),
              const SizedBox(height: 8),
              Text('Experience: ${_therapistExperience(therapist)} years'),
              const SizedBox(height: 12),
              const Text('About', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_value(therapist, 'bio', 'No biography available yet.')),
              const SizedBox(height: 12),
              const Text('Qualifications', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_value(therapist, 'qualification', 'Not provided')),
            ])),
            const SizedBox(height: 16),
            if (!assigned)
              SizedBox(width: double.infinity, child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: purple),
                onPressed: _saving ? null : () {
                  Navigator.pop(sheetContext);
                  _assign(therapistId, _therapistName(therapist));
                },
                child: const Text('Assign Therapist'),
              )),
          ],
        )),
      )),
    );
  }

  Widget _discover() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Find a Therapist', style: TextStyle(fontSize: 25,
      fontWeight: FontWeight.w800, color: purple)),
    const SizedBox(height: 6),
    const Text('Find a speech therapist for your child.',
      style: TextStyle(color: Colors.black54)),
    const SizedBox(height: 20),
    TextField(
      controller: _search,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, color: purple),
        hintText: 'Search name, specialty or clinic',
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none),
      ),
    ),
    const SizedBox(height: 14),
    SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
      for (final option in ['All', 'Available', 'Speech Therapy', 'Pediatric'])
        Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
          label: Text(option), selected: _filter == option,
          selectedColor: yellow,
          onSelected: (_) => setState(() => _filter = option),
        )),
    ])),
    const SizedBox(height: 22),
    const Text('Available Therapists', style: TextStyle(fontSize: 20,
      fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('therapists').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Cannot load therapists: ${snapshot.error}');
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final query = _search.text.trim().toLowerCase();
        final matches = snapshot.data!.docs.where((doc) {
          final t = doc.data();
          // Only verified, active therapists should appear. Verification
          // should be enforced by backend rules, not only this UI.
          if ((t['verificationStatus'] ?? '').toString().trim().toLowerCase() != 'verified' || t['isActive'] != true) return false;
          final text = '${_therapistName(t)} ${t['specialization'] ?? ''} ${_therapistClinic(t)}'.toLowerCase();
          if (!text.contains(query)) return false;
          if (_filter == 'Available' && t['isAvailable'] != true) return false;
          if (_filter == 'Speech Therapy' && !text.contains('speech')) return false;
          if (_filter == 'Pediatric' && !text.contains('pediatric') && !text.contains('paediatric')) return false;
          return true;
        }).toList();
        if (matches.isEmpty) return _panel(const Text('No therapists found. Try another search or filter.'));
        return Column(children: [
          for (final doc in matches) Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showTherapist(doc.data(), doc.id),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: yellow,
                  borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  _avatar(doc.data()),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_therapistName(doc.data()),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(_value(doc.data(), 'specialization', 'Speech Therapist'),
                        style: const TextStyle(fontSize: 12)),
                      Text(_therapistClinic(doc.data()),
                        style: const TextStyle(fontSize: 11)),
                    ])),
                  const Icon(Icons.chevron_right, color: purple),
                ]),
              ),
            ),
          ),
        ]);
      },
    ),
  ]);

  bool _openingVideo = false;

  Future<void> _openVideoCall(String therapistId, String therapistName) async {
    final parentId = _uid;
    final childId = _selectedChildId;
    if (parentId == null || childId == null || _openingVideo) return;

    setState(() => _openingVideo = true);
    try {
      // This query needs parent-scoped read permission on appointments.
      final result = await FirebaseFirestore.instance
          .collection('appointments')
          .where('parentId', isEqualTo: parentId)
          .get();

      final now = DateTime.now();
      QueryDocumentSnapshot<Map<String, dynamic>>? active;
      for (final doc in result.docs) {
        final a = doc.data();
        if (a['therapistId'] != therapistId || a['childId'] != childId) continue;
        if (a['status'] != 'booked' && a['status'] != 'confirmed') continue;
        final start = a['startAt'];
        final end = a['endAt'];
        if (start is! Timestamp || end is! Timestamp) continue;
        if (!now.isBefore(start.toDate()) && now.isBefore(end.toDate())) {
          active = doc;
          break;
        }
      }

      if (active == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No active video appointment. Join during your booked 60-minute session.'),
        ));
        return;
      }

      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) throw StateError('Please sign in again.');
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) throw StateError('Unable to obtain Firebase login token.');

      // Android Emulator -> host computer. Replace for physical devices/deployment.
      final url = Uri.parse(
        'http://10.0.2.2:8000/agora/token/${Uri.encodeComponent(active.id)}',
      );
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $idToken',
      }).timeout(const Duration(seconds: 15));
      final body = jsonDecode(response.body);
      if (response.statusCode != 200) {
        final detail = body is Map ? body['detail'] : null;
        throw StateError(detail?.toString() ?? 'Video token request failed (${response.statusCode})');
      }
      if (body is! Map<String, dynamic>) {
        throw const FormatException('Unexpected video token response');
      }
      final appId = body['appId'] as String?;
      final token = body['token'] as String?;
      final channelName = body['channelName'] as String?;
      final agoraUid = body['uid'];
      if (appId == null || token == null || channelName == null || agoraUid is! int) {
        throw const FormatException('Incomplete Agora token response');
      }
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => ParentVideoCallScreen(
          appId: appId,
          token: token,
          channelName: channelName,
          uid: agoraUid,
          therapistName: therapistName,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Unable to start video call: $e'),
      ));
    } finally {
      if (mounted) setState(() => _openingVideo = false);
    }
  }

  void _notReady(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature will be available after the session setup is connected.'),
    ));
  }

  Widget _actionTile(IconData icon, String label, {required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(children: [
            Icon(icon, color: purple, size: 27),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }

  Widget _therapistNotes(String therapistId) {
    final ref = _childRef;
    if (ref == null) return const SizedBox.shrink();
    return _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Therapist Notes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ref.collection('therapistFeedback').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Unable to load notes: ${snapshot.error}');
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.where((d) => d.data()['therapistId'] == therapistId).toList();
          docs.sort((a, b) {
            final ad = a.data()['createdAt'];
            final bd = b.data()['createdAt'];
            final at = ad is Timestamp ? ad.millisecondsSinceEpoch : 0;
            final bt = bd is Timestamp ? bd.millisecondsSinceEpoch : 0;
            return bt.compareTo(at);
          });
          if (docs.isEmpty) return const Text('Session notes will appear here when shared by your therapist.');
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final doc in docs) ...[
              Text(_value(doc.data(), 'therapistName', 'Therapist'),
                style: const TextStyle(color: purple, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(_value(doc.data(), 'observation', 'No observation provided.')),
              if ((doc.data()['recommendation'] ?? '').toString().trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Recommendation: ${doc.data()['recommendation']}'),
              ],
              const SizedBox(height: 12),
            ],
          ]);
        },
      ),
    ]));
  }

  Widget _homeworkModules(String therapistId) {
    final ref = _childRef;
    if (ref == null) return const SizedBox.shrink();
    return _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Homework Module', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: ref.collection('moduleAssignments').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Unable to load homework: ${snapshot.error}');
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.where((d) => d.data()['therapistId'] == therapistId).toList();
          docs.sort((a, b) {
            final ad = a.data()['assignedAt'];
            final bd = b.data()['assignedAt'];
            final at = ad is Timestamp ? ad.millisecondsSinceEpoch : 0;
            final bt = bd is Timestamp ? bd.millisecondsSinceEpoch : 0;
            return bt.compareTo(at);
          });
          if (docs.isEmpty) return const Text('Assigned practice activities will appear here.');
          return Column(children: [
            for (final doc in docs) Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.menu_book_outlined, color: purple),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${_value(doc.data(), 'sound', 'Practice')} Sound • Module ${doc.data()['module'] ?? '-'}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_value(doc.data(), 'instructions', 'Practice this module at home.')),
                  const SizedBox(height: 3),
                  Text('Status: ${_value(doc.data(), 'status', 'assigned')}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ])),
              ]),
            ),
          ]);
        },
      ),
    ]));
  }

  Widget _assigned(String therapistId, String childName) =>
    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('therapists').doc(therapistId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Cannot load therapist: ${snapshot.error}');
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (!snapshot.data!.exists) return _panel(const Text('Assigned therapist profile is unavailable.'));
        final t = snapshot.data!.data() ?? {};
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('My Therapist', style: TextStyle(fontSize: 25,
            fontWeight: FontWeight.w800, color: purple)),
          const SizedBox(height: 6),
          Text('Assigned to $childName', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 18),
          Container(width: double.infinity, padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: yellow,
              borderRadius: BorderRadius.circular(24)),
            child: Column(children: [
              _avatar(t, size: 112),
              const SizedBox(height: 12),
              Text(_therapistName(t),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(_value(t, 'specialization', 'Speech Therapist')),
              Text(_therapistClinic(t)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _actionTile(Icons.calendar_month, 'Book\nAppointment',
                  onTap: () {
                    final childId = _selectedChildId;
                    if (childId == null) return;
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ParentBookAppointmentScreen(
                      therapistId: therapistId,
                      therapistName: _therapistName(t),
                      childId: childId, childName: childName,
                    )));
                  })),
                const SizedBox(width: 8),
                Expanded(child: _actionTile(Icons.videocam_outlined, 'Video\nCall',
                  onTap: () => _openVideoCall(therapistId, _therapistName(t)))),
                const SizedBox(width: 8),
                Expanded(child: _actionTile(Icons.chat_bubble_outline, 'Chat', onTap: () {
                  final childId = _selectedChildId;
                  final parentId = _uid;
                  if (childId == null || parentId == null) return;
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ParentTherapistChatScreen(
                      parentId: parentId,
                      therapistId: therapistId,
                      childId: childId,
                      therapistName: _therapistName(t),
                    ),
                  ));
                })),
              ]),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => _showTherapist(t, therapistId, assigned: true),
                icon: const Icon(Icons.person_outline),
                label: const Text('View Full Profile'),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Upcoming Schedule', style: TextStyle(fontSize: 17,
              fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ParentUpcomingAppointments(
              childId: _selectedChildId,
              therapistId: therapistId,
              onJoinCall: (context, appointmentId) async {
                await _openVideoCall(
                  therapistId,
                  _therapistName(t),
                );
              },
            ),
          ])),
          const SizedBox(height: 14),
          _therapistNotes(therapistId),
          const SizedBox(height: 14),
          _homeworkModules(therapistId),
        ]);
      },
    );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChildProfile>>(
      future: _childrenFuture,
      builder: (context, childrenSnapshot) {
        final children = childrenSnapshot.data ?? <ChildProfile>[];
        final selectedId = children.any((c) => c.id == _selectedChildId)
            ? _selectedChildId
            : (children.isEmpty ? null : children.first.id);
        _selectedChildId = selectedId;

        return ParentPage(
          tab: ParentTab.therapist,
          header: ParentHeader(
            title: 'Therapist',
            subtitle: 'Find support for your child',
            below: children.isEmpty
                ? const Text('Select a child to continue',
                    style: TextStyle(color: Colors.white))
                : ParentChildPicker(
                    children: children,
                    selectedId: selectedId,
                    onSelect: (child) => setState(() => _selectedChildId = child.id),
                  ),
          ),
          children: [
            if (childrenSnapshot.hasError)
              ParentCard(child: Text('Unable to load children: ${childrenSnapshot.error}'))
            else if (!childrenSnapshot.hasData)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (selectedId == null)
              const ParentCard(child: Text('Please add a child profile first.'))
            else
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                key: ValueKey(selectedId),
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(_uid!)
                    .collection('children')
                    .doc(selectedId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ParentCard(child: Text('Cannot load child: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.data!.exists) {
                    return const ParentCard(child: Text('Child profile not found.'));
                  }
                  final child = snapshot.data!.data() ?? {};
                  final assignedId =
                      (child['assignedTherapistId'] ?? '').toString().trim();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: assignedId.isEmpty
                        ? _discover()
                        : _assigned(assignedId, _value(child, 'name', 'your child')),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

/// Matches the existing ParentTab.therapist navigation in parent_ui.dart.
class TherapistScreen extends StatelessWidget {
  const TherapistScreen({super.key});

  @override
  Widget build(BuildContext context) => const ParentTherapistScreen();
}
