import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';

import 'widgets/parent_form.dart';
import 'widgets/parent_ui.dart';

class AddChildProfileScreen extends StatefulWidget {
  const AddChildProfileScreen({super.key});

  @override
  State<AddChildProfileScreen> createState() => _AddChildProfileScreenState();
}

class _AddChildProfileScreenState extends State<AddChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _otherConcern = TextEditingController();
  final _specificProblem = TextEditingController();
  DateTime? _birthDate;
  String? _gender;
  String? _concern;
  String? _targetSound;
  final Set<String> _goals = {};
  bool _saving = false;
  Uint8List? _photoBytes;

  Future<void> _choosePhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 45,
        maxWidth: 320,
        maxHeight: 320,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > 180 * 1024) {
        if (mounted) _showMessage('This photo is still too large. Please choose a smaller image.');
        return;
      }
      if (mounted) setState(() => _photoBytes = bytes);
    } catch (e) {
      if (mounted) _showMessage('Could not select photo: $e');
    }
  }

  static const concerns = [
    'Speech Sound Disorder',
    'Speech Delay',
    'Autism Spectrum Disorder',
    'Not Diagnosed / Not Sure',
    'Other',
  ];

  static const goalOptions = [
    'Improve Pronunciation',
    'Improve Vocabulary',
    'Improve Sentence Formation',
    'Improve Communication Skills',
    'Improve Speech Clarity',
    'Practice Specific Sounds (R, S, L, TH, SH)',
    'Improve Social Communication',
    'Improve Listening & Understanding',
    'Build Confidence in Speaking',
    'Other / Not Sure',
  ];

  int _ageAt(DateTime birth, DateTime now) {
    var age = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 5, now.month, now.day),
      firstDate: DateTime(now.year - 13),
      lastDate: now,
    );
    if (selected != null && mounted) setState(() => _birthDate = selected);
  }

  String _dateText(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_birthDate == null) {
      _showMessage('Please select the child\'s birth date.');
      return;
    }
    final age = _ageAt(_birthDate!, DateTime.now());
    if (age < 2 || age > 12) {
      _showMessage('TalkiePal supports children aged 2 to 12.');
      return;
    }
    if (_concern == null) {
      _showMessage('Please select a speech or developmental concern.');
      return;
    }
    if (_goals.isEmpty) {
      _showMessage('Please select at least one therapy goal.');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showMessage('Please sign in again.');
      return;
    }
    setState(() => _saving = true);
    try {
      final children = FirebaseFirestore.instance.collection('users').doc(uid).collection('children');
      final childRef = children.doc();
      // Query first for a friendly limit check. Firestore rules should also
      // enforce authorization; a server-side limit is needed for strict enforcement.
      final existing = await children.limit(5).get();
      if (existing.docs.length >= 5) {
        throw StateError('Maximum 5 children per parent.');
      }
      // A small JPEG thumbnail is stored directly in the child document.
      // Base64 increases size by about 33%; keep it well under Firestore's
      // 1 MiB document limit. No Firebase Storage or billing is required.
      final String? photoBase64 = _photoBytes == null ? null : base64Encode(_photoBytes!);
      await childRef.set({
        'parentId': uid,
        'name': _name.text.trim(),
        'birthDate': Timestamp.fromDate(_birthDate!),
        'age': age,
        'gender': _gender,
        'speechConcern': _concern,
        'otherConcern': _concern == 'Other' && _otherConcern.text.trim().isNotEmpty ? _otherConcern.text.trim() : null,
        'specificProblem': _specificProblem.text.trim(),
        'therapyGoals': _goals.toList()..sort(),
        'targetSound': _targetSound,
        'primaryTherapistId': null,
        'photoBase64': photoBase64,
        'photoMimeType': photoBase64 == null ? null : 'image/jpeg',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      await _showSuccess(childRef.id);
    } catch (e) {
      if (mounted) _showMessage('Could not save child: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _showSuccess(String childId) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const CircleAvatar(
          radius: 30,
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.check_rounded, size: 34, color: Color(0xFF43A047)),
        ),
        title: Text(
          '${_name.text.trim()} is added!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, color: ParentColors.ink),
        ),
        content: const Text(
          'The profile is ready for practice. Would you like to find a therapist now?',
          textAlign: TextAlign.center,
          style: TextStyle(color: ParentColors.soft),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context, {'childId': childId, 'findTherapist': false});
            },
            child: const Text('Back to Home', style: TextStyle(color: ParentColors.soft)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ParentColors.purple),
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context, {'childId': childId, 'findTherapist': true});
            },
            child: const Text('Find therapist'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _otherConcern.dispose();
    _specificProblem.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, {String? hint, Widget? suffix}) =>
      parentInputDecoration(label, hint: hint, suffix: suffix);

  /// Small label above a group of choices.
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ParentColors.ink),
    ),
  );

  /// Choices as tappable pills; [selected] decides which are on.
  Widget _choices(
    List<String> options,
    bool Function(String) selected,
    void Function(String) onTap, {
    String Function(String)? label,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          GestureDetector(
            onTap: _saving ? null : () => setState(() => onTap(option)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: selected(option) ? ParentColors.purple : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: selected(option) ? ParentColors.purple : ParentColors.line, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected(option)) ...[
                    const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      label?.call(option) ?? option,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: selected(option) ? Colors.white : ParentColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ParentPage(
        header: const ParentHeader(
          title: 'Add a child',
          subtitle: 'Create a profile for practice and progress',
          back: true,
        ),
        bottom: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: ParentColors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Save child profile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ),
        children: [
          // ---- Photo ----
          ParentCard(
            child: Row(
              children: [
                GestureDetector(
                  onTap: _saving ? null : _choosePhoto,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: ParentColors.yellowLight,
                        backgroundImage: _photoBytes == null ? null : MemoryImage(_photoBytes!),
                        child: _photoBytes == null
                            ? const Icon(Icons.child_care_rounded, size: 38, color: ParentColors.purple)
                            : null,
                      ),
                      const Positioned(
                        bottom: -2,
                        right: -2,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: ParentColors.purple,
                          child: Icon(Icons.photo_camera_rounded, size: 15, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _photoBytes == null ? 'Add a photo' : 'Photo added',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ParentColors.ink),
                      ),
                      const Text(
                        'Optional. Helps your child find their own profile.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ParentColors.soft),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _saving ? null : _choosePhoto,
                        child: Text(
                          _photoBytes == null ? 'Choose photo' : 'Change photo',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ParentColors.purple),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ---- About the child ----
          ParentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ParentSectionTitle('About your child', icon: Icons.person_outline_rounded),
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('Child name *'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter child name' : null,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _saving ? null : _pickDate,
                  child: InputDecorator(
                    decoration: _decoration(
                      'Birth date *',
                      suffix: const Icon(Icons.calendar_month_rounded, color: ParentColors.purple),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _birthDate == null ? 'Select birth date' : _dateText(_birthDate!),
                            style: TextStyle(
                              fontSize: 15,
                              color: _birthDate == null ? ParentColors.muted : ParentColors.ink,
                            ),
                          ),
                        ),
                        if (_birthDate != null)
                          ParentPill('${_ageAt(_birthDate!, DateTime.now())} years', ParentColors.purple),
                      ],
                    ),
                  ),
                ),
                _label('Gender (optional)'),
                _choices(
                  const ['Male', 'Female', 'Prefer not to say'],
                  (g) => _gender == g,
                  (g) => _gender = _gender == g ? null : g,
                ),
              ],
            ),
          ),

          // ---- Speech ----
          ParentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ParentSectionTitle('Speech', icon: Icons.record_voice_over_rounded),
                const Text(
                  'Parent-reported concern; not a medical diagnosis.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ParentColors.soft),
                ),
                _label('Speech or developmental concern *'),
                _choices(concerns, (c) => _concern == c, (c) => _concern = c),
                if (_concern == 'Other') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _otherConcern,
                    enabled: !_saving,
                    decoration: _decoration('Other concern (optional)'),
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: _specificProblem,
                  enabled: !_saving,
                  decoration: _decoration('Specific problem (optional)', hint: 'e.g. Difficulty saying R and S sounds'),
                  maxLines: 3,
                ),
                _label('Target sound (optional)'),
                _choices(
                  const ['R', 'S', 'L', 'TH', 'SH'],
                  (v) => _targetSound == v,
                  (v) => _targetSound = _targetSound == v ? null : v,
                  label: (v) => '/$v/',
                ),
              ],
            ),
          ),

          // ---- Goals ----
          ParentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ParentSectionTitle('Therapy goals *', icon: Icons.flag_outlined),
                const Text(
                  'Select one or more goals.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ParentColors.soft),
                ),
                const SizedBox(height: 12),
                _choices(
                  goalOptions,
                  _goals.contains,
                  (goal) => _goals.contains(goal) ? _goals.remove(goal) : _goals.add(goal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
