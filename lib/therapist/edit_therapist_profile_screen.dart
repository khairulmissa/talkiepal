import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_auth_service.dart';

import 'therapist_schedule_screen.dart';
import 'therapist_ui.dart';

class EditTherapistProfileScreen extends StatefulWidget {
  const EditTherapistProfileScreen({super.key});

  @override
  State<EditTherapistProfileScreen> createState() =>
      _EditTherapistProfileScreenState();
}

class _EditTherapistProfileScreenState
    extends State<EditTherapistProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _specialization = TextEditingController();
  final _hospital = TextEditingController();
  final _experience = TextEditingController();
  final _bio = TextEditingController();
  final _qualification = TextEditingController();

  bool _isAvailable = true;
  bool _loading = true;
  bool _saving = false;
  Uint8List? _photoBytes;
  Uint8List? _certificateBytes;
  String? _photoPath;
  String? _certificatePath;
  String? _photoUrl;
  String? _certificateUrl;

  static const _purple = TherapistColors.purple;
  static const _ink = TherapistColors.text;
  static const _muted = TherapistColors.muted;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String?> _signedImageUrl(String bucket, String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      return await Supabase.instance.client.storage
          .from(bucket)
          .createSignedUrl(path, 3600);
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Please sign in again.');
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('therapists').doc(uid).get(),
        FirebaseFirestore.instance.collection('users').doc(uid).get(),
      ]);
      final data = results[0].data() ?? <String, dynamic>{};
      final userData = results[1].data() ?? <String, dynamic>{};
      _name.text = (data['fullName'] ?? userData['username'] ?? '').toString();
      _specialization.text = (data['specialization'] ?? '').toString();
      _hospital.text = (data['hospital'] ?? '').toString();
      _experience.text = (data['experienceYears'] ?? '').toString();
      _bio.text = (data['bio'] ?? '').toString();
      _qualification.text = (data['qualification'] ?? '').toString();
      _isAvailable = data['isAvailable'] is bool
          ? data['isAvailable'] as bool
          : true;
      _photoPath = (data['profileImagePath'] ?? data['photoPath'])?.toString();
      _certificatePath = (data['certificatePath'] ?? data['certPath'])?.toString();
      // Profile photos are public; certificates are private.
      _photoUrl = (_photoPath != null && _photoPath!.isNotEmpty)
          ? Supabase.instance.client.storage
              .from('therapist-photos')
              .getPublicUrl(_photoPath!)
          : null;
      if (_certificatePath != null && _certificatePath!.isNotEmpty) {
        try {
          await SupabaseAuthService.enableSupabaseAccess();
          _certificateUrl = await _signedImageUrl(
            'therapist-certificates', _certificatePath);
        } catch (_) {
          // Profile remains editable even if the private preview is unavailable.
          _certificateUrl = null;
        }
      }
    } catch (e) {
      _message('Unable to load profile: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pick({required bool certificate}) async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        _message('Please choose an image smaller than 5 MB.');
        return;
      }
      if (!mounted) return;
      setState(() {
        if (certificate) {
          _certificateBytes = bytes;
        } else {
          _photoBytes = bytes;
        }
      });
    } catch (e) {
      _message('Unable to select image: $e');
    }
  }

  Future<String> _upload(Uint8List bytes, String bucket, String filename) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Please sign in again.');
    final path = '$uid/$filename';
    await Supabase.instance.client.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(upsert: false, contentType: _imageContentType(bytes)),
    );
    return path;
  }

  // Detect the image format so PNG files aren't incorrectly labelled JPEG.
  String _imageContentType(Uint8List bytes) {
    if (bytes.length >= 8 && bytes[0] == 0x89 && bytes[1] == 0x50 &&
        bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'image/jpeg';
    }
    throw const FormatException('Only JPG or PNG images are supported.');
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Please sign in again.');
      if (_photoBytes != null || _certificateBytes != null) {
        await SupabaseAuthService.enableSupabaseAccess();
      }
      if (_photoBytes != null) {
        _photoPath = await _upload(
          _photoBytes!,
          'therapist-photos',
          'profile_${DateTime.now().microsecondsSinceEpoch}.${_imageContentType(_photoBytes!) == 'image/png' ? 'png' : 'jpg'}',
        );
      }
      if (_certificateBytes != null) {
        _certificatePath = await _upload(
          _certificateBytes!,
          'therapist-certificates',
          'certificate_${DateTime.now().microsecondsSinceEpoch}.${_imageContentType(_certificateBytes!) == 'image/png' ? 'png' : 'jpg'}',
        );
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
      _message('Profile saved successfully.');
      Navigator.of(context).pop(true);
    } catch (e) {
      _message('Unable to save profile: $e. Check Supabase authentication and Storage policies.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeAvailabilityStatus() async {
    final choice = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: TherapistColors.cream,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Booking availability',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Are you currently accepting new therapy bookings?',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted)),
            const SizedBox(height: 20),
            _statusChoice(sheetContext, true, 'Available',
                'Parents can request new sessions', Icons.check_circle_outline),
            const SizedBox(height: 10),
            _statusChoice(sheetContext, false, 'Not available',
                'Pause new booking requests', Icons.pause_circle_outline),
          ]),
        ),
      ),
    );
    if (choice == null || !mounted || choice == _isAvailable) return;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Please sign in again.');
      await FirebaseFirestore.instance.collection('therapists').doc(uid).set({
        'isAvailable': choice,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) setState(() => _isAvailable = choice);
    } catch (e) {
      _message('Unable to update availability: $e');
    }
  }

  Widget _statusChoice(BuildContext sheetContext, bool value,
      String title, String subtitle, IconData icon) {
    return InkWell(
      onTap: () => Navigator.pop(sheetContext, value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: value == _isAvailable ? _purple : TherapistColors.border),
        ),
        child: Row(children: [
          Icon(icon, color: _purple),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: _muted)),
          ])),
          if (value == _isAvailable) const Icon(Icons.check_circle, color: _purple),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _name, _specialization, _hospital, _experience, _bio, _qualification,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TherapistColors.background,
      appBar: AppBar(
        backgroundColor: TherapistColors.cream,
        foregroundColor: _ink,
        elevation: 0,
        centerTitle: true,
        title: const Text('Edit Therapist Profile',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _purple))
          : Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _profileHeader(),
                  const SizedBox(height: 18),
                  _availabilityCard(),
                  const SizedBox(height: 18),
                  _sectionCard(
                    icon: Icons.badge_outlined,
                    title: 'Professional information',
                    subtitle: 'How parents will see your therapist profile',
                    children: [
                      _field('Full name', _name, Icons.person_outline,
                          requiredField: true, hint: 'e.g. Dr Sarah'),
                      _field('Specialization', _specialization,
                          Icons.psychology_outlined,
                          hint: 'e.g. Speech-Language Therapist'),
                      _field('Clinic / hospital', _hospital,
                          Icons.local_hospital_outlined,
                          hint: 'Where you practice'),
                      _field('Years of experience', _experience,
                          Icons.work_history_outlined,
                          number: true, hint: 'e.g. 5'),
                      _field('About me', _bio, Icons.notes_outlined,
                          lines: 4, hint: 'Tell parents about your approach...'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _sectionCard(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Qualifications & certification',
                    subtitle: 'Share your professional credentials',
                    children: [
                      _field('Qualifications', _qualification,
                          Icons.school_outlined,
                          lines: 3, hint: 'Degrees, certifications, training...'),
                      _certificatePicker(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: _purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: _saving
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2,
                                  color: Colors.white))
                          : const Icon(Icons.check_circle_outline),
                      label: Text(_saving ? 'Saving profile...' : 'Save Changes',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Your profile details are saved securely.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 12)),
                ],
              ),
            ),
    );
  }

  Widget _profileHeader() {
    ImageProvider? image;
    if (_photoBytes != null) {
      image = MemoryImage(_photoBytes!);
    } else if (_photoUrl != null) {
      image = NetworkImage(_photoUrl!);
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TherapistColors.purple, TherapistColors.deepPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(children: [
        Stack(clipBehavior: Clip.none, children: [
          CircleAvatar(
            radius: 53,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 49,
              backgroundColor: const Color(0xFFF2EAF8),
              backgroundImage: image,
              child: image == null
                  ? const Icon(Icons.person_rounded, size: 52, color: _purple)
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: -3,
            child: Material(
              color: TherapistColors.yellow,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Change profile picture',
                onPressed: () => _pick(certificate: false),
                icon: const Icon(Icons.camera_alt_rounded, color: _ink, size: 20),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        Text(_name.text.trim().isEmpty ? 'Your therapist profile' : _name.text.trim(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        const Text('Tap the camera to update your photo',
            style: TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }

  Widget _availabilityCard() {
    return TherapistCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Availability & schedule',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _actionTile(
            Icons.calendar_month_outlined, 'Manage schedule',
            'Edit available dates',
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TherapistScheduleScreen())),
          )),
          const SizedBox(width: 10),
          Expanded(child: _actionTile(
            _isAvailable ? Icons.check_circle_outline : Icons.pause_circle_outline,
            'Booking status',
            _isAvailable ? 'Available' : 'Not available',
            _changeAvailabilityStatus,
          )),
        ]),
      ]),
    );
  }

  Widget _actionTile(IconData icon, String title, String subtitle,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F0FB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: _purple, size: 24),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700,
              fontSize: 12, color: _ink)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: _muted)),
        ]),
      ),
    );
  }

  Widget _sectionCard({required IconData icon, required String title,
      required String subtitle, required List<Widget> children}) {
    return TherapistCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: const Color(0xFFF2E9F8),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _purple, size: 22),
          ),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(title, style: const TextStyle(fontSize: 15,
                fontWeight: FontWeight.w800, color: _ink)),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11)),
          ])),
        ]),
        const SizedBox(height: 20),
        ...children,
      ]),
    );
  }

  Widget _field(String label, TextEditingController controller, IconData icon,
      {bool requiredField = false, bool number = false,
      int lines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        keyboardType: number
            ? TextInputType.number
            : lines > 1 ? TextInputType.multiline : TextInputType.text,
        inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly] : null,
        textCapitalization: number ? TextCapitalization.none : TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: lines > 1,
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: lines > 1 ? 62 : 0),
            child: Icon(icon, size: 20, color: _purple),
          ),
          filled: true,
          fillColor: const Color(0xFFFCFAFD),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: TherapistColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: TherapistColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: _purple, width: 1.5)),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (requiredField && text.isEmpty) return 'Please enter $label';
          if (number && text.isNotEmpty && int.tryParse(text) == null) {
            return 'Enter a valid number';
          }
          return null;
        },
      ),
    );
  }

  Widget _certificatePicker() {
    final hasCertificate = _certificateBytes != null || _certificatePath != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_certificateBytes != null || _certificateUrl != null) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: _certificateBytes != null
              ? Image.memory(_certificateBytes!, height: 155, fit: BoxFit.contain)
              : Image.network(_certificateUrl!, height: 155, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                      height: 80, child: Center(child: Text('Preview unavailable')))),
        ),
        const SizedBox(height: 12),
      ],
      OutlinedButton.icon(
        onPressed: () => _pick(certificate: true),
        style: OutlinedButton.styleFrom(
          foregroundColor: _purple,
          side: const BorderSide(color: TherapistColors.border),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        ),
        icon: const Icon(Icons.upload_file_outlined),
        label: Text(hasCertificate ? 'Replace certificate image' : 'Upload certificate image'),
      ),
      const SizedBox(height: 6),
      const Text('JPG image, maximum 5 MB',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: _muted)),
    ]);
  }
}
