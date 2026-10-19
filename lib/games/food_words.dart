import 'dart:math';

import 'package:talkiepal/games/picture_words.dart';
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

  /// [count] foods: the AI's words that are on the list first, then random
  /// foods from the list to fill up.
  static List<PracticeExercise> pick(List<PracticeExercise> fromAi, int count, Random random) {
    return PictureWords.pick(all, fromAi, count, random);
  }
}
