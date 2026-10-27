import 'dart:convert';
import 'dart:typed_data';
import 'edit_child_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talkiepal/services/progress_store.dart';

class ChildProfileDetailsScreen extends StatefulWidget {
  final String childId;

  const ChildProfileDetailsScreen({
    super.key,
    required this.childId,
  });

  @override
  State<ChildProfileDetailsScreen> createState() =>
      _ChildProfileDetailsScreenState();
}

class _ChildProfileDetailsScreenState
    extends State<ChildProfileDetailsScreen> {
  static const Color purple = Color(0xFF8154AA);
  static const Color cream = Color(0xFFFFFBF4);
  static const Color yellow = Color(0xFFFFEFA8);

  DocumentReference<Map<String, dynamic>>? get _childRef {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('children')
        .doc(widget.childId);
  }

  String _string(
    Map<String, dynamic> data,
    String key, [
    String fallback = 'Not specified',
  ]) {
    final value = data[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  String _therapistId(Map<String, dynamic> data) {
    final primary =
        (data['primaryTherapistId'] ?? '').toString().trim();

    final assigned =
        (data['assignedTherapistId'] ?? '').toString().trim();

    return primary.isNotEmpty ? primary : assigned;
  }

  List<String> _goals(Map<String, dynamic> data) {
    final raw = data['therapyGoals'];

    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return [];
  }

  Widget _card({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: purple,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editChild(Map<String, dynamic> data) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditChildProfileScreen(
          childId: widget.childId,
          initialData: data,
        ),
      ),
    );
  }

  Uint8List? _childPhoto(Map<String, dynamic> data) {
    final raw = data['base64Photo'];
    if (raw is! String || raw.isEmpty) return null;
    try {
      return base64Decode(raw.contains(',') ? raw.split(',').last : raw);
    } catch (_) {
      return null;
    }
  }

  // Read the current Supabase photo; keep Base64 for older profiles.
  Widget _displayChildPhoto(Map<String, dynamic> data) {
    final path = (data['childPhotoPath'] ?? '').toString().trim();
    final oldPhoto = _childPhoto(data);

    if (path.isEmpty) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: yellow,
        backgroundImage: oldPhoto == null ? null : MemoryImage(oldPhoto),
        child: oldPhoto == null
            ? const Icon(Icons.child_care_rounded, color: purple, size: 38)
            : null,
      );
    }

    // updatedAt changes when a new photo is saved, even if its path stays the same.
    final version = data['updatedAt']?.toString() ?? '';
    return _SupabaseChildAvatar(
      key: ValueKey('$path|$version'),
      path: path,
      fallbackPhoto: oldPhoto,
    );
  }

  Widget _childInformation(
    Map<String, dynamic> data,
  ) {
    final goals = _goals(data);

    final age = data['age']?.toString().trim();

    return _card(
      title: 'Child Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(
            'Name',
            _string(data, 'name'),
          ),
          _infoRow(
            'Age',
            age == null || age.isEmpty
                ? 'Not specified'
                : '$age years',
          ),
          _infoRow(
            'Target Sound',
            '/${_string(data, 'targetSound', '-')}/',
          ),
          _infoRow(
            'Speech Concern',
            _string(data, 'speechConcern'),
          ),
          _infoRow(
            'Specific Problem',
            _string(data, 'specificProblem'),
          ),
          _infoRow(
            'Notes',
            _string(data, 'notes'),
          ),
          const Divider(height: 22),
          const Text(
            'Therapy Goals',
            style: TextStyle(
              color: purple,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          if (goals.isEmpty)
            const Text(
              'No therapy goals specified.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            )
          else
            ...goals.map(
              (goal) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: purple,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        goal,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _editChild(data),
              style: FilledButton.styleFrom(
                backgroundColor: purple,
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
              ),
              icon: const Icon(Icons.edit_rounded),
              label: const Text(
                'Edit Child Information',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignedTherapist(
    Map<String, dynamic> childData,
  ) {
    final therapistId = _therapistId(childData);

    if (therapistId.isEmpty) {
      return _card(
        title: 'Assigned Therapist',
        child: const Text(
          'No therapist assigned yet.',
        ),
      );
    }

    return _card(
      title: 'Assigned Therapist',
      child: StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('therapists')
            .doc(therapistId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(
              'Unable to load therapist: ${snapshot.error}',
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.data!.exists) {
            return const Text(
              'Assigned therapist profile not found.',
            );
          }

          final therapist = snapshot.data!.data() ?? {};

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: yellow,
                child: Icon(
                  Icons.medical_services_rounded,
                  color: purple,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _string(
                        therapist,
                        'fullName',
                        'Speech Therapist',
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _string(
                        therapist,
                        'specialization',
                        'Speech Therapy',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _string(
                        therapist,
                        'hospital',
                        'Hospital not specified',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
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

  Widget _learningProgress() {
    return _card(
      title: 'Learning Progress',
      child: FutureBuilder(
        future: ProgressStore.instance.sessions(
          childId: widget.childId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(
              'Unable to load progress: ${snapshot.error}',
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final sessions = snapshot.data!;

          if (sessions.isEmpty) {
            return const Text(
              'No practice sessions recorded yet.',
              style: TextStyle(fontSize: 12),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Practice Sessions',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${sessions.length}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: purple,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Practice records are saved for this child.',
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = _childRef;

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: purple,
        foregroundColor: Colors.white,
        title: const Text('Child Profile'),
      ),
      body: ref == null
          ? const Center(
              child: Text('Please sign in again.'),
            )
          : StreamBuilder<
              DocumentSnapshot<Map<String, dynamic>>>(
              stream: ref.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load child: ${snapshot.error}',
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.data!.exists) {
                  return const Center(
                    child: Text('Child profile not found.'),
                  );
                }

                final data = snapshot.data!.data() ?? {};

                final name = _string(
                  data,
                  'name',
                  'Child',
                );

                final sound = _string(
                  data,
                  'targetSound',
                  '-',
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 22,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: purple,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            _displayChildPhoto(data),
                            const SizedBox(height: 12),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Target /$sound/',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _childInformation(data),
                      _assignedTherapist(data),
                      _learningProgress(),
                    ],
                  ),
                );
              },
            ),
    );
  }
}


/// Fetches one signed URL per profile update, rather than on every rebuild.
class _SupabaseChildAvatar extends StatefulWidget {
  const _SupabaseChildAvatar({
    super.key,
    required this.path,
    required this.fallbackPhoto,
  });

  final String path;
  final Uint8List? fallbackPhoto;

  @override
  State<_SupabaseChildAvatar> createState() => _SupabaseChildAvatarState();
}

class _SupabaseChildAvatarState extends State<_SupabaseChildAvatar> {
  late final Future<String> _photoUrl;

  @override
  void initState() {
    super.initState();
    _photoUrl = Supabase.instance.client.storage
        .from('child-photos')
        .createSignedUrl(widget.path, 3600);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _photoUrl,
      builder: (context, snapshot) {
        final fallback = widget.fallbackPhoto;
        final ImageProvider? image = snapshot.hasData
            ? NetworkImage(snapshot.data!)
            : (fallback == null ? null : MemoryImage(fallback));
        return CircleAvatar(
          radius: 40,
          backgroundColor: const Color(0xFFFFEFA8),
          backgroundImage: image,
          child: image == null
              ? const Icon(Icons.child_care_rounded,
                  color: Color(0xFF8154AA), size: 38)
              : null,
        );
      },
    );
  }
}
