import 'dart:typed_data';

/// The child profile picked on the kids profile screen.
/// Pages read it to show the child's name and photo.
class CurrentKid {
  static String? name;
  static Uint8List? photo;

  static void select({required String name, Uint8List? photo}) {
    CurrentKid.name = name;
    CurrentKid.photo = photo;
  }
}
