import 'dart:math';

import 'package:talkiepal/config/api_config.dart';
import 'package:talkiepal/services/backend_client.dart';
import 'package:talkiepal/services/exercise_service.dart';

/// Two words that differ by one sound, e.g. CAT and RAT.
class MinimalPair {
  final PracticeExercise a;
  final PracticeExercise b;

  const MinimalPair(this.a, this.b);

  Iterable<String> get words => [a.word, b.word];
}

class MinimalPairResult {
  final List<MinimalPair> pairs;

  /// True when the backend was unreachable and only offline pairs were used.
  final bool isOffline;

  const MinimalPairResult({required this.pairs, required this.isOffline});
}

/// Fetches minimal pairs from the AI backend, topped up with offline pairs.
abstract final class MinimalPairService {
  static const int _recentLimit = 30;

  static const List<(String, String, String, String)> _offlinePairs = [
    ('CAT', '🐱', 'RAT', '🐭'),
    ('FAN', '🪭', 'VAN', '🚐'),
    ('BEAR', '🐻', 'PEAR', '🍐'),
    ('MOUSE', '🐭', 'HOUSE', '🏠'),
    ('SOCK', '🧦', 'ROCK', '🪨'),
    ('BOAT', '🚤', 'GOAT', '🐐'),
    ('RING', '💍', 'KING', '🤴'),
    ('FOX', '🦊', 'BOX', '📦'),
    ('NOSE', '👃', 'ROSE', '🌹'),
    ('TIE', '👔', 'PIE', '🥧'),
    ('MAP', '🗺️', 'CAP', '🧢'),
    ('COAT', '🧥', 'GOAT', '🐐'),
    ('DOG', '🐶', 'LOG', '🪵'),
    ('FISH', '🐟', 'DISH', '🍽️'),
    ('HAT', '👒', 'BAT', '🦇'),
    ('PEN', '🖊️', 'TEN', '🔟'),
    ('SHIP', '🚢', 'SHEEP', '🐑'),
    ('BEE', '🐝', 'TEA', '🍵'),
    ('MOON', '🌙', 'SPOON', '🥄'),
    ('CAKE', '🎂', 'SNAKE', '🐍'),
  ];

  /// Recently shown words, sent to the backend so it avoids repeats.
  static final List<String> _recentWords = [];

  static Future<MinimalPairResult> getPairs({int count = 10}) async {
    final random = Random();
    var pairs = <MinimalPair>[];
    var isOffline = false;

    try {
      final data = await postToBackend(ApiConfig.generateMinimalPairsUrl, {'count': count, 'exclude': _recentWords});

      pairs = [for (final item in data['pairs'] as List) MinimalPair(_parseWord(item['a']), _parseWord(item['b']))];

      _recentWords.addAll(pairs.expand((p) => p.words));
      if (_recentWords.length > _recentLimit) {
        _recentWords.removeRange(0, _recentWords.length - _recentLimit);
      }
    } catch (_) {
      isOffline = true;
    }

    if (pairs.length < count) {
      _topUpWithOffline(pairs, count, random);
    }

    pairs.shuffle(random);
    return MinimalPairResult(pairs: pairs, isOffline: isOffline);
  }

  static void _topUpWithOffline(List<MinimalPair> pairs, int count, Random random) {
    final used = pairs.expand((p) => p.words).toSet();
    final candidates = [..._offlinePairs]..shuffle(random);

    for (final (wordA, emojiA, wordB, emojiB) in candidates) {
      if (pairs.length >= count) break;
      if (used.contains(wordA) || used.contains(wordB)) continue;

      pairs.add(
        MinimalPair(PracticeExercise(word: wordA, emoji: emojiA), PracticeExercise(word: wordB, emoji: emojiB)),
      );
      used.addAll([wordA, wordB]);
    }
  }

  static PracticeExercise _parseWord(dynamic item) {
    return PracticeExercise(word: (item['word'] as String).toUpperCase(), emoji: item['emoji'] as String);
  }
}