import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:talkiepal/services/therapist_progress_pdf.dart';

import 'therapist_ui.dart';
import 'therapist_dashboard.dart';
import 'therapist_parent_chat_screen.dart';
import 'therapist_profile_screen.dart';

class TalkiePalApiConfig {
  // Pass --dart-define=TALKIEPAL_API_URL=https://your-deployed-api.example
  // For Android Emulator use http://10.0.2.2:8000 instead.
  static const String baseUrl = String.fromEnvironment(
    'TALKIEPAL_API_URL',
    defaultValue: 'http://192.168.0.139:8000',
  );
}

const _ink = TherapistColors.text;
const _purple = TherapistColors.purple;

String _string(dynamic value, [String fallback = 'Not provided']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _date(dynamic value) {
  DateTime? date;
  if (value is Timestamp) date = value.toDate();
  if (value is DateTime) date = value;
  if (value is String) date = DateTime.tryParse(value);
  if (date == null) return 'Not provided';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _age(Map<String, dynamic> child) {
  final birth = child['birthDate'] ?? child['dob'];
  DateTime? date;
  if (birth is Timestamp) date = birth.toDate();
  if (birth is DateTime) date = birth;
  if (date != null) {
    final now = DateTime.now();
    var years = now.year - date.year;
    if (now.month < date.month || (now.month == date.month && now.day < date.day)) years--;
    return '$years years';
  }
  return child['age'] == null ? 'Not provided' : '${child['age']} years (registered)';
}

void _message(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _TherapistParentPhoto extends StatefulWidget {
  const _TherapistParentPhoto({required this.parentId, this.radius = 20});
  final String parentId;
  final double radius;

  @override
  State<_TherapistParentPhoto> createState() => _TherapistParentPhotoState();
}

class _TherapistParentPhotoState extends State<_TherapistParentPhoto> {
  late Future<String?> _photoUrl;

  @override
  void initState() {
    super.initState();
    _photoUrl = _loadPhoto();
  }

  @override
  void didUpdateWidget(covariant _TherapistParentPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parentId != widget.parentId) _photoUrl = _loadPhoto();
  }

  Future<String?> _loadPhoto() async {
    try {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) return null;
    final response = await http.get(
      Uri.parse('${TalkiePalApiConfig.baseUrl}/therapist/parents/${Uri.encodeComponent(widget.parentId)}/photo'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      debugPrint('Parent photo request failed: ${response.statusCode} ${response.body}');
      return null;
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['url'] as String?;
    } catch (e) {
      debugPrint('Supabase photo URL request failed: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _photoUrl,
      builder: (context, snapshot) {
        final url = snapshot.data;
        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: const Color(0xFFFFF0C5),
          backgroundImage: url == null ? null : NetworkImage(url),
          onBackgroundImageError: url == null ? null : (error, stack) {
            debugPrint('Parent photo display failed: $error');
          },
          child: url != null ? null : const Icon(Icons.person_outline_rounded, color: _purple),
        );
      },
    );
  }
}

class _TherapistChildPhoto extends StatefulWidget {
  const _TherapistChildPhoto({required this.parentId, required this.childId, this.radius = 28});
  final String parentId;
  final String childId;
  final double radius;

  @override
  State<_TherapistChildPhoto> createState() => _TherapistChildPhotoState();
}

class _TherapistChildPhotoState extends State<_TherapistChildPhoto> {
  late Future<String?> _photoUrl;

  @override
  void initState() {
    super.initState();
    _photoUrl = _loadPhoto();
  }

  @override
  void didUpdateWidget(covariant _TherapistChildPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parentId != widget.parentId || oldWidget.childId != widget.childId) {
      _photoUrl = _loadPhoto();
    }
  }

  Future<String?> _loadPhoto() async {
    try {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) return null;
    final response = await http.get(
      Uri.parse('${TalkiePalApiConfig.baseUrl}/therapist/parents/${Uri.encodeComponent(widget.parentId)}/children/${Uri.encodeComponent(widget.childId)}/photo'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      debugPrint('Child photo request failed: ${response.statusCode} ${response.body}');
      return null;
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['url'] as String?;
    } catch (e) {
      debugPrint('Supabase photo URL request failed: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _photoUrl,
      builder: (context, snapshot) {
        final url = snapshot.data;
        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: const Color(0xFFF1E8F8),
          backgroundImage: url == null ? null : NetworkImage(url),
          onBackgroundImageError: url == null ? null : (error, stack) {
            debugPrint('Child photo display failed: $error');
          },
          child: url == null ? const Icon(Icons.person_outline_rounded, color: _purple) : null,
        );
      },
    );
  }
}

class TherapistPatientsScreen extends StatefulWidget {
  const TherapistPatientsScreen({super.key});

  @override
  State<TherapistPatientsScreen> createState() => _TherapistPatientsScreenState();
}

class _TherapistPatientsScreenState extends State<TherapistPatientsScreen> {
  final TextEditingController _search = TextEditingController();
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _search.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _search.removeListener(_refresh);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please sign in as a therapist.')));
    }

    return Scaffold(
      backgroundColor: TherapistColors.background,
      appBar: AppBar(
        backgroundColor: TherapistColors.yellow,
        foregroundColor: _ink,
        title: const Text('My Patients', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      bottomNavigationBar: TherapistBottomNav(
        selectedIndex: 2,
        onSelect: (index) {
          if (index == 2) return;
          Widget destination;
          switch (index) {
            case 0:
              destination = const TherapistDashboard();
              break;
            case 1:
              destination = const TherapistParentChatScreen();
              break;
            case 3:
              destination = const TherapistProfileScreen();
              break;
            default:
              return;
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => destination),
          );
        },
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF9C72C4), Color(0xFF65408B)]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: _purple.withValues(alpha: .14), blurRadius: 16, offset: const Offset(0, 7))],
          ),
          child: const Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('YOUR LITTLE STARS', style: TextStyle(color: Color(0xFFF5E9FF), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
              SizedBox(height: 8),
              Text('Patient Care', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              SizedBox(height: 6),
              Text('Every little sound is a big achievement.', style: TextStyle(color: Color(0xFFF4E9FC), fontSize: 12)),
            ])),
            Icon(Icons.diversity_1_rounded, color: Color(0xFFFFEFA8), size: 46),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFECE1F4))),
            child: Column(children: [
              TextField(controller: _search,
                decoration: InputDecoration(hintText: 'Search child or parent...',
                  prefixIcon: const Icon(Icons.search_rounded, color: _purple),
                  suffixIcon: _search.text.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded), onPressed: _search.clear),
                  filled: true, fillColor: const Color(0xFFF8F3FC),
                  border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(14))),
              ),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft,
                child: Text('Filter by speech concern', style: TextStyle(
                  color: _ink, fontSize: 12, fontWeight: FontWeight.w700))),
              const SizedBox(height: 9),
              SizedBox(height: 40, child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final problem in const ['All', 'Speech Delay', 'R', 'S', 'L', 'TH', 'SH', 'Other'])
                    Padding(padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(problem, style: const TextStyle(fontSize: 12)),
                        selected: _filter == problem,
                        selectedColor: const Color(0xFFFFEFA8),
                        backgroundColor: const Color(0xFFF8F3FC),
                        onSelected: (_) => setState(() => _filter = problem),
                      )),
                ],
              )),
            ]),
          ),
        ),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('therapist_assignments')
              .where('therapistUid', isEqualTo: uid).snapshots(),
          builder: (context, assignmentsSnapshot) {
            if (assignmentsSnapshot.hasError) {
              return _notice('Unable to read therapist assignments. Check Firestore rules.\n${assignmentsSnapshot.error}');
            }
            if (!assignmentsSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('chats')
                  .where('therapistId', isEqualTo: uid).snapshots(),
              builder: (context, chatsSnapshot) {
                // Assignments are authoritative. Existing chats are a compatibility fallback.
                final patients = <String, Map<String, dynamic>>{};
                for (final doc in assignmentsSnapshot.data!.docs) {
                  final data = doc.data();
                  final parentId = _string(data['parentUid'] ?? data['parentId'], '');
                  final childId = _string(data['childId'], '');
                  if (parentId.isEmpty || childId.isEmpty) continue;
                  patients['$parentId/$childId'] = {...data, 'parentId': parentId, 'childId': childId};
                }
                if (chatsSnapshot.hasData) {
                  for (final doc in chatsSnapshot.data!.docs) {
                    final data = doc.data();
                    final parentId = _string(data['parentId'] ?? data['parentUid'], '');
                    final childId = _string(data['childId'], '');
                    if (parentId.isEmpty || childId.isEmpty) continue;
                    patients.putIfAbsent('$parentId/$childId', () => data);
                  }
                }
                final filtered = patients.values.toList();
                if (filtered.isEmpty) {
                  return _notice('No patients found. Confirm the child is linked in therapist_assignments with therapistUid, parentUid and childId.');
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final data = filtered[index];
                    return _PatientTile(
                      parentId: _string(data['parentId'] ?? data['parentUid'], ''),
                      childId: _string(data['childId'], ''),
                      fallbackChildName: _string(data['childName'], 'Child'),
                      fallbackParentName: _string(data['parentName'], 'Parent'),
                      search: _search.text.trim().toLowerCase(),
                      problemFilter: _filter,
                    );
                  },
                );
              },
            );
          },
        )),
      ]),
    );
  }

  Widget _notice(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: TherapistCard(child: Text(message, textAlign: TextAlign.center)),
        ),
      );
}

