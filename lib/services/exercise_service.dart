import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:talkiepal/config/api_config.dart';

class PracticeExercise {
  final String word;
  final String emoji;
  final String? image;

  const PracticeExercise({required this.word, required this.emoji, this.image});
}

class ExerciseResult {
  final List<PracticeExercise> exercises;

  /// True when the AI could not be reached and offline words were used.
  final bool isOffline;

  const ExerciseResult({required this.exercises, required this.isOffline});
}

/// Gets practice words from the AI backend, with offline words as backup.
class ExerciseService {
  // Words that already have a picture in lib/assets/images/<folder>/<word>.png.
  // They are also used as backup when the AI is not available.
  static const Map<String, String> _topicFolders = {
    'Colors': 'colors',
    'Shapes': 'shapes',
    'Animals': 'animals',
    'Fruits': 'fruits',
    'Body Parts': 'bodyparts',
    'Clothes': 'clothes',
    'Vehicles': 'vehicles',
  };

  static const Map<String, List<String>> _topicImageWords = {
    'Colors': ['black', 'blue', 'brown', 'green', 'orange', 'pink', 'purple', 'red', 'white', 'yellow'],
    'Shapes': ['circle', 'diamond', 'heart', 'hexagon', 'oval', 'pentagon', 'rectangle', 'square', 'star', 'triangle'],
    'Animals': ['bird', 'cat', 'cow', 'dog', 'elephant', 'fish', 'frog', 'lion', 'monkey', 'rabbit'],
    'Fruits': ['apple', 'banana', 'cherry', 'grape', 'mango', 'orange', 'pear', 'pineapple', 'strawberry', 'watermelon'],
    'Body Parts': ['arm', 'ear', 'eyes', 'finger', 'foot', 'hand', 'head', 'leg', 'mouth', 'nose'],
    'Clothes': ['dress', 'gloves', 'hat', 'jacket', 'pants', 'scarf', 'shirt', 'shoes', 'skirt', 'socks'],
    'Vehicles': ['airplane', 'bicycle', 'boat', 'bus', 'car', 'helicopter', 'motorcycle', 'train', 'truck'],
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
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw Exception('Backend error ${response.statusCode}');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final exercises = (data['exercises'] as List)
          .map((item) => _buildExercise(topic, item['word'] as String, item['emoji'] as String))
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

  static PracticeExercise _buildExercise(String topic, String word, String emoji) {
    final folder = _topicFolders[topic];
    final lower = word.toLowerCase();
    final hasImage = folder != null && (_topicImageWords[topic]?.contains(lower) ?? false);

    return PracticeExercise(
      word: word.toUpperCase(),
      emoji: emoji.isEmpty ? '⭐' : emoji,
      image: hasImage ? 'lib/assets/images/$folder/$lower.png' : null,
    );
  }

  static List<PracticeExercise> _offlineExercises(String topic, int count) {
    final words = [...?_topicImageWords[topic]]..shuffle(Random());
    return words.take(count).map((word) => _buildExercise(topic, word, '⭐')).toList();
  }
}
