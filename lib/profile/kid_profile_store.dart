import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/current_kid.dart';
import '../services/supabase_auth_service.dart';

/// Reads and saves the profile of the child in [CurrentKid]
/// (users/{parent}/children/{id}) for the kids Profile pages.
class KidProfileStore {
  static DocumentReference<Map<String, dynamic>>? get _ref {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final childId = CurrentKid.id;
    if (uid == null || childId == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('children').doc(childId);
  }

  /// The child's saved data, or an empty map when there is no child or no sign-in.
  static Future<Map<String, dynamic>> load() async {
    final ref = _ref;
    if (ref == null) return {};
    final snapshot = await ref.get();
    return snapshot.data() ?? {};
  }

  /// Saves the practice reminder switch and the language choice.
  static Future<void> savePreferences({bool? practiceReminders, String? language}) async {
    final ref = _ref;
    if (ref == null) throw StateError('Please choose a child profile first.');
    await ref.update({
      'practiceReminders': ?practiceReminders,
      'language': ?language,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Saves a new name and, when given, a new photo, then updates [CurrentKid].
  /// The photo goes to the same Supabase place as the parent's Edit Child Profile.
  static Future<void> saveNameAndPhoto({required String name, Uint8List? photo}) async {
    final ref = _ref;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (ref == null || uid == null) throw StateError('Please choose a child profile first.');

    final data = <String, dynamic>{
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (photo != null) {
      await SupabaseAuthService.enableSupabaseAccess();
      final path = '$uid/${ref.id}/profile.jpg';
      await Supabase.instance.client.storage.from('child-photos').uploadBinary(
            path,
            photo,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      data['childPhotoPath'] = path;
      data['base64Photo'] = FieldValue.delete();
      data['photoBase64'] = FieldValue.delete();
    }
    await ref.update(data);
    CurrentKid.select(name: name, id: ref.id, photo: photo ?? CurrentKid.photo);
  }
}
