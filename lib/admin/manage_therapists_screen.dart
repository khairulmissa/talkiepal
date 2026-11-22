import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_api.dart';
import 'widgets/admin_ui.dart';

class ManageTherapistsScreen extends StatefulWidget {
  const ManageTherapistsScreen({super.key});
  @override
  State<ManageTherapistsScreen> createState() => _ManageTherapistsScreenState();
}

class _ManageTherapistsScreenState extends State<ManageTherapistsScreen> {
  static const cream = Color(0xFFFFFBF4);
  static const purple = Color(0xFF8054A1);
  static const dark = Color(0xFF50336D);
  String search = '';
  String filter = 'All';
  bool busy = false;

  String _value(dynamic v, [String fallback = 'Not provided']) {
    final s = (v ?? '').toString().trim();
    return s.isEmpty ? fallback : s;
  }

  String _name(Map<String, dynamic> therapist, Map<String, dynamic> user) =>
      _value(therapist['fullName'] ?? therapist['name'] ?? user['username'] ?? user['name'], 'Unnamed therapist');

  String? _storageUrl(dynamic path, String bucket) {
    final p = (path ?? '').toString().trim();
    if (p.isEmpty) return null;
    if (p.startsWith('https://') || p.startsWith('http://')) return p;
    // This works only when the Supabase bucket is public.
    return Supabase.instance.client.storage.from(bucket).getPublicUrl(p);
  }

  Widget _avatar(String? url, {double radius = 27}) => CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFF1E8F7),
        backgroundImage: url == null ? null : NetworkImage(url),
        child: url == null ? Icon(Icons.person, color: purple, size: radius) : null,
      );

  InputDecoration _input(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: purple),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  Future<void> _register() async {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final key = GlobalKey<FormState>();
    bool visible = false;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cream,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Register Therapist', style: TextStyle(color: dark, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: key,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircleAvatar(radius: 34, backgroundColor: Color(0xFFF1E8F7), child: Icon(Icons.person_add_alt_1, color: purple, size: 32)),
                  const SizedBox(height: 12),
                  const Text('Therapist will complete professional details after logging in.', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  TextFormField(controller: name, decoration: _input('Full Name', Icons.badge_outlined),
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Enter full name' : null),
                  const SizedBox(height: 12),
                  TextFormField(controller: email, keyboardType: TextInputType.emailAddress,
                    decoration: _input('Email Address', Icons.email_outlined),
                    validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email'),
                  const SizedBox(height: 12),
                  TextFormField(controller: password, obscureText: !visible,
                    decoration: _input('Password', Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => visible = !visible))),
                    validator: (v) => (v ?? '').length < 8 ? 'Minimum 8 characters' : null),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: purple),
              onPressed: () {
                if (key.currentState!.validate()) {
                  Navigator.pop(dialogContext, {
                    'name': name.text.trim(),
                    'email': email.text.trim().toLowerCase(),
                    'password': password.text,
                  });
                }
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
    // Dialog is closed; captured values are already in result.
    name.dispose();
    email.dispose();
    password.dispose();
    if (result == null || !mounted) return;
    setState(() => busy = true);
    try {
      await AdminApi.call('inviteTherapist', result);
      if (mounted) adminMessage(context, 'Therapist registered. Profile verification is pending.');
    } catch (e) {
      if (mounted) adminMessage(context, 'Registration failed: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _action(String uid, String name, String action) async {
    final confirmed = await confirmAdminAction(context,
      '${action[0].toUpperCase()}${action.substring(1)} Therapist',
      'Are you sure you want to $action $name?');
    if (!confirmed || !mounted) return;
    setState(() => busy = true);
    try {
      if (action == 'approve') {
        await AdminApi.call('manageAccount', {'uid': uid, 'action': 'approve'});
      } else {
        await AdminApi.call('manageAccount', {'uid': uid, 'action': action});
      }
      if (mounted) adminMessage(context, 'Action completed successfully.');
    } catch (e) {
      if (mounted) adminMessage(context, 'Action failed: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _info(String label, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: purple, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(_value(value), style: const TextStyle(fontSize: 15, color: dark)),
    ]),
  );

  void _details(String uid) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AdminPage(
      title: 'Therapist Details',
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('therapists').doc(uid).snapshots(),
        builder: (context, therapistSnapshot) {
          if (therapistSnapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Unable to load therapist details.\n${therapistSnapshot.error}',
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            ));
          }
          if (!therapistSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: purple));
          final therapist = therapistSnapshot.data!.data() ?? {};
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.hasError) {
                return Center(child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Unable to load therapist account.\n${userSnapshot.error}',
                    textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                ));
              }
              if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: purple));
              final user = userSnapshot.data!.data() ?? {};
              final name = _name(therapist, user);
              final status = _value(therapist['verificationStatus'] ?? user['verificationStatus'], 'pending');
              final suspended = user['accountStatus'] == 'suspended' || user['isActive'] == false;
              final photo = _storageUrl(therapist['profileImagePath'] ?? therapist['photoUrl'], 'therapist-photos');
                             final certificatePath = _value(
                 therapist['certificatePath'] ?? therapist['certUrl'],
                 '',
               );
