import 'dart:typed_data';

/// The child profile picked on the kids profile screen.
/// Pages read it to show the child's name and photo, and to save the
/// child's practice under their profile.
class CurrentKid {
  /// Firestore id of the child (users/{parent}/children/{id}).
  static String? id;
  static String? name;
  static Uint8List? photo;

  static void select({required String name, String? id, Uint8List? photo}) {
    CurrentKid.id = id;
    CurrentKid.name = name;
    CurrentKid.photo = photo;
  }
}
