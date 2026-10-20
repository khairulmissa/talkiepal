import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:talkiepal/games/game_result_page.dart';
import 'package:talkiepal/practice/practice_session.dart';
import 'package:talkiepal/practice/widgets/score_dialog.dart';
import 'package:talkiepal/services/current_kid.dart';

/// One finished practice or game, as saved for the Progress pages.
class SessionRecord {
  static const String practice = 'practice';
  static const String game = 'game';

  /// [practice] or [game].
  final String kind;

  /// "Beginner", "Special Sound"... or "Game".
  final String level;

  /// "Animals", "Sound R", "Minimal Pairs"...
  final String topic;

  /// 0-100: speaking score, right on the first try, or the game's score.
  final int score;
  final int stars;
  final int itemCount;
  final int passedCount;

  /// Times the child spoke or tapped an answer.
  final int tries;
  final Duration time;
  final DateTime finishedAt;

  /// Intermediate questions: scored by being right on the first try.
  final bool isQuiz;

  /// Every word, question or round with how it went.
  final List<Map<String, dynamic>> items;

  /// Games: sounds or words the child mixed up and how often.
  final Map<String, int> mixedUp;

  const SessionRecord({
    required this.kind,
    required this.level,
    required this.topic,
    required this.score,
    required this.stars,
    required this.itemCount,
    required this.passedCount,
    required this.tries,
    required this.time,
    required this.finishedAt,
    this.isQuiz = false,
    this.items = const [],
    this.mixedUp = const {},
  });

  bool get isGame => kind == game;

  /// Words the child said out loud (not questions or games).
  int get wordsSaid => kind == practice && !isQuiz ? items.where((i) => (i['tries'] ?? 0) > 0).length : 0;

  factory SessionRecord.fromPractice(PracticeSession session, {required String level, required String topic}) {
    return SessionRecord(
      kind: practice,
      level: level,
      topic: topic,
      score: session.overallScore,
      stars: ScoreBand.starsFor(session.overallScore),
      itemCount: session.items.length,
      passedCount: session.passedCount,
      tries: session.totalTries,
      time: session.duration,
      finishedAt: DateTime.now(),
      isQuiz: session.isQuiz,
      items: [
        for (final item in session.items)
          {
            'label': item.label,
            if (item.emoji != null) 'emoji': item.emoji,
            'tries': item.tries,
            if (item.bestScore != null) 'score': item.bestScore,
            if (item.heard != null) 'heard': item.heard,
          },
      ],
    );
  }

  factory SessionRecord.fromGame(GameResult result) {
    return SessionRecord(
      kind: game,
      level: 'Game',
      topic: result.title,
      score: result.score,
      stars: ScoreBand.starsFor(result.score),
      itemCount: result.rows.length,
      passedCount: result.rows.where((r) => r.score >= ScoreBand.pass).length,
      tries: 0,
      time: result.time,
      finishedAt: DateTime.now(),
      items: [
        for (final row in result.rows)
          {'lead': row.lead, 'label': row.label, 'detail': row.detail, 'pill': row.pill, 'score': row.score},
        if (result.note != null) {'note': '${result.note!.$1}${result.note!.$2}'},
      ],
      mixedUp: result.mixedUp,
    );
  }

  Map<String, dynamic> toMap() => {
        'kind': kind,
        'level': level,
        'topic': topic,
        'score': score,
        'stars': stars,
        'itemCount': itemCount,
        'passedCount': passedCount,
        'tries': tries,
        'seconds': time.inSeconds,
        'finishedAt': Timestamp.fromDate(finishedAt),
        'isQuiz': isQuiz,
        'items': items,
        'mixedUp': mixedUp,
      };

