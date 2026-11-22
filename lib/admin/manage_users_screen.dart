import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'admin_api.dart';
import 'widgets/admin_ui.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  static const Color purple = Color(0xFF8054A1);
  static const Color cream = Color(0xFFFFFBF4);

  String search = '';
  String filter = 'all';
  bool busy = false;

  bool _suspended(Map<String, dynamic> data) =>
      data['accountStatus'] == 'suspended';

  bool _active(Map<String, dynamic> data) =>
      data['isActive'] != false && !_suspended(data);

  String _name(Map<String, dynamic> data) {
    final value = (data['username'] ?? data['name'] ?? '').toString().trim();
    return value.isEmpty ? 'Unknown Parent' : value;
  }

  DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  DateTime? _lastActive(Map<String, dynamic> data) =>
      _date(data['lastActiveAt']);

  String _formatDate(dynamic value) {
    final date = _date(value);
    if (date == null) return 'Not recorded';
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String _status(Map<String, dynamic> data) {
    if (_suspended(data)) return 'Suspended';
    return _active(data) ? 'Active' : 'Inactive';
  }

  Color _statusColor(Map<String, dynamic> data) {
    if (_suspended(data)) return Colors.red.shade700;
    return _active(data) ? Colors.green.shade700 : Colors.orange.shade800;
  }


  Future<void> _changeStatus(
    String uid,
    String name,
    bool isSuspended,
  ) async {
    final action = isSuspended ? 'reactivate' : 'suspend';
    final approved = await confirmAdminAction(
      context,
      isSuspended ? 'Reactivate Account' : 'Suspend Account',
      'Do you want to $action $name?',
    );
    if (!approved || !mounted) return;

    setState(() => busy = true);
    try {
      await AdminApi.call('manageAccount', {
        'uid': uid,
        'action': action,
      });
      if (mounted) {
        adminMessage(context, 'Account ${isSuspended ? 'reactivated' : 'suspended'} successfully.');
      }
    } catch (error) {
      if (mounted) adminMessage(context, 'Unable to update account: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filtered(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> source,
  ) {
    final query = search.trim().toLowerCase();
    final result = source.where((doc) {
      final data = doc.data();
      final searchable = '${_name(data)} ${data['email'] ?? ''}'.toLowerCase();
      if (!searchable.contains(query)) return false;
      switch (filter) {
        case 'active':
          return _active(data);
        case 'inactive':
          return !_active(data) && !_suspended(data);
        case 'suspended':
          return _suspended(data);
        default:
          return true;
      }
    }).toList();

    if (filter == 'mostActive' || filter == 'leastActive') {
      result.sort((a, b) {
        final ad = _lastActive(a.data());
        final bd = _lastActive(b.data());
        // Unknown activity always comes last, not counted as inactivity.
        if (ad == null && bd == null) return _name(a.data()).compareTo(_name(b.data()));
        if (ad == null) return 1;
        if (bd == null) return -1;
        final compare = ad.compareTo(bd);
        return filter == 'mostActive' ? -compare : compare;
      });
    } else {
      result.sort((a, b) =>
          _name(a.data()).toLowerCase().compareTo(_name(b.data()).toLowerCase()));
    }
    return result;
  }

  void _openParent(String uid) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ParentDetailsScreen(
          parentUid: uid,
          onChangeStatus: _changeStatus,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Manage Users',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search parent name or email',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onChanged: (value) => setState(() => search = value),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, color: purple),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Parent Accounts',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                    const Icon(Icons.filter_list, color: purple),
                    const SizedBox(width: 6),
                    Flexible(
                      child: DropdownButton<String>(
                        value: filter,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Parents')),
                          DropdownMenuItem(value: 'active', child: Text('Active')),
                          DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                          DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                          DropdownMenuItem(value: 'mostActive', child: Text('Most Recently Active')),
                          DropdownMenuItem(value: 'leastActive', child: Text('Least Recently Active')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => filter = value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'parent')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ErrorView(message: '${snapshot.error}');
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = _filtered(snapshot.data!.docs);
                if (docs.isEmpty) {
                  return const Center(child: Text('No parent accounts found.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final name = _name(data);
                    final suspended = _suspended(data);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AdminCard(
                        child: InkWell(
                          onTap: () => _openParent(doc.id),
                          child: Row(
                            children: [
                              _ParentAvatar(parentUid: doc.id),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('${data['email'] ?? ''}',
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(_status(data),
                                        style: TextStyle(
                                            color: _statusColor(data),
                                            fontWeight: FontWeight.w600)),
                                    Text('Last active: ${_formatDate(data['lastActiveAt'])}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                enabled: !busy,
                                onSelected: (_) => _changeStatus(doc.id, name, suspended),
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: suspended ? 'reactivate' : 'suspend',
                                    child: Text(suspended ? 'Reactivate' : 'Suspend'),
                                  ),
                                ],
                              ),
                              const Icon(Icons.chevron_right, color: purple),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentDetailsScreen extends StatelessWidget {
  const _ParentDetailsScreen({
    required this.parentUid,
    required this.onChangeStatus,
  });

  final String parentUid;
  final Future<void> Function(String, String, bool) onChangeStatus;

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Parent Details',
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(parentUid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _ErrorView(message: '${snapshot.error}');
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) return const Center(child: Text('Parent not found.'));
          final data = snapshot.data!.data() ?? {};
          final name = (data['username'] ?? data['name'] ?? 'Unknown Parent').toString();
          final suspended = data['accountStatus'] == 'suspended';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _ParentAvatar(parentUid: parentUid, radius: 45)),
                    const SizedBox(height: 12),
                    Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _DetailRow('Email', '${data['email'] ?? '-'}'),
                    _DetailRow('Status', suspended ? 'Suspended' : data['isActive'] == false ? 'Inactive' : 'Active'),
                    _DetailRow('Last active', _formatTimestamp(data['lastActiveAt'])),
                    _DetailRow('Registered', _formatTimestamp(data['createdAt'])),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Icon(suspended ? Icons.restore : Icons.block),
                        label: Text(suspended ? 'Reactivate Parent Account' : 'Suspend Parent Account'),
                        onPressed: () => onChangeStatus(parentUid, name, suspended),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('Children Profiles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users').doc(parentUid).collection('children').snapshots(),
                builder: (context, childSnapshot) {
                  if (childSnapshot.hasError) {
                    return _ErrorView(message: '${childSnapshot.error}');
                  }
                  if (!childSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final children = childSnapshot.data!.docs;
                  if (children.isEmpty) return const Text('No children registered.');
                  return Column(
                    children: children.map((child) {
                      final d = child.data();
                      final bytes = _decodePhoto(d['photoBase64'] ?? d['base64Photo'],);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AdminCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFEDE2F5),
                              backgroundImage: bytes == null ? null : MemoryImage(bytes),
                              child: bytes == null
                                  ? const Icon(Icons.child_care, color: Color(0xFF8054A1))
                                  : null,
                            ),
                            title: Text('${d['name'] ?? 'Unknown Child'}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Age: ${d['age'] ?? '-'}  •  Problem: ${d['problemType'] ?? '-'}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => _ChildDetailsScreen(
                                  parentUid: parentUid,
                                  childId: child.id,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}


class _ChildDetailsScreen extends StatelessWidget {
  const _ChildDetailsScreen({
    required this.parentUid,
    required this.childId,
  });

  final String parentUid;
  final String childId;

  @override
  Widget build(BuildContext context) {
    final childRef = FirebaseFirestore.instance
        .collection('users')
        .doc(parentUid)
        .collection('children')
        .doc(childId);

    return AdminPage(
      title: 'Child Details',
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: childRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorView(message: '${snapshot.error}');
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.data!.exists) {
            return const Center(
              child: Text('Child not found.'),
            );
          }

          final data = snapshot.data!.data() ?? {};

          final bytes = _decodePhoto(
            data['photoBase64'] ?? data['base64Photo'],
          );

          final name = (data['name'] ?? 'Unknown Child').toString();

          final goals = data['therapyGoals'];
          final goalsList = goals is List
              ? goals.map((e) => e.toString()).toList()
              : <String>[];

          String display(dynamic value) {
            if (value == null) return '-';
            final text = value.toString().trim();
            return text.isEmpty ? '-' : text;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFFEDE2F5),
                      backgroundImage:
                          bytes == null ? null : MemoryImage(bytes),
                      child: bytes == null
                          ? const Icon(
                              Icons.child_care,
                              size: 42,
                              color: Color(0xFF8054A1),
                            )
                          : null,
                    ),

                    const SizedBox(height: 14),

                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _DetailRow('Age', display(data['age'])),
                    _DetailRow('Gender', display(data['gender'])),

                    _DetailRow(
                      'Date of birth',
                      _formatTimestamp(
                        data['birthDate'] ?? data['dob'],
                      ),
                    ),

                    _DetailRow(
                      'Speech concern',
                      display(
                        data['speechConcern'] ?? data['problemType'],
                      ),
                    ),

                    _DetailRow(
                      'Specific problem',
                      display(
                        data['specificProblem'] ??
                            data['otherProblem'],
                      ),
                    ),

                    _DetailRow(
                      'Target sound',
                      display(data['targetSound']),
                    ),

                    _DetailRow(
                      'Other concern',
                      display(data['otherConcern']),
                    ),

                    _DetailRow(
                      'Therapist',
                      display(data['assignedTherapistName']),
                    ),

                    _DetailRow(
                      'Therapist assigned',
                      _formatTimestamp(data['therapistAssignedAt']),
                    ),

                    _DetailRow(
                      'Profile created',
                      _formatTimestamp(data['createdAt']),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'Therapy Goals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              AdminCard(
                child: goalsList.isEmpty
                    ? const Text('No therapy goals recorded.')
                    : Column(
                        children: goalsList.map((goal) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.check_circle_outline,
                              color: Color(0xFF8054A1),
                            ),
                            title: Text(goal),
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Practice History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: childRef
                    .collection('practiceSessions')
                    .snapshots(),
                builder: (context, sessionSnapshot) {
                  if (sessionSnapshot.hasError) {
                    return _ErrorView(
                      message: '${sessionSnapshot.error}',
                    );
                  }

                  if (!sessionSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final sessions =
                      sessionSnapshot.data!.docs.toList();

                  sessions.sort((a, b) {
                    final at = _asDate(
                      a.data()['finishedAt'],
                    );
                    final bt = _asDate(
                      b.data()['finishedAt'],
                    );

                    return (bt?.millisecondsSinceEpoch ?? 0)
                        .compareTo(
                          at?.millisecondsSinceEpoch ?? 0,
                        );
                  });

                  if (sessions.isEmpty) {
                    return AdminCard(
                      child: const Text(
                        'No practice sessions recorded yet.',
                      ),
                    );
                  }

                  return Column(
                    children: sessions.take(20).map((session) {
                      final d = session.data();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AdminCard(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                display(
                                  d['topic'] ??
                                      d['kind'] ??
                                      'Practice',
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),

                              const SizedBox(height: 10),

                              _DetailRow(
                                'Level',
                                display(d['level']),
                              ),

                              _DetailRow(
                                'Score',
                                display(d['score']),
                              ),

                              _DetailRow(
                                'Stars',
                                display(d['stars']),
                              ),

                              _DetailRow(
                                'Passed',
                                display(d['passedCount']),
                              ),

                              _DetailRow(
                                'Total items',
                                display(d['itemCount']),
                              ),

                              _DetailRow(
                                'Attempts',
                                display(d['tries']),
                              ),

                              _DetailRow(
                                'Completed',
                                _formatTimestamp(d['finishedAt']),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Admin backend creates a temporary signed URL for the PRIVATE bucket.
class _ParentAvatar extends StatefulWidget {
  const _ParentAvatar({required this.parentUid, this.radius = 22});

  final String parentUid;
  final double radius;

  @override
  State<_ParentAvatar> createState() => _ParentAvatarState();
}

class _ParentAvatarState extends State<_ParentAvatar> {
  late Future<String?> _photoFuture;

  @override
  void initState() {
    super.initState();
    _photoFuture = AdminApi.getParentPhotoUrl(widget.parentUid);
  }

  @override
  void didUpdateWidget(covariant _ParentAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parentUid != widget.parentUid) {
      _photoFuture = AdminApi.getParentPhotoUrl(widget.parentUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _photoFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Parent photo fetch error: ${snapshot.error}');
        }
        final url = snapshot.data;
        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: const Color(0xFFEDE2F5),
          foregroundImage: url != null && url.isNotEmpty
              ? NetworkImage(url)
              : null,
          onForegroundImageError: url != null && url.isNotEmpty
              ? (error, stackTrace) {
                  debugPrint('Parent photo image error: $error');
                }
              : null,
          child: Icon(
            Icons.person,
            color: const Color(0xFF8054A1),
            size: widget.radius,
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Center(
        child: Text(message, textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}

DateTime? _asDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String _formatTimestamp(dynamic value) {
  final date = _asDate(value)?.toLocal();
  if (date == null) return 'Not recorded';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} '
      '${two(date.hour)}:${two(date.minute)}';
}

Uint8List? _decodePhoto(dynamic raw) {
  if (raw is! String || raw.trim().isEmpty) return null;
  try {
    return base64Decode(raw.contains(',') ? raw.split(',').last : raw);
  } catch (_) {
    return null;
  }
}
