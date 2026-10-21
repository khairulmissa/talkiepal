import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The signed-in parent, for the parent Home and Profile pages.
class ParentInfo {
  final String name;
  final String email;

  const ParentInfo({required this.name, required this.email});
}

/// A booked therapy session.
class UpcomingSession {
  final DateTime when;
  final String therapist;
  final String child;

  const UpcomingSession({required this.when, required this.therapist, required this.child});
}

/// Reads the signed-in parent's account. Every page uses
/// [ParentStore.instance], so tests can swap in a fake.
abstract class ParentStore {
  static ParentStore instance = FirestoreParentStore();

  Future<ParentInfo> me();

  /// Booked sessions from now on, soonest first.
  Stream<List<UpcomingSession>> upcomingSessions();

  Future<void> signOut();
}

class FirestoreParentStore implements ParentStore {
  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  Future<ParentInfo> me() async {
    final user = _user;
    Map<String, dynamic>? data;
    if (user != null) {
      try {
        data = (await FirebaseFirestore.instance.collection('users').doc(user.uid).get()).data();
      } catch (_) {
        // Fall back to the account name below.
      }
    }
    return ParentInfo(name: _name(user, data), email: user?.email ?? '');
  }

  /// Name saved in the profile, else the account name, else the email.
  static String _name(User? user, Map<String, dynamic>? data) {
    final saved = (data?['username'] ?? data?['name'] ?? '').toString().trim();
    if (saved.isNotEmpty) return saved;
    final display = user?.displayName?.trim() ?? '';
    if (display.isNotEmpty) return display;
    return user?.email?.split('@').first ?? 'Parent';
  }

  @override
  Stream<List<UpcomingSession>> upcomingSessions() {
    final user = _user;
    if (user == null) return Stream.value(const []);
    // Filtered and sorted on the phone, so no composite index is needed.
    return FirebaseFirestore.instance.collection('sessions').where('parentId', isEqualTo: user.uid).snapshots().map((
      snapshot,
    ) {
      final now = DateTime.now();
      final list = <UpcomingSession>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final date = data['scheduledAt'];
        final status = data['status']?.toString().toLowerCase();
        if (date is! Timestamp || date.toDate().isBefore(now)) continue;
        if (status == 'cancelled' || status == 'completed') continue;
        list.add(
          UpcomingSession(
            when: date.toDate(),
            therapist: (data['therapistName'] ?? 'To be assigned').toString(),
            child: (data['childName'] ?? 'Not specified').toString(),
          ),
        );
      }
      return list..sort((a, b) => a.when.compareTo(b.when));
    });
  }

  @override
  Future<void> signOut() => FirebaseAuth.instance.signOut();
}