  factory SessionRecord.fromMap(Map<String, dynamic> map) {
    final finished = map['finishedAt'];
    int number(String key) => (map[key] as num?)?.toInt() ?? 0;

    return SessionRecord(
      kind: map['kind'] as String? ?? practice,
      level: map['level'] as String? ?? '',
      topic: map['topic'] as String? ?? '',
      score: number('score'),
      stars: number('stars'),
      itemCount: number('itemCount'),
      passedCount: number('passedCount'),
      tries: number('tries'),
      time: Duration(seconds: number('seconds')),
      finishedAt: finished is Timestamp ? finished.toDate() : DateTime.fromMillisecondsSinceEpoch(0),
      isQuiz: map['isQuiz'] == true,
      items: [
        for (final item in (map['items'] as List? ?? const []))
          if (item is Map) Map<String, dynamic>.from(item),
      ],
      mixedUp: {
        for (final e in (map['mixedUp'] as Map? ?? const {}).entries)
          if (e.value is num) e.key.toString(): (e.value as num).toInt(),
      },
    );
  }
}

/// A child of the signed-in parent, for the parent's Progress page.
class ChildProfile {
  final String id;
  final String name;
  final Uint8List? photo;

  /// Sound the parent picked to work on, e.g. "R" (null when not picked).
  final String? targetSound;

  const ChildProfile({required this.id, required this.name, this.photo, this.targetSound});
}

/// Saves and loads the children's finished practices and games.
/// Every page uses [ProgressStore.instance], so tests can swap in a fake.
abstract class ProgressStore {
  static ProgressStore instance = FirestoreProgressStore();

  /// Saves a finished session for the current child. Does nothing when no
  /// child is picked.
  Future<void> save(SessionRecord record);

  /// A child's sessions, newest first: the current child's, or [childId]'s
  /// (for the parent's Progress page).
  Future<List<SessionRecord>> sessions({String? childId});

  /// The signed-in parent's children, by name.
  Future<List<ChildProfile>> children();
}

/// Keeps sessions in Firestore under the child:
/// users/{parent}/children/{child}/practiceSessions.
class FirestoreProgressStore implements ProgressStore {
  CollectionReference<Map<String, dynamic>>? get _children {
    final parent = FirebaseAuth.instance.currentUser?.uid;
    if (parent == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(parent).collection('children');
  }

  CollectionReference<Map<String, dynamic>>? _sessionsOf(String? child) {
    if (child == null) return null;
    return _children?.doc(child).collection('practiceSessions');
  }

  @override
  Future<void> save(SessionRecord record) async {
    final collection = _sessionsOf(CurrentKid.id);
    if (collection == null) return;
    try {
      await collection.add({...record.toMap(), 'savedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      // Progress is a bonus: a failed save must never stop the child playing.
      debugPrint('[Progress] could not save: $e');
    }
  }

  @override
  Future<List<SessionRecord>> sessions({String? childId}) async {
    final collection = _sessionsOf(childId ?? CurrentKid.id);
    if (collection == null) return [];
    final snapshot = await collection.orderBy('finishedAt', descending: true).limit(1000).get();
    return [for (final doc in snapshot.docs) SessionRecord.fromMap(doc.data())];
  }

  @override
  Future<List<ChildProfile>> children() async {
    final collection = _children;
    if (collection == null) return [];
    final snapshot = await collection.get();
    final list = [
      for (final doc in snapshot.docs)
        ChildProfile(
          id: doc.id,
          name: (doc.data()['name'] ?? 'Child').toString(),
          photo: _photo(doc.data()['photoBase64']),
          targetSound: _sound(doc.data()['targetSound']),
        ),
    ]..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  static Uint8List? _photo(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    try {
      // Plain Base64 or data:image/jpeg;base64,...
      return base64Decode(raw.contains(',') ? raw.split(',').last : raw);
    } catch (_) {
      return null;
    }
  }

  /// "/r/", "R" or "r" become "R".
  static String? _sound(dynamic raw) {
    final sound = raw?.toString().replaceAll('/', '').trim().toUpperCase() ?? '';
    return sound.isEmpty ? null : sound;
  }
}
