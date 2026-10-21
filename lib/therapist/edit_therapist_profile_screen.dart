import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'therapist_schedule_screen.dart';

class EditTherapistProfileScreen extends StatefulWidget {
  const EditTherapistProfileScreen({super.key});

  @override
  State<EditTherapistProfileScreen> createState() => _EditTherapistProfileScreenState();
}

class _EditTherapistProfileScreenState extends State<EditTherapistProfileScreen> {
  static const cream = Color(0xFFFFFBF4);
  static const yellow = Color(0xFFF5E5A0);
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _specialization = TextEditingController();
  final _hospital = TextEditingController();
  final _experience = TextEditingController();
  final _bio = TextEditingController();
  final _qualification = TextEditingController();
  bool _isAvailable = true;
  Uint8List? _photoBytes;
  Uint8List? _certificateBytes;
  String? _photoPath;
  String? _certificatePath;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('therapists').doc(uid).get(),
        FirebaseFirestore.instance.collection('users').doc(uid).get(),
      ]);
      final data = results[0].data() ?? {};
      final userData = results[1].data() ?? {};
      _name.text = (data['fullName'] ?? userData['username'] ?? '').toString();
      _specialization.text = (data['specialization'] ?? '').toString();
      _hospital.text = (data['hospital'] ?? '').toString();
      _experience.text = (data['experienceYears'] ?? '').toString();
      _bio.text = (data['bio'] ?? '').toString();
      _qualification.text = (data['qualification'] ?? '').toString();
      _isAvailable = data['isAvailable'] is bool ? data['isAvailable'] as bool : true;
      _photoPath = data['profileImagePath']?.toString();
      _certificatePath = data['certificatePath']?.toString();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Load failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pick({required bool certificate}) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery,
      maxWidth: 1400, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose an image smaller than 5 MB.')));
      return;
    }
    setState(() {
      if (certificate) { _certificateBytes = bytes; } else { _photoBytes = bytes; }
    });
  }

  Future<String> _upload(Uint8List bytes, String bucket, String filename) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final path = '$uid/$filename';
    await Supabase.instance.client.storage.from(bucket).uploadBinary(
      path, bytes,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
    );
    return path;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      if (_photoBytes != null) {
        _photoPath = await _upload(_photoBytes!, 'therapist-photos',
          'profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
      }
      if (_certificateBytes != null) {
        _certificatePath = await _upload(_certificateBytes!, 'therapist-certificates',
          'certificate_${DateTime.now().millisecondsSinceEpoch}.jpg');
      }
      await FirebaseFirestore.instance.collection('therapists').doc(uid).set({
        'fullName': _name.text.trim(),
        'specialization': _specialization.text.trim(),
        'hospital': _hospital.text.trim(),
        'experienceYears': int.tryParse(_experience.text.trim()) ?? 0,
        'bio': _bio.text.trim(),
        'qualification': _qualification.text.trim(),
        'isAvailable': _isAvailable,
        if (_photoPath != null) 'profileImagePath': _photoPath,
        if (_certificatePath != null) 'certificatePath': _certificatePath,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved successfully.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _specialization, _hospital, _experience, _bio, _qualification]) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: cream,
    appBar: AppBar(title: const Text('Edit Profile'), backgroundColor: cream),
    body: _loading ? const Center(child: CircularProgressIndicator()) :
    Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(18), children: [
      Center(child: Stack(clipBehavior: Clip.none, children: [
        Container(width: 145, height: 155, color: Colors.grey.shade200,
          child: _photoBytes == null ? const Icon(Icons.person, size: 100, color: Colors.grey)
            : Image.memory(_photoBytes!, fit: BoxFit.cover)),
        Positioned(right: -8, bottom: -8, child: IconButton.filled(
          onPressed: () => _pick(certificate: false), icon: const Icon(Icons.camera_alt),
          style: IconButton.styleFrom(backgroundColor: Colors.black))),
      ])),
      if (_photoPath != null && _photoBytes == null)
        const Center(child: Padding(padding: EdgeInsets.all(8), child: Text('Current photo saved in Supabase. Select a new one to replace.', style: TextStyle(fontSize: 11)))),
      const SizedBox(height: 22),
      Row(children: [
        Expanded(child: _tile(Icons.calendar_month, 'Availability', 'Edit Schedule', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TherapistScheduleScreen())))),
        const SizedBox(width: 10),
        Expanded(child: _tile(Icons.notifications_active, 'Availability Status', _isAvailable ? 'Available' : 'Not Available', onTap: _changeAvailabilityStatus)),
      ]),
      const SizedBox(height: 22),
      _section('Information'),
      _field('Name', _name, required: true),
      _field('Role / Specialization', _specialization),
      _field('Base / Hospital', _hospital),
      _field('Experience (years)', _experience, number: true),
      _field('About', _bio, lines: 4),
      const SizedBox(height: 4),
      Text('Booking Status: ${_isAvailable ? 'Available' : 'Not Available'}', style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      const SizedBox(height: 12),
      _section('🎓 Qualification'),
      _field('Qualification', _qualification, lines: 3),
      OutlinedButton.icon(onPressed: () => _pick(certificate: true),
        icon: const Icon(Icons.add_photo_alternate),
        label: Text(_certificateBytes == null ? 'Choose certificate image' : 'Certificate image selected')),
      const SizedBox(height: 8),
      if (_certificateBytes != null) Image.memory(_certificateBytes!, height: 150),
      if (_certificatePath != null && _certificateBytes == null)
        const Text('Certificate already uploaded to Supabase.', style: TextStyle(fontSize: 12)),
      const SizedBox(height: 20),
      FilledButton(onPressed: _saving ? null : _save,
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF8B5E9E), padding: const EdgeInsets.all(16)),
        child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes')),
      const SizedBox(height: 20),
    ])),
  );

  Future<void> _changeAvailabilityStatus() async {
    final choice = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Availability Status'),
        content: const Text('Are you accepting new therapy bookings?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Available')),
          FilledButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('Available')),
        ],
      ),
    );
    if (choice == null || !mounted) return;
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('therapists').doc(uid).set({
        'isAvailable': choice,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) setState(() => _isAvailable = choice);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update status: $e')));
    }
  }

  Widget _section(String title) => Padding(padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)));
  Widget _tile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(
    padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: yellow, borderRadius: BorderRadius.circular(12)),
    child: Column(children: [Icon(icon), const SizedBox(height: 4), Text(title, textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      Text(subtitle, style: const TextStyle(fontSize: 10))])));
  Widget _field(String label, TextEditingController controller,
    {bool required = false, bool number = false, int lines = 1}) => Padding(
      padding: const EdgeInsets.only(bottom: 12), child: TextFormField(
        controller: controller, maxLines: lines,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.white,
          border: const OutlineInputBorder()),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) return 'Required';
          if (number && value != null && value.isNotEmpty && (int.tryParse(value) == null || int.parse(value) < 0)) return 'Enter a valid number';
          return null;
        },
      ));
}
