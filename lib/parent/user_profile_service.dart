import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Saves a profile without overwriting the role chosen elsewhere in the app.
class UserProfileService {
  static Future<void> syncUser(User user, {String? username}) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await ref.get();
    final existing = snapshot.data() ?? <String, dynamic>{};

    final suppliedName = username?.trim() ?? '';
    final authName = user.displayName?.trim() ?? '';
    final oldName = (existing['username'] ?? '').toString().trim();
    final emailName = (user.email ?? '').split('@').first;
    final name = suppliedName.isNotEmpty
        ? suppliedName
        : oldName.isNotEmpty
            ? oldName
            : authName.isNotEmpty
                ? authName
                : emailName.isNotEmpty ? emailName : 'TalkiePal User';

    final data = <String, dynamic>{
      'username': name,
      'email': user.email ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!snapshot.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['role'] = 'parent';
    }
    await ref.set(data, SetOptions(merge: true));
  }

  /// Call from ChooseRoleScreen only after the user selects a role.
  static Future<void> saveRole(String role) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw StateError('Please sign in first.');
  }

  if (role != 'parent') {
    throw StateError(
      'Therapist and admin roles must be assigned by an administrator.',
    );
  }
    await FirebaseFirestore.instance.collection('users').doc(user.uid)
        .set({'role': 'parent', 'updatedAt': FieldValue.serverTimestamp()},
             SetOptions(merge: true));
  }
}
