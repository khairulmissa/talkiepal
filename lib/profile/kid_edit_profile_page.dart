import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/current_kid.dart';
import '../widgets/dino_mascot.dart';
import 'kid_page_ui.dart';
import 'kid_profile_store.dart';

/// Lets the child change the name and photo shown in the app.
class KidEditProfilePage extends StatefulWidget {
  const KidEditProfilePage({super.key});

  @override
  State<KidEditProfilePage> createState() => _KidEditProfilePageState();
}

class _KidEditProfilePageState extends State<KidEditProfilePage> {
  final _name = TextEditingController(text: CurrentKid.name ?? '');
  Uint8List? _newPhoto;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 65,
        maxWidth: 720,
        maxHeight: 720,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        _tell('That photo is too big. Please pick another one.');
        return;
      }
      if (mounted) setState(() => _newPhoto = bytes);
    } catch (e) {
      _tell('Could not open photos: $e');
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _tell('Please type your name.');
      return;
    }
    setState(() => _saving = true);
    try {
      await KidProfileStore.saveNameAndPhoto(name: name, photo: _newPhoto);
      if (!mounted) return;
      _tell('Saved! Looking good, $name! 🌟');
      Navigator.pop(context, true);
    } catch (e) {
      _tell('Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _tell(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), backgroundColor: const Color(0xFF8B5E9E)));
  }

  @override
  Widget build(BuildContext context) {
    final photo = _newPhoto ?? CurrentKid.photo;
    final unchanged = _newPhoto == null && _name.text.trim() == (CurrentKid.name ?? '').trim();

    return KidSubPage(
      emoji: '✏️',
      title: 'Edit Profile',
      bottom: KidButton(label: 'Save', busy: _saving, onPressed: unchanged ? null : _save),
      children: [
        KidCard(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              GestureDetector(
                onTap: _saving ? null : _choosePhoto,
                child: Stack(
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFD54F), width: 4),
                      ),
                      child: photo != null
                          ? ClipOval(child: Image.memory(photo, fit: BoxFit.cover))
                          : const DinoMascot(color: Color(0xFFB794F6), size: 100),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: KidColors.plum, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _saving ? null : _choosePhoto,
                child: const Text(
                  '🖼️ Choose a photo',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: KidColors.plum),
                ),
              ),
            ],
          ),
        ),
        KidCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '😊 My name',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: KidColors.ink),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _name,
                enabled: !_saving,
                maxLength: 20,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: KidColors.ink),
                decoration: InputDecoration(
                  hintText: 'Type your name',
                  filled: true,
                  fillColor: const Color(0xFFF3E5F5),
                  counterText: '',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: KidColors.plum, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
