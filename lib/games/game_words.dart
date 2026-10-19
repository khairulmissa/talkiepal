import 'dart:math';

import 'package:talkiepal/games/picture_words.dart';
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
  /// Only real words from the topic's picture list are kept, each with the
  /// list's picture; the list fills up the rest, so there are always [count].
  static Future<GameWords> load({required int count, Random? random, List<String> from = topics}) async {
    final rng = random ?? Random();
    final topic = from[rng.nextInt(from.length)];
    final result = await ExerciseService.getExercises(level: 'beginner', topic: topic, count: count);

    final words = PictureWords.pick(PictureWords.topics[topic]!, result.exercises, count, rng);

    return GameWords(topic, words, result.isOffline);
  }
}
