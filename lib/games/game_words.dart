import 'dart:math';

import 'package:talkiepal/services/exercise_service.dart';

/// Words for one game, plus whether the AI was offline.
class GameWords {
  final String topic;
  final List<PracticeExercise> words;
  final bool isOffline;

  const GameWords(this.topic, this.words, this.isOffline);

  // Beginner topics with words that are easy to show as a picture.
  static const List<String> topics = ['Animals', 'Fruits', 'Vehicles', 'Body Parts', 'Clothes'];

  /// Gets Beginner words from the AI for a random topic in [from].
  /// Repeated words or pictures are dropped, so every choice looks different.
  static Future<GameWords> load({required int count, Random? random, List<String> from = topics}) async {
    final topic = from[(random ?? Random()).nextInt(from.length)];
    final result = await ExerciseService.getExercises(level: 'beginner', topic: topic, count: count);

    final seenWords = <String>{};
    final seenEmojis = <String>{};
    final words = result.exercises.where((e) => seenWords.add(e.word) && seenEmojis.add(e.emoji)).toList();

    return GameWords(topic, words, result.isOffline);
  }
}
