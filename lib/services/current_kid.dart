import 'dart:typed_data';

/// The child profile picked on the kids profile screen.
abstract final class CurrentKid {
  /// Firestore id of the child (`users/{parent}/children/{id}`).
  static String? id;
  static String? name;
  static Uint8List? photo;

  static void select({required String name, String? id, Uint8List? photo}) {
    CurrentKid.id = id;
    CurrentKid.name = name;
    CurrentKid.photo = photo;
  }
}