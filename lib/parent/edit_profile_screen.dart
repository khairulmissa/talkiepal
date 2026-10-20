import 'package:flutter/material.dart';
import 'package:talkiepal/services/parent_store.dart';

import 'widgets/parent_form.dart';
import 'widgets/parent_ui.dart';

/// Edit the parent's own details.
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await ParentStore.instance.me();
      if (!mounted) return;
      setState(() {
        if (nameController.text.isEmpty) nameController.text = me.name;
        usernameController.text = me.name;
        emailController.text = me.email;
      });
    } catch (e) {
      debugPrint('[EditProfile] could not load: $e');
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null && mounted) setState(() => birthDate = picked);
  }

  void saveProfile() {
    if (!formKey.currentState!.validate()) return;
    if (birthDate == null) {
      _tell('Date of birth is required');
      return;
    }
    _tell('Profile updated successfully');
    Navigator.pop(context);
  }

  void _tell(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  String? _required(String label, String? value) => value == null || value.trim().isEmpty ? '$label is required' : null;

  @override
  Widget build(BuildContext context) {
    final name = nameController.text.trim();

    return Form(
      key: formKey,
      child: ParentPage(
        header: ParentHeader(
          title: 'Edit profile',
          subtitle: 'Keep your details up to date',
          back: true,
          below: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: ParentColors.yellow,
                    child: Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: ParentColors.purpleDark),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: GestureDetector(
                      onTap: () => _tell('Changing your photo is coming soon.'),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: ParentColors.purpleLight, width: 2),
                        ),
                        child: const Icon(Icons.photo_camera_rounded, size: 15, color: ParentColors.purple),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Your name' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    Text(
                      emailController.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottom: ParentSaveButton(label: 'Save changes', onPressed: saveProfile),
        children: [
          ParentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ParentSectionTitle('Personal details', icon: Icons.person_outline_rounded),
                TextFormField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: parentInputDecoration('Name'),
                  validator: (v) => _required('Name', v),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: parentInputDecoration('Phone number', hint: 'e.g. 012-345 6789'),
                  validator: (v) => _required('Phone number', v),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: parentInputDecoration(
                      'Date of birth',
                      suffix: const Icon(Icons.calendar_month_rounded, color: ParentColors.purple),
                    ),
                    child: Text(
                      birthDate == null
                          ? 'Select date'
                          : '${birthDate!.day.toString().padLeft(2, '0')}/'
                                '${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}',
                      style: TextStyle(fontSize: 15, color: birthDate == null ? ParentColors.muted : ParentColors.ink),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ParentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ParentSectionTitle('Account', icon: Icons.verified_user_outlined),
                TextFormField(
                  controller: usernameController,
                  readOnly: true,
                  decoration: parentInputDecoration('Username', locked: true),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  readOnly: true,
                  decoration: parentInputDecoration('Email', locked: true),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Username and email are linked to your sign-in and cannot be changed here.',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: ParentColors.soft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
