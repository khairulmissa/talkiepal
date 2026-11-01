import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParentInfo {
  final String name;
  final String email;

  const ParentInfo({required this.name, required this.email});
}

class UpcomingSession {
  final DateTime when;
  final String therapist;
  final String child;

  const UpcomingSession({required this.when, required this.therapist, required this.child});
}

/// Reads the signed-in parent's account.
///
/// Pages go through [ParentStore.instance] so tests can swap in a fake.
abstract class ParentStore {
  static ParentStore instance = FirestoreParentStore();

  Future<ParentInfo> me();

  /// Booked sessions from now on, soonest first.
  Stream<List<UpcomingSession>> upcomingSessions();

  Future<void> signOut();
}

class FirestoreParentStore implements ParentStore {
  static const Set<String> _closedStatuses = {'cancelled', 'completed'};

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Future<ParentInfo> me() async {
    final user = _auth.currentUser;
    Map<String, dynamic>? data;
    if (user != null) {
      try {
        data = (await _db.collection('users').doc(user.uid).get()).data();
      } catch (_) {
        // Fall back to the auth profile.
      }
    }
    return ParentInfo(name: _displayName(user, data), email: user?.email ?? '');
  }

  /// Saved profile name, else the account name, else the email prefix.
  static String _displayName(User? user, Map<String, dynamic>? data) {
    final saved = (data?['username'] ?? data?['name'] ?? '').toString().trim();
    if (saved.isNotEmpty) return saved;

    final display = user?.displayName?.trim() ?? '';
    if (display.isNotEmpty) return display;

    return user?.email?.split('@').first ?? 'Parent';
  }

  @override
  Stream<List<UpcomingSession>> upcomingSessions() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(const []);

    // Filtered and sorted client-side to avoid needing a composite index.
    return _db.collection('sessions').where('parentId', isEqualTo: user.uid).snapshots().map((snapshot) {
      final now = DateTime.now();
      final sessions = <UpcomingSession>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final scheduledAt = data['scheduledAt'];
        final status = data['status']?.toString().toLowerCase();

        if (scheduledAt is! Timestamp || scheduledAt.toDate().isBefore(now)) continue;
        if (_closedStatuses.contains(status)) continue;

        sessions.add(
          UpcomingSession(
            when: scheduledAt.toDate(),
            therapist: (data['therapistName'] ?? 'To be assigned').toString(),
            child: (data['childName'] ?? 'Not specified').toString(),
          ),
        );
      }

      return sessions..sort((a, b) => a.when.compareTo(b.when));
    });
  }

  @override
  Future<void> signOut() => _auth.signOut();
}