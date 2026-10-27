import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talkiepal/services/parent_store.dart';
import 'package:talkiepal/services/supabase_auth_service.dart';

import 'widgets/parent_form.dart';
import 'widgets/parent_ui.dart';

/// Requires an authenticated Supabase session with Storage RLS permissions.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  DateTime? birthDate;
  Uint8List? photoBytes;
  String? photoUrl;
  bool uploading = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final results = await Future.wait([
        ParentStore.instance.me(),
        FirebaseFirestore.instance.collection('users').doc(uid).get(),
      ]);
      final me = results[0] as ParentInfo;
      final snap = results[1] as DocumentSnapshot<Map<String, dynamic>>;
      final data = snap.data() ?? <String, dynamic>{};
      final storedDate = data['dateOfBirth'];
      final path = data['parentPhotoPath']?.toString();
      String? signedUrl;
      if (path != null && path.isNotEmpty) {
        try {
          signedUrl = await Supabase.instance.client.storage
              .from('parent-photos').createSignedUrl(path, 3600);
        } catch (e) {
          debugPrint('[EditProfile] could not load photo: $e');
        }
      }
      if (!mounted) return;
      setState(() {
        nameController.text = (data['name'] ?? me.name).toString();
        usernameController.text = (data['username'] ?? me.name).toString();
        emailController.text = me.email;
        phoneController.text = (data['phone'] ?? '').toString();
        birthDate = storedDate is Timestamp ? storedDate.toDate() : null;
        photoUrl = signedUrl;
      });
    } catch (e) {
      debugPrint('[EditProfile] could not load: $e');
      if (mounted) _tell('Unable to load profile: $e');
    }
  }

  Future<void> _pickPhoto() async {
    if (uploading || saving) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { _tell('Please sign in first.'); return; }
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 75, maxWidth: 900,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        _tell('Please choose a picture smaller than 2 MB.');
        return;
      }
      if (!mounted) return;
      setState(() => uploading = true);
      // Verify Firebase account and refresh its Supabase-compatible JWT.
      await SupabaseAuthService.enableSupabaseAccess();
      final lower = picked.name.toLowerCase();
      final isPng = lower.endsWith('.png');
      final path = '$uid/profile.${isPng ? 'png' : 'jpg'}';
      final supabase = Supabase.instance.client;
      await supabase.storage.from('parent-photos').uploadBinary(
        path, bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: isPng ? 'image/png' : 'image/jpeg',
        ),
      );
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'parentPhotoPath': path,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      final url = await supabase.storage.from('parent-photos')
          .createSignedUrl(path, 3600);
      if (!mounted) return;
      setState(() { photoBytes = bytes; photoUrl = url; });
      _tell('Profile picture updated successfully.');
    } catch (e) {
      if (mounted) _tell('Photo upload failed: $e');
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (saving || uploading || !formKey.currentState!.validate()) return;
    if (birthDate == null) { _tell('Date of birth is required'); return; }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { _tell('Please sign in first.'); return; }
    setState(() => saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'dateOfBirth': Timestamp.fromDate(birthDate!),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      _tell('Profile updated successfully');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _tell('Could not save profile: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose(); usernameController.dispose();
    emailController.dispose(); phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context, initialDate: birthDate ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 100), lastDate: now,
    );
    if (picked != null && mounted) setState(() => birthDate = picked);
  }

  void _tell(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _required(String label, String? value) =>
      value == null || value.trim().isEmpty ? '$label is required' : null;

  @override
  Widget build(BuildContext context) {
    final name = nameController.text.trim();
    ImageProvider? avatar;
    if (photoBytes != null) {
      avatar = MemoryImage(photoBytes!);
    } else if (photoUrl != null) {
      avatar = NetworkImage(photoUrl!);
    }
    return Form(
      key: formKey,
      child: ParentPage(
        header: ParentHeader(
          title: 'Edit profile', subtitle: 'Keep your details up to date', back: true,
          below: Row(children: [
            Stack(clipBehavior: Clip.none, children: [
              CircleAvatar(
                radius: 34, backgroundColor: ParentColors.yellow,
                backgroundImage: avatar,
                child: avatar == null ? Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                    color: ParentColors.purpleDark),
                ) : null,
              ),
              Positioned(bottom: -2, right: -2,
                child: GestureDetector(
                  onTap: uploading ? null : _pickPhoto,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: ParentColors.purpleLight, width: 2)),
                    child: uploading
                        ? const SizedBox(width: 15, height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.photo_camera_rounded, size: 15,
                            color: ParentColors.purple),
                  ),
                ),
              ),
            ]),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name.isEmpty ? 'Your name' : name, maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                  color: Colors.white)),
              Text(emailController.text, maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: Colors.white70)),
            ])),
          ]),
        ),
        bottom: ParentSaveButton(
          label: saving ? 'Saving...' : 'Save changes',
          onPressed: () { if (!saving && !uploading) _saveProfile(); },
        ),
        children: [
          ParentCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const ParentSectionTitle('Personal details', icon: Icons.person_outline_rounded),
            TextFormField(controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: parentInputDecoration('Name'),
              validator: (v) => _required('Name', v),
              onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            TextFormField(controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: parentInputDecoration('Phone number', hint: 'e.g. 012-345 6789'),
              validator: (v) => _required('Phone number', v)),
            const SizedBox(height: 12),
            GestureDetector(onTap: _pickDate,
              child: InputDecorator(
                decoration: parentInputDecoration('Date of birth',
                  suffix: const Icon(Icons.calendar_month_rounded,
                    color: ParentColors.purple)),
                child: Text(birthDate == null ? 'Select date' :
                  '${birthDate!.day.toString().padLeft(2, '0')}/'
                  '${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}',
                  style: TextStyle(fontSize: 15,
                    color: birthDate == null ? ParentColors.muted : ParentColors.ink)),
              ),
            ),
          ])),
          ParentCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const ParentSectionTitle('Account', icon: Icons.verified_user_outlined),
            TextFormField(controller: usernameController, readOnly: true,
              decoration: parentInputDecoration('Username', locked: true)),
            const SizedBox(height: 12),
            TextFormField(controller: emailController, readOnly: true,
              decoration: parentInputDecoration('Email', locked: true)),
            const SizedBox(height: 8),
            const Text('Username and email are linked to your sign-in and cannot be changed here.',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600,
                color: ParentColors.soft)),
          ])),
        ],
      ),
    );
  }
}
