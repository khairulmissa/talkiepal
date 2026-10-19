import 'dart:math';

import 'package:talkiepal/services/exercise_service.dart';

/// Real food words, each with the one picture that shows it.
/// The AI sometimes makes up words (MUMMUSO) or cuts them (STRAW), so only
/// words from this list are used, always with this list's picture.
class FoodWords {
  static const Map<String, String> all = {
    'APPLE': '🍎',
    'BANANA': '🍌',
    'GRAPES': '🍇',
    'ORANGE': '🍊',
    'LEMON': '🍋',
    'WATERMELON': '🍉',
    'STRAWBERRY': '🍓',
    'CHERRY': '🍒',
    'PEAR': '🍐',
    'PEACH': '🍑',
    'PINEAPPLE': '🍍',
    'MANGO': '🥭',
    'KIWI': '🥝',
    'COCONUT': '🥥',
    'CARROT': '🥕',
    'CORN': '🌽',
    'BROCCOLI': '🥦',
    'TOMATO': '🍅',
    'POTATO': '🥔',
    'CUCUMBER': '🥒',
    'BREAD': '🍞',
    'CHEESE': '🧀',
    'EGG': '🥚',
    'MILK': '🥛',
    'RICE': '🍚',
    'PIZZA': '🍕',
    'CAKE': '🍰',
    'COOKIE': '🍪',
    'DONUT': '🍩',
    'HONEY': '🍯',
  };

  // Other ways the AI may write a word on the list.
  static const Map<String, String> _sameAs = {
    'GRAPE': 'GRAPES',
    'CHERRIES': 'CHERRY',
    'STRAWBERRIES': 'STRAWBERRY',
    'APPLES': 'APPLE',
    'BANANAS': 'BANANA',
    'ORANGES': 'ORANGE',
    'PEARS': 'PEAR',
    'MANGOES': 'MANGO',
    'CARROTS': 'CARROT',
    'TOMATOES': 'TOMATO',
    'POTATOES': 'POTATO',
    'EGGS': 'EGG',
    'COOKIES': 'COOKIE',
    'DOUGHNUT': 'DONUT',
  };

  /// [count] foods: the AI's words that are on the list first, then random
  /// foods from the list to fill up.
  static List<PracticeExercise> pick(List<PracticeExercise> fromAi, int count, Random random) {
    final words = <String>[];

    for (final item in fromAi) {
      final raw = item.word.trim().toUpperCase();
      final word = _sameAs[raw] ?? raw;
      if (all.containsKey(word) && !words.contains(word)) words.add(word);
    }

    final extra = all.keys.where((w) => !words.contains(w)).toList()..shuffle(random);
    words.addAll(extra.take(max(0, count - words.length)));

    return [
      for (final word in words.take(count)) PracticeExercise(word: word, emoji: all[word]!),
    ];
  }
}