class _PatientTile extends StatelessWidget {
  const _PatientTile({
    required this.parentId,
    required this.childId,
    required this.fallbackChildName,
    required this.fallbackParentName,
    required this.search,
    required this.problemFilter,
  });

  final String parentId;
  final String childId;
  final String fallbackChildName;
  final String fallbackParentName;
  final String search;
  final String problemFilter;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(parentId).snapshots(),
      builder: (context, parentSnapshot) {
        final parentData = parentSnapshot.data?.data() ?? <String, dynamic>{};
        final parentName = _string(parentData['username'] ?? parentData['name'] ?? parentData['fullName'], fallbackParentName);
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(parentId)
          .collection('children')
          .doc(childId)
          .snapshots(),
      builder: (context, childSnapshot) {
        final child = childSnapshot.data?.data() ?? <String, dynamic>{};
        final name = _string(child['name'], fallbackChildName);
        if (search.isNotEmpty &&
            !name.toLowerCase().contains(search) &&
            !parentName.toLowerCase().contains(search)) {
          return const SizedBox.shrink();
        }
        final concern = _string(child['speechConcern'] ?? child['problemType'] ?? child['specificProblem'], 'Not specified');
        final problems = [child['speechConcern'], child['problemType'], child['specificProblem'], child['otherProblem'], child['targetSound']]
            .where((v) => v != null).map((v) => v.toString().toLowerCase()).join(' ');
        final selectedProblem = problemFilter.toLowerCase();
        if (problemFilter != 'All') {
          final matches = selectedProblem == 'other'
              ? problems.contains('other')
              : selectedProblem.length <= 2
                  ? RegExp('(^|[^a-z])${RegExp.escape(selectedProblem)}([^a-z]|\$)').hasMatch(problems)
                  : problems.contains(selectedProblem);
          if (!matches) return const SizedBox.shrink();
        }
                return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(19),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TherapistPatientDetailPage(
                    parentId: parentId,
                    childId: childId,
                    childName: name,
                    parentName: parentName,
                  ),
                ),
              ),
              child: TherapistCard(
                child: Row(
                  children: [
                    _TherapistChildPhoto(parentId: parentId, childId: childId),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: _ink)),
                          const SizedBox(height: 4),
                          Text('Parent: $parentName', style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 7),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0xFFF4ECFA), borderRadius: BorderRadius.circular(20)),
                            child: Text('Speech focus: $concern', style: const TextStyle(fontSize: 11, color: _purple, fontWeight: FontWeight.w700))),
                          if (childSnapshot.hasError)
                            Text('Child profile access denied: ${childSnapshot.error}',
                                style: const TextStyle(fontSize: 11, color: Colors.deepOrange)),
                        ],
                      ),
                    ),
                    const CircleAvatar(radius: 16, backgroundColor: Color(0xFFFFEFA8), child: Icon(Icons.arrow_forward_ios_rounded, size: 13, color: _purple)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
      },
    );
  }
}

