import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';

class AddChildProfileScreen extends StatefulWidget {
  const AddChildProfileScreen({super.key});

  @override
  State<AddChildProfileScreen> createState() => _AddChildProfileScreenState();
}

class _AddChildProfileScreenState extends State<AddChildProfileScreen> {
  static const cream = Color(0xFFF5EFE8);
  static const yellow = Color(0xFFFFEFA8);
  static const purple = Color(0xFF8B5E9E);

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
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
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
      final children = FirebaseFirestore.instance
          .collection('users').doc(uid).collection('children');
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
      final String? photoBase64 = _photoBytes == null
          ? null
          : base64Encode(_photoBytes!);
      await childRef.set({
        'parentId': uid,
        'name': _name.text.trim(),
        'birthDate': Timestamp.fromDate(_birthDate!),
        'age': age,
        'gender': _gender,
        'speechConcern': _concern,
        'otherConcern': _concern == 'Other' && _otherConcern.text.trim().isNotEmpty
            ? _otherConcern.text.trim() : null,
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
        title: const Text('Profile successfully created!'),
        content: const Text('Your child has been added. Would you like to find a therapist now?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context, {'childId': childId, 'findTherapist': false});
            },
            child: const Text('Back to Dashboard'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context, {'childId': childId, 'findTherapist': true});
            },
            child: const Text('Find Therapist'),
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

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: yellow,
        title: const Text('Create Child Profile'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: InkWell(
                  onTap: _saving ? null : _choosePhoto,
                  borderRadius: BorderRadius.circular(60),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: yellow,
                        backgroundImage: _photoBytes == null
                            ? null
                            : MemoryImage(_photoBytes!),
                        child: _photoBytes == null
                            ? const Icon(Icons.add_a_photo, size: 42, color: purple)
                            : null,
                      ),
                      const Positioned(
                        bottom: 0,
                        right: -2,
                        child: CircleAvatar(
                          radius: 17,
                          backgroundColor: purple,
                          child: Icon(Icons.edit, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(child: Text('Tap to choose a child photo (optional)',
                style: TextStyle(color: Colors.black54, fontSize: 12))),
              const SizedBox(height: 24),
              const Text('Personal Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration('Child Name *'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter child name' : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _saving ? null : _pickDate,
                child: InputDecorator(
                  decoration: _decoration('Birth Date *'),
                  child: Row(children: [
                    Expanded(child: Text(_birthDate == null
                        ? 'Select birth date' : _dateText(_birthDate!))),
                    const Icon(Icons.calendar_month),
                  ]),
                ),
              ),
              if (_birthDate != null) Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Age: ${_ageAt(_birthDate!, DateTime.now())} years'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: _decoration('Gender (optional)'),
                value: _gender,
                items: ['Male', 'Female', 'Prefer not to say']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: _saving ? null : (value) => setState(() => _gender = value),
              ),
              const SizedBox(height: 26),
              const Text('Speech Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Parent-reported concern; not a medical diagnosis.',
                style: TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: _decoration('Speech / Developmental Concern *'),
                value: _concern,
                isExpanded: true,
                items: concerns.map((v) => DropdownMenuItem(
                  value: v, child: Text(v, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: _saving ? null : (value) => setState(() => _concern = value),
                validator: (value) => value == null ? 'Select a concern' : null,
              ),
              if (_concern == 'Other') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _otherConcern,
                  decoration: _decoration('Other Concern (optional)'),
                  maxLines: 2,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _specificProblem,
                decoration: _decoration('Specific Problem (optional)',
                    hint: 'e.g. Difficulty saying R and S sounds'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: _decoration('Target Sound (optional)'),
                value: _targetSound,
                items: ['R', 'S', 'L', 'TH', 'SH'].map((v) =>
                  DropdownMenuItem(value: v, child: Text('/$v/'))).toList(),
                onChanged: _saving ? null : (value) => setState(() => _targetSound = value),
              ),
              const SizedBox(height: 26),
              const Text('Therapy Goals *',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Select one or more goals.',
                style: TextStyle(color: Colors.black54)),
              ...goalOptions.map((goal) => CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: purple,
                title: Text(goal, style: const TextStyle(fontSize: 13)),
                value: _goals.contains(goal),
                onChanged: _saving ? null : (checked) => setState(() {
                  if (checked == true) {
                    _goals.add(goal);
                  } else {
                    _goals.remove(goal);
                  }
                }),
              )),
              const SizedBox(height: 18),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor: Colors.black,
                  ),
                  child: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Child Profile',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
