import 'dart:math';

import 'package:talkiepal/services/exercise_service.dart';

/// Real words for each picture topic, each with the one picture that shows it.
/// The AI sometimes makes up words or gives a picture that does not match, so
/// games only use words from these lists, always with the list's picture.
class PictureWords {
  static const Map<String, Map<String, String>> topics = {
    'Animals': {
      'CAT': '🐱', 'DOG': '🐶', 'COW': '🐮', 'PIG': '🐷', 'HORSE': '🐴', 'SHEEP': '🐑',
      'GOAT': '🐐', 'DUCK': '🦆', 'CHICKEN': '🐔', 'RABBIT': '🐰', 'MOUSE': '🐭', 'LION': '🦁',
      'TIGER': '🐯', 'BEAR': '🐻', 'MONKEY': '🐵', 'ELEPHANT': '🐘', 'GIRAFFE': '🦒', 'ZEBRA': '🦓',
      'FROG': '🐸', 'FISH': '🐟', 'BIRD': '🐦', 'OWL': '🦉', 'SNAKE': '🐍', 'TURTLE': '🐢',
      'PENGUIN': '🐧', 'FOX': '🦊', 'BEE': '🐝', 'BUTTERFLY': '🦋', 'WHALE': '🐳', 'CAMEL': '🐫',
    },
    'Fruits': {
      'APPLE': '🍎', 'BANANA': '🍌', 'GRAPES': '🍇', 'ORANGE': '🍊', 'LEMON': '🍋',
      'WATERMELON': '🍉', 'STRAWBERRY': '🍓', 'CHERRY': '🍒', 'PEAR': '🍐', 'PEACH': '🍑',
      'PINEAPPLE': '🍍', 'MANGO': '🥭', 'KIWI': '🥝', 'COCONUT': '🥥',
    },
    'Vehicles': {
      'CAR': '🚗', 'BUS': '🚌', 'TRAIN': '🚆', 'PLANE': '✈️', 'BOAT': '🚤', 'SHIP': '🚢',
      'BICYCLE': '🚲', 'MOTORCYCLE': '🏍️', 'TRUCK': '🚚', 'TAXI': '🚕', 'HELICOPTER': '🚁',
      'ROCKET': '🚀', 'TRACTOR': '🚜', 'AMBULANCE': '🚑', 'SCOOTER': '🛴', 'VAN': '🚐',
    },
    'Body Parts': {
      'EYE': '👁️', 'EAR': '👂', 'NOSE': '👃', 'MOUTH': '👄', 'HAND': '✋', 'FOOT': '🦶',
      'LEG': '🦵', 'TOOTH': '🦷', 'TONGUE': '👅', 'BRAIN': '🧠', 'ARM': '💪', 'FINGER': '👆',
    },
    'Clothes': {
      'SHIRT': '👕', 'DRESS': '👗', 'HAT': '👒', 'CAP': '🧢', 'SOCKS': '🧦', 'SHOES': '👟',
      'JEANS': '👖', 'COAT': '🧥', 'SCARF': '🧣', 'GLOVES': '🧤', 'BOOTS': '👢', 'TIE': '👔',
      'GLASSES': '👓', 'BAG': '🎒', 'CROWN': '👑',
    },
  };

  // Other ways the AI may write a word; plurals like SOCK / SOCKS are handled too.
  static const Map<String, String> _sameAs = {
    'TEETH': 'TOOTH',
    'FEET': 'FOOT',
    'MICE': 'MOUSE',
    'AEROPLANE': 'PLANE',
    'AIRPLANE': 'PLANE',
    'BIKE': 'BICYCLE',
    'MOTORBIKE': 'MOTORCYCLE',
    'CHERRIES': 'CHERRY',
    'STRAWBERRIES': 'STRAWBERRY',
    'MANGOES': 'MANGO',
    'DOUGHNUT': 'DONUT',
    'TOMATOES': 'TOMATO',
    'POTATOES': 'POTATO',
  };

  /// The list word for what the AI wrote, or null when it is not on the list.
  static String? match(String aiWord, Map<String, String> list) {
    final raw = aiWord.trim().toUpperCase();
    final candidates = [
      _sameAs[raw] ?? raw,
      if (raw.endsWith('S')) raw.substring(0, raw.length - 1),
      '${raw}S',
    ];
    for (final word in candidates) {
      if (list.containsKey(word)) return word;
    }
    return null;
  }

  /// [count] words from [list]: the AI's words that are on the list first,
  /// then random words from the list to fill up.
  static List<PracticeExercise> pick(
    Map<String, String> list,
    List<PracticeExercise> fromAi,
    int count,
    Random random,
  ) {
    final words = <String>[];

    for (final item in fromAi) {
      final word = match(item.word, list);
      if (word != null && !words.contains(word)) words.add(word);
    }

    final extra = list.keys.where((w) => !words.contains(w)).toList()..shuffle(random);
    words.addAll(extra.take(max(0, count - words.length)));

    return [
      for (final word in words.take(count)) PracticeExercise(word: word, emoji: list[word]!),
    ];
  }
}