class TherapistPatientDetailPage extends StatelessWidget {
  const TherapistPatientDetailPage({
    super.key,
    required this.parentId,
    required this.childId,
    required this.childName,
    required this.parentName,
  });

  final String parentId;
  final String childId;
  final String childName;
  final String parentName;

  DocumentReference<Map<String, dynamic>> get _childRef => FirebaseFirestore.instance
      .collection('users').doc(parentId).collection('children').doc(childId);

  Future<void> _comment(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _TherapistCommentDialog(
        parentId: parentId,
        childId: childId,
      ),
    );
  }

  Future<void> _assignModules(BuildContext context) async {
    final selections = <String>{};
    final instructions = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Assign practice modules'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select modules for the child:'),
                  for (final sound in const ['R', 'S', 'L', 'TH', 'SH']) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 4),
                      child: Text('$sound sound', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    for (var level = 1; level <= 3; level++)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('Module $level'),
                        value: selections.contains('$sound-$level'),
                        onChanged: (checked) => update(() {
                          if (checked == true) {
                            selections.add('$sound-$level');
                          } else {
                            selections.remove('$sound-$level');
                          }
                        }),
                      ),
                  ],
                  TextField(
                    controller: instructions,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Instructions (optional)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: selections.isEmpty ? null : () => Navigator.pop(dialogContext, true),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
    final note = instructions.text.trim();
    instructions.dispose();
    if (confirmed != true || selections.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final selection in selections) {
        final parts = selection.split('-');
        final ref = _childRef.collection('moduleAssignments').doc('${uid}_${parts[0]}_${parts[1]}');
        batch.set(ref, {
          'therapistId': uid,
          'parentId': parentId,
          'childId': childId,
          'sound': parts[0],
          'module': int.parse(parts[1]),
          'instructions': note,
          'status': 'assigned',
          'assignedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      if (context.mounted) _message(context, '${selections.length} module(s) assigned.');
    } catch (error) {
      if (context.mounted) _message(context, 'Unable to assign modules: $error');
    }
  }

  Future<void> _report(BuildContext context) async {
    try {
      await generateTherapistProgressPdf(
        parentId: parentId,
        childId: childId,
        fallbackChildName: childName,
        parentName: parentName,
      );
    } catch (error) {
      if (context.mounted) _message(context, 'Unable to generate report: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TherapistColors.background,
      appBar: AppBar(
        title: Text(childName, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: TherapistColors.yellow,
        foregroundColor: _ink,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _childRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Unable to read child profile. Check Firestore permissions.\n${snapshot.error}'),
            ));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final child = snapshot.data?.data();
          if (child == null) return const Center(child: Text('Child profile not found.'));
            final goals = (child['therapyGoals'] ?? child['goals']) is List ? (child['therapyGoals'] ?? child['goals']) as List : const [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8256A8), Color(0xFF65408B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(children: [
                  _TherapistChildPhoto(parentId: parentId, childId: childId, radius: 39),
                  const SizedBox(width: 16),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CHILD PATIENT', style: TextStyle(
                        color: Color(0xFFEBDDF5), fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                      const SizedBox(height: 5),
                      Text(_string(child['name'], childName),
                          style: const TextStyle(color: Colors.white,
                              fontSize: 21, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 7, runSpacing: 7, children: [
                        _pill(_age(child)),
                        _pill(_string(child['gender'])),
                      ]),
                    ],
                  )),
                ]),
              ),
              const SizedBox(height: 14),
              _sectionWithIcon(Icons.badge_outlined, 'Child information', [
                _detail('Date of birth', _date(child['birthDate'] ?? child['dob'])),
                _detail('Registration date', _date(child['createdAt'])),
              ]),
              const SizedBox(height: 14),
              _sectionWithIcon(Icons.record_voice_over_outlined, 'Speech & development', [
                _detail('Parent-reported concern', child['speechConcern'] ?? child['problemType']),
                if (_string(child['otherConcern'], '').isNotEmpty)
                  _detail('Other concern', child['otherConcern']),
                if (_string(child['specificProblem'], '').isNotEmpty)
                  _detail('Specific problem', child['specificProblem']),
                _detail('Target sound', child['targetSound']),
                const SizedBox(height: 3),
                const Text('Therapy goals', style: TextStyle(
                    fontSize: 12, color: TherapistColors.muted,
                    fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                goals.isEmpty
                    ? const Text('Not provided', style: TextStyle(color: _ink))
                    : Wrap(spacing: 7, runSpacing: 7,
                        children: goals.map((goal) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EBF8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(goal.toString(), style: const TextStyle(
                            color: _purple, fontSize: 12, fontWeight: FontWeight.w600)),
                        )).toList()),
              ]),
              const SizedBox(height: 14),
              _sectionWithIcon(Icons.family_restroom_outlined, 'Parent information', [
                Row(children: [
                  _TherapistParentPhoto(parentId: parentId),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_string(parentName), style: const TextStyle(
                          fontWeight: FontWeight.w800, color: _ink)),
                      const Text('Parent / Guardian', style: TextStyle(
                          fontSize: 12, color: TherapistColors.muted)),
                    ],
                  )),
                ]),
              ]),
              const SizedBox(height: 14),
              _sectionWithIcon(Icons.insights_outlined, 'Practice progress', [
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _childRef.collection('practiceSessions')
                      .orderBy('finishedAt', descending: true).limit(100).snapshots(),
                  builder: (context, practiceSnapshot) {
                    if (practiceSnapshot.hasError) {
                      return const Text('Practice data is unavailable. Check Firestore permissions.');
                    }
                    if (!practiceSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = practiceSnapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Row(children: [
                        Icon(Icons.hourglass_empty_rounded, color: _purple),
                        SizedBox(width: 12),
                        Expanded(child: Text(
                          'No completed practice sessions yet.\nResults will appear after the child finishes an exercise.',
                          style: TextStyle(color: TherapistColors.muted, height: 1.5))),
                      ]);
                    }
                    final scores = docs.map((d) => d.data()['score']).whereType<num>().toList();
                    final average = scores.isEmpty
                        ? 'N/A'
                        : '${(scores.fold<double>(0, (sum, value) => sum + value.toDouble()) / scores.length).toStringAsFixed(1)}/100';
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F0FB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('${docs.length} recent sessions',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
                          Text('Average: $average', style: const TextStyle(
                              fontWeight: FontWeight.w800, color: _purple)),
                        ]),
                      ),
                      const SizedBox(height: 8),
                      for (final doc in docs.take(10))
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(doc.data()['kind'] == 'game'
                              ? Icons.sports_esports : Icons.mic, color: _purple),
                          title: Text('${_string(doc.data()['topic'], 'Practice')} • ${_string(doc.data()['level'], '')}'),
                          subtitle: Text('${_date(doc.data()['finishedAt'])} • ${_string(doc.data()['stars'], '0')} stars'),
                          trailing: Text('${_string(doc.data()['score'], '-')}/100'),
                        ),
                    ]);
                  },
                ),
              ]),
              const SizedBox(height: 14),
              _sectionWithIcon(Icons.assignment_outlined, 'Therapist actions', [
                SizedBox(width: double.infinity, child: FilledButton.icon(
                  onPressed: () => _assignModules(context),
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Assign Practice Module',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                )),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _action(Icons.comment_outlined,
                      'Add Comment', () => _comment(context))),
                  const SizedBox(width: 8),
                  Expanded(child: _action(Icons.picture_as_pdf_rounded,
                      'PDF Report', () => _report(context))),
                ]),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _pill(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: const TextStyle(
          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      );

  Widget _sectionWithIcon(IconData icon, String title, List<Widget> children) =>
      TherapistCard(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EBF8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _purple, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, color: _ink))),
          ]),
          const SizedBox(height: 14),
          ...children,
        ],
      ));

  Widget _section(String title, List<Widget> children) => TherapistCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );

  Widget _detail(String label, dynamic value) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: TherapistColors.muted)),
            const SizedBox(height: 2),
            Text(_string(value), style: const TextStyle(fontWeight: FontWeight.w600, color: _ink)),
          ],
        ),
      );

  Widget _action(IconData icon, String title, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, color: _purple),
          label: Text(title, style: const TextStyle(color: _ink, fontSize: 11, fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
            side: const BorderSide(color: TherapistColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
        ),
      );
}


/// Owns the controllers for the whole dialog lifetime, including exit animation.
class _TherapistCommentDialog extends StatefulWidget {
  const _TherapistCommentDialog({required this.parentId, required this.childId});

  final String parentId;
  final String childId;

  @override
  State<_TherapistCommentDialog> createState() => _TherapistCommentDialogState();
}

class _TherapistCommentDialogState extends State<_TherapistCommentDialog> {
  final _observation = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _observation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final comment = _observation.text.trim();
    if (comment.isEmpty) {
      _message(context, 'Please enter a comment first.');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _message(context, 'Please sign in as a therapist.');
      return;
    }
    setState(() => _saving = true);
    try {
      final therapistName = (user.displayName?.trim().isNotEmpty ?? false)
          ? user.displayName!.trim()
          : 'Therapist';
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.parentId)
          .collection('children')
          .doc(widget.childId)
          .collection('therapistFeedback')
          .add({
        'therapistId': user.uid,
        'therapistName': therapistName,
        'parentId': widget.parentId,
        'childId': widget.childId,
        'observation': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _message(context, 'Unable to save comment: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add therapist comment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _observation,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Feedback for the parent',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}
