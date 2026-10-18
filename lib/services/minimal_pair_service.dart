import 'dart:math';

import 'package:talkiepal/config/api_config.dart';
import 'package:talkiepal/services/backend_client.dart';
import 'package:talkiepal/services/exercise_service.dart';

/// Two words that differ by one sound, e.g. CAT and RAT.
class MinimalPair {
  final PracticeExercise a;
  final PracticeExercise b;

  const MinimalPair(this.a, this.b);
}

class MinimalPairResult {
  final List<MinimalPair> pairs;

  /// True when the AI could not be reached and only offline pairs were used.
  final bool isOffline;

  const MinimalPairResult({required this.pairs, required this.isOffline});
}

/// Gets minimal pairs from the AI backend, topped up with offline pairs.
class MinimalPairService {
  // Backup pairs: [word A, emoji A, word B, emoji B].
  static const List<List<String>> _offlinePairs = [
    ['CAT', '🐱', 'RAT', '🐭'],
    ['FAN', '🪭', 'VAN', '🚐'],
    ['BEAR', '🐻', 'PEAR', '🍐'],
    ['MOUSE', '🐭', 'HOUSE', '🏠'],
    ['SOCK', '🧦', 'ROCK', '🪨'],
    ['BOAT', '🚤', 'GOAT', '🐐'],
    ['RING', '💍', 'KING', '🤴'],
    ['FOX', '🦊', 'BOX', '📦'],
    ['NOSE', '👃', 'ROSE', '🌹'],
    ['TIE', '👔', 'PIE', '🥧'],
    ['MAP', '🗺️', 'CAP', '🧢'],
    ['COAT', '🧥', 'GOAT', '🐐'],
    ['DOG', '🐶', 'LOG', '🪵'],
    ['FISH', '🐟', 'DISH', '🍽️'],
    ['HAT', '👒', 'BAT', '🦇'],
    ['PEN', '🖊️', 'TEN', '🔟'],
    ['SHIP', '🚢', 'SHEEP', '🐑'],
    ['BEE', '🐝', 'TEA', '🍵'],
    ['MOON', '🌙', 'SPOON', '🥄'],
    ['CAKE', '🎂', 'SNAKE', '🐍'],
  ];

  // Words shown in recent games, sent to the AI so it picks new ones.
  static final List<String> _recentWords = [];

  static Future<MinimalPairResult> getPairs({int count = 10}) async {
    final random = Random();
    var pairs = <MinimalPair>[];
    var isOffline = false;

    try {
      final data = await postToBackend(ApiConfig.generateMinimalPairsUrl, {
        'count': count,
        'exclude': _recentWords,
      });

      pairs = (data['pairs'] as List).map((item) {
        return MinimalPair(_word(item['a']), _word(item['b']));
      }).toList();

      _recentWords.addAll(pairs.expand((p) => [p.a.word, p.b.word]));
      if (_recentWords.length > 30) {
        _recentWords.removeRange(0, _recentWords.length - 30);
      }
    } catch (_) {
      isOffline = true;
    }

    // Top up with offline pairs when the AI gave too few.
    if (pairs.length < count) {
      final used = pairs.expand((p) => [p.a.word, p.b.word]).toSet();
      final extra = [..._offlinePairs]..shuffle(random);
      for (final item in extra) {
        if (pairs.length >= count) break;
        if (used.contains(item[0]) || used.contains(item[2])) continue;
        pairs.add(MinimalPair(
          PracticeExercise(word: item[0], emoji: item[1]),
          PracticeExercise(word: item[2], emoji: item[3]),
        ));
        used.addAll([item[0], item[2]]);
      }
    }

    pairs.shuffle(random);
    return MinimalPairResult(pairs: pairs, isOffline: isOffline);
  }

  static PracticeExercise _word(dynamic item) {
    return PracticeExercise(
      word: (item['word'] as String).toUpperCase(),
      emoji: item['emoji'] as String,
    );
  }
}
