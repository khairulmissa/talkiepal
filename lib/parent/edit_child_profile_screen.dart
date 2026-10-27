import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Change this import only if your service has a different filename.
import '../services/supabase_auth_service.dart';

class EditChildProfileScreen extends StatefulWidget {
  final String childId;
  final Map<String, dynamic> initialData;
  const EditChildProfileScreen({super.key, required this.childId, required this.initialData});

  @override
  State<EditChildProfileScreen> createState() => _EditChildProfileScreenState();
}

class _EditChildProfileScreenState extends State<EditChildProfileScreen> {
  static const purple = Color(0xFF8154AA);
  static const cream = Color(0xFFFFFBF4);
  static const yellow = Color(0xFFFFEFA8);
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name, sound, concern, problem, goals, notes;
  Uint8List? photo;
  bool photoChanged = false;
  bool saving = false;
  DateTime? dob;
  String? existingPhotoPath;
  String? existingPhotoUrl;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    String value(String key) => (d[key] ?? '').toString();
    name = TextEditingController(text: value('name'));
    sound = TextEditingController(text: value('targetSound'));
    concern = TextEditingController(text: value('speechConcern'));
    problem = TextEditingController(text: value('specificProblem'));
    notes = TextEditingController(text: value('notes'));
    final rawGoals = d['therapyGoals'];
    goals = TextEditingController(text: rawGoals is List ? rawGoals.join('\n') : '');
    final rawDob = d['dob'] ?? d['dateOfBirth'] ?? d['birthDate'];
    if (rawDob is Timestamp) dob = rawDob.toDate();
    if (rawDob is DateTime) dob = rawDob;
    if (rawDob is String) dob = DateTime.tryParse(rawDob);
    final encoded = d['base64Photo'] ?? d['photoBase64'];
    if (encoded is String && encoded.isNotEmpty) {
      try { photo = base64Decode(encoded.contains(',') ? encoded.split(',').last : encoded); } catch (_) {}
    }
    existingPhotoPath = d['childPhotoPath']?.toString();
    if (existingPhotoPath != null && existingPhotoPath!.isNotEmpty) {
      _loadExistingPhoto();
    }
  }

  Future<void> _loadExistingPhoto() async {
    try {
      final url = await Supabase.instance.client.storage
          .from('child-photos').createSignedUrl(existingPhotoPath!, 3600);
      if (mounted) setState(() => existingPhotoUrl = url);
    } catch (e) {
      debugPrint('Could not load child photo: $e');
    }
  }

  @override
  void dispose() {
    for (final c in [name, sound, concern, problem, goals, notes]) { c.dispose(); }
    super.dispose();
  }

  Future<void> choosePhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 65,
        maxWidth: 720, maxHeight: 720,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo too large. Please choose a smaller image.')));
        return;
      }
      if (mounted) setState(() { photo = bytes; photoChanged = true; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not select photo: $e')));
    }
  }

  Future<void> pickDob() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context, initialDate: dob ?? DateTime(now.year - 4),
      firstDate: DateTime(2000), lastDate: now,
    );
    if (date != null && mounted) setState(() => dob = date);
  }

  int get age {
    if (dob == null) return 0;
    final now = DateTime.now();
    var years = now.year - dob!.year;
    if (now.month < dob!.month || (now.month == dob!.month && now.day < dob!.day)) years--;
    return years;
  }

  Future<void> save() async {
    if (saving || !formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => saving = true);
    try {
      final data = <String, dynamic>{
        'name': name.text.trim(),
        'targetSound': sound.text.trim().toUpperCase(),
        'speechConcern': concern.text.trim(),
        'specificProblem': problem.text.trim(),
        'therapyGoals': goals.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        'notes': notes.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (dob != null) {
        data['dob'] = Timestamp.fromDate(dob!);
        data['age'] = age;
      }
      if (photoChanged && photo != null) {
        // This service provisions the Firebase custom claim for Supabase Storage.
        await SupabaseAuthService.enableSupabaseAccess();
        await FirebaseAuth.instance.currentUser!.getIdToken(true);
        final path = '$uid/${widget.childId}/profile.jpg';
        await Supabase.instance.client.storage.from('child-photos').uploadBinary(
          path,
          photo!,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
        data['childPhotoPath'] = path;
        // Remove the old Base64 image only after Supabase upload succeeds.
        data['base64Photo'] = FieldValue.delete();
        data['photoBase64'] = FieldValue.delete();
      }
      await FirebaseFirestore.instance.collection('users').doc(uid)
          .collection('children').doc(widget.childId).update(data);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save child profile: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget field(String label, TextEditingController controller,
      {int lines = 1, String? hint, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller, maxLines: lines,
        validator: required ? (v) => v == null || v.trim().isEmpty ? '$label is required' : null : null,
        decoration: InputDecoration(
          labelText: label, hintText: hint, alignLabelWithHint: lines > 1,
          filled: true, fillColor: cream,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: purple, width: 1.5)),
        ),
      ),
    );
  }

  Widget section(String title, IconData icon, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: purple, size: 21), const SizedBox(width: 9),
        Text(title, style: const TextStyle(color: purple, fontSize: 17, fontWeight: FontWeight.bold))]),
      const SizedBox(height: 18), ...children,
    ]),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: cream,
    appBar: AppBar(title: const Text('Edit Child Profile'), backgroundColor: purple,
      foregroundColor: Colors.white),
    body: Form(key: formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(color: purple, borderRadius: BorderRadius.circular(24)),
        child: Column(children: [
          Stack(children: [
            CircleAvatar(radius: 53, backgroundColor: yellow,
              backgroundImage: photoChanged && photo != null
                  ? MemoryImage(photo!)
                  : existingPhotoUrl != null
                      ? NetworkImage(existingPhotoUrl!)
                      : photo != null ? MemoryImage(photo!) : null,
              child: photo == null && existingPhotoUrl == null
                  ? const Icon(Icons.child_care_rounded, size: 55, color: purple) : null),
            Positioned(bottom: 0, right: 0,
              child: CircleAvatar(radius: 18, backgroundColor: Colors.white,
                child: IconButton(icon: const Icon(Icons.camera_alt, color: purple, size: 19),
                  onPressed: choosePhoto, padding: EdgeInsets.zero))),
          ]),
          const SizedBox(height: 10),
          const Text('Child Profile Photo', style: TextStyle(color: Colors.white,
            fontWeight: FontWeight.bold, fontSize: 17)),
          TextButton.icon(onPressed: choosePhoto,
            icon: const Icon(Icons.photo_library_outlined, color: yellow),
            label: const Text('Choose from gallery', style: TextStyle(color: yellow))),
        ])),
      const SizedBox(height: 16),
      section('Personal Information', Icons.person_outline, [
        field('Child Name', name, required: true),
        InkWell(onTap: pickDob,
          child: InputDecorator(decoration: InputDecoration(labelText: 'Date of Birth',
            filled: true, fillColor: cream,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            suffixIcon: const Icon(Icons.calendar_month, color: purple)),
            child: Text(dob == null ? 'Tap to select date'
                : '${dob!.day}/${dob!.month}/${dob!.year}  •  $age years old'))),
      ]),
      section('Speech Therapy Details', Icons.record_voice_over_outlined, [
        field('Target Sound', sound, hint: 'R, S, L, TH, SH'),
        field('Speech Concern', concern, hint: 'e.g. Speech Delay'),
        field('Specific Problem', problem, hint: 'Describe the difficulty'),
      ]),
      section('Therapy Goals', Icons.flag_outlined, [
        field('Goals (one per line)', goals, lines: 4,
          hint: 'Improve Communication Skills\nImprove Speech Clarity'),
      ]),
      section('Additional Notes', Icons.notes_rounded, [
        field('Notes', notes, lines: 4, hint: 'Anything the therapist should know'),
      ]),
      const SizedBox(height: 12),
    ])),
    bottomNavigationBar: SafeArea(child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: SizedBox(height: 52, child: FilledButton.icon(
        onPressed: saving ? null : save,
        icon: saving ? const SizedBox(width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.save_outlined),
        label: Text(saving ? 'Saving...' : 'Save Changes'),
        style: FilledButton.styleFrom(backgroundColor: purple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      )),
    )),
  );
}
