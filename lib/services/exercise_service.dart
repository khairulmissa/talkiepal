import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:talkiepal/config/api_config.dart';

class PracticeExercise {
  final String word;
  final String emoji;

  const PracticeExercise({required this.word, required this.emoji});
}

class ExerciseResult {
  final List<PracticeExercise> exercises;

  /// True when the AI could not be reached and offline words were used.
  final bool isOffline;

  const ExerciseResult({required this.exercises, required this.isOffline});
}

/// Gets practice words from the AI backend, with offline words as backup.
class ExerciseService {
  // Backup words with emoji, used when the AI is not available.
  static const Map<String, Map<String, String>> _offlineWords = {
    'Colors': {
      'RED': '🔴', 'BLUE': '🔵', 'GREEN': '🟢', 'YELLOW': '🟡', 'ORANGE': '🟠',
      'PURPLE': '🟣', 'BROWN': '🟤', 'BLACK': '⚫', 'WHITE': '⚪', 'PINK': '🩷',
    },
    'Shapes': {
      'CIRCLE': '⭕', 'SQUARE': '🟦', 'TRIANGLE': '🔺', 'STAR': '⭐', 'HEART': '❤️',
      'DIAMOND': '🔷', 'OVAL': '🥚',
    },
    'Animals': {
      'CAT': '🐱', 'DOG': '🐶', 'COW': '🐮', 'BIRD': '🐦', 'FISH': '🐟',
      'RABBIT': '🐰', 'FROG': '🐸', 'MONKEY': '🐵', 'LION': '🦁', 'ELEPHANT': '🐘',
    },
    'Fruits': {
      'APPLE': '🍎', 'BANANA': '🍌', 'CHERRY': '🍒', 'GRAPE': '🍇', 'MANGO': '🥭',
      'ORANGE': '🍊', 'PEAR': '🍐', 'PINEAPPLE': '🍍', 'STRAWBERRY': '🍓', 'WATERMELON': '🍉',
    },
    'Body Parts': {
      'ARM': '💪', 'EAR': '👂', 'EYES': '👀', 'FINGER': '☝️', 'FOOT': '🦶',
      'HAND': '✋', 'HEAD': '🙂', 'LEG': '🦵', 'MOUTH': '👄', 'NOSE': '👃',
    },
    'Clothes': {
      'DRESS': '👗', 'GLOVES': '🧤', 'HAT': '👒', 'JACKET': '🧥', 'PANTS': '👖',
      'SCARF': '🧣', 'SHIRT': '👕', 'SHOES': '👟', 'SOCKS': '🧦', 'CAP': '🧢',
    },
    'Vehicles': {
      'AIRPLANE': '✈️', 'BICYCLE': '🚲', 'BOAT': '⛵', 'BUS': '🚌', 'CAR': '🚗',
      'HELICOPTER': '🚁', 'MOTORCYCLE': '🏍️', 'TRAIN': '🚆', 'TRUCK': '🚚',
    },
  };

  // Words shown in recent sessions, sent to the AI so it picks new ones.
  static final Map<String, List<String>> _recentWords = {};

  static Future<ExerciseResult> getExercises({
    required String level,
    required String topic,
    int count = 5,
  }) async {
    final key = '$level/$topic';
    final recent = _recentWords[key] ?? [];

    try {
      // Quick check first, so the app does not wait long when the
      // backend cannot be reached (wrong IP, laptop off, other WiFi).
      await http.get(Uri.parse(ApiConfig.healthUrl)).timeout(const Duration(seconds: 3));

      final response = await http
          .post(
            Uri.parse(ApiConfig.generateExercisesUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'level': level,
              'topic': topic,
              'count': count,
              'exclude': recent,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        throw Exception('Backend error ${response.statusCode}');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final exercises = (data['exercises'] as List)
          .map((item) => _buildExercise(item['word'] as String, item['emoji'] as String))
          .toList();

      if (exercises.isEmpty) {
        throw Exception('No exercises returned');
      }

      // Remember the last 20 words for this topic.
      final updated = [...recent, ...exercises.map((e) => e.word)];
      _recentWords[key] = updated.sublist(max(0, updated.length - 20));

      return ExerciseResult(exercises: exercises, isOffline: false);
    } catch (_) {
      return ExerciseResult(exercises: _offlineExercises(topic, count), isOffline: true);
    }
  }

  static PracticeExercise _buildExercise(String word, String emoji) {
    return PracticeExercise(
      word: word.toUpperCase(),
      emoji: emoji.isEmpty ? '⭐' : emoji,
    );
  }

  static List<PracticeExercise> _offlineExercises(String topic, int count) {
    final words = (_offlineWords[topic] ?? {}).entries.toList()..shuffle(Random());
    return words.take(count).map((entry) => _buildExercise(entry.key, entry.value)).toList();
  }
}