return ListView(padding: const EdgeInsets.all(16), children: [
                AdminCard(child: Column(children: [
                  _avatar(photo, radius: 48),
                  const SizedBox(height: 12),
                  Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: dark)),
                  const SizedBox(height: 4),
                  Text(_value(therapist['specialization'], 'Specialization not provided'), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Chip(label: Text(status.toUpperCase()), backgroundColor: const Color.fromARGB(255, 34, 230, 3)),
                ])),
                const SizedBox(height: 14),
                AdminCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Professional Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: dark)),
                  const Divider(),
                  _info('Email', user['email'] ?? therapist['email']),
                  _info('Hospital / Clinic', therapist['hospital'] ?? therapist['clinicName']),
                  _info('Specialization', therapist['specialization']),
                  _info('Years of Experience', therapist['experienceYears'] ?? therapist['yearsOfExperience']),
                  _info('Qualification', therapist['qualification']),
                  _info('Biography', therapist['bio']),
                  _info('Availability', therapist['isAvailable'] == true ? 'Available' : 'Not available'),
                ])),
                const SizedBox(height: 14),
                AdminCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Professional Certificate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: dark)),
                  const SizedBox(height: 12),
                                    if (certificatePath.isEmpty)
                    const Text('No certificate uploaded yet.')
                  else
                    _TherapistCertificatePreview(
                      key: ValueKey('$uid:$certificatePath'),
                      therapistUid: uid,
                      certificatePath: certificatePath,
                    ),
                ])),
                const SizedBox(height: 16),
                if (status == 'pending') ...[
                  AdminActionButton(label: 'Approve Therapist', icon: Icons.verified,
                    onPressed: busy ? null : () => _action(uid, name, 'approve')),
                  const SizedBox(height: 10),
                ],
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _action(uid, name, suspended ? 'reactivate' : 'suspend'),
                  icon: Icon(suspended ? Icons.check_circle_outline : Icons.block),
                  label: Text(suspended ? 'Reactivate Account' : 'Suspend Account'),
                ),
              ]);
            },
          );
        },
      ),
    )));
  }

  @override
  Widget build(BuildContext context) => AdminPage(
    title: 'Manage Therapists',
    actions: [IconButton(onPressed: busy ? null : _register,
      icon: const Icon(Icons.person_add_alt_1), tooltip: 'Register Therapist')],
    child: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        TextField(onChanged: (v) => setState(() => search = v),
          decoration: _input('Search name, email or specialization', Icons.search)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: filter,
          decoration: _input('Filter by status', Icons.filter_list),
          items: ['All', 'pending', 'verified', 'rejected']
            .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => filter = v ?? 'All'),
        ),
      ])),
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('therapists').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Firestore error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.where((doc) {
            final d = doc.data();
            final searchable = '${d['fullName'] ?? d['name'] ?? ''} ${d['email'] ?? ''} ${d['specialization'] ?? ''}'.toLowerCase();
            return searchable.contains(search.toLowerCase()) &&
              (filter == 'All' || d['verificationStatus'] == filter);
          }).toList();
          if (docs.isEmpty) return const Center(child: Text('No therapists found.'));
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final d = doc.data();
              final photo = _storageUrl(d['profileImagePath'] ?? d['photoUrl'], 'therapist-photos');
              return Padding(padding: const EdgeInsets.only(bottom: 12), child: InkWell(
                onTap: () => _details(doc.id),
                borderRadius: BorderRadius.circular(16),
                child: AdminCard(child: Row(children: [
                  _avatar(photo),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_value(d['fullName'] ?? d['name'], 'Unnamed therapist'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: dark)),
                    Text(_value(d['specialization'], 'Profile not completed'),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('Status: ${_value(d['verificationStatus'], 'pending')}',
                      style: const TextStyle(color: purple)),
                  ])),
                  const Icon(Icons.chevron_right, color: purple),
                ])),
              ));
            },
          );
        },
      )),
    ]),
  );
}


/// Fetches an admin-authorized, short-lived signed URL from the Python backend.
/// The private Supabase service-role key never enters the Flutter app.
class _TherapistCertificatePreview extends StatefulWidget {
  final String therapistUid;
  final String certificatePath;

  const _TherapistCertificatePreview({
    super.key,
    required this.therapistUid,
    required this.certificatePath,
  });

  @override
  State<_TherapistCertificatePreview> createState() =>
      _TherapistCertificatePreviewState();
}

class _TherapistCertificatePreviewState
    extends State<_TherapistCertificatePreview> {
  late Future<String> _certificateUrl;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _certificateUrl = AdminApi.getTherapistCertificateUrl(
      widget.therapistUid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = Uri.tryParse(widget.certificatePath)
            ?.path.toLowerCase().endsWith('.pdf') ??
        false;

    return FutureBuilder<String>(
      future: _certificateUrl,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Color(0xFF8054A1)),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Unable to load certificate. Check Admin Backend and certificatePath.'),
              const SizedBox(height: 8),
              Text('${snapshot.error ?? 'No URL returned'}',
                  style: const TextStyle(fontSize: 12, color: Colors.red)),
              TextButton.icon(
                onPressed: () => setState(_refresh),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          );
        }

        final url = snapshot.data!;
        if (isPdf) {
          return const Text(
            'PDF certificate available. A PDF viewer is required for inline preview.',
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            fit: BoxFit.contain,
            height: 250,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Unable to display certificate image.'),
                TextButton.icon(
                  onPressed: () => setState(_refresh),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
