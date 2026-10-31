import 'dart:math';

import 'package:talkiepal/config/api_config.dart';
import 'package:talkiepal/services/backend_client.dart';

class PracticeExercise {
  final String word;
  final String emoji;

  const PracticeExercise({required this.word, required this.emoji});
}

class ExerciseResult {
  final List<PracticeExercise> exercises;

  /// True when the backend was unreachable and offline words were used.
  final bool isOffline;

  const ExerciseResult({required this.exercises, required this.isOffline});
}

/// Fetches practice words from the AI backend, falling back to offline words.
abstract final class ExerciseService {
  static const int _recentLimit = 20;
  static const String _defaultEmoji = '⭐';

  /// Offline words keyed by level, then topic, then word → emoji.
  static const Map<String, Map<String, Map<String, String>>> _offlineWords = {
    'beginner': {
      'Colors': {
        'RED': '🔴',
        'BLUE': '🔵',
        'GREEN': '🟢',
        'YELLOW': '🟡',
        'ORANGE': '🟠',
        'PURPLE': '🟣',
        'BROWN': '🟤',
        'BLACK': '⚫',
        'WHITE': '⚪',
        'PINK': '🩷',
      },
      'Animals': {
        'CAT': '🐱',
        'DOG': '🐶',
        'COW': '🐮',
        'BIRD': '🐦',
        'FISH': '🐟',
        'RABBIT': '🐰',
        'FROG': '🐸',
        'MONKEY': '🐵',
        'LION': '🦁',
        'ELEPHANT': '🐘',
      },
      'Fruits': {
        'APPLE': '🍎',
        'BANANA': '🍌',
        'CHERRY': '🍒',
        'GRAPE': '🍇',
        'MANGO': '🥭',
        'ORANGE': '🍊',
        'PEAR': '🍐',
        'PINEAPPLE': '🍍',
        'STRAWBERRY': '🍓',
        'WATERMELON': '🍉',
      },
      'Body Parts': {
        'ARM': '💪',
        'EAR': '👂',
        'EYES': '👀',
        'FINGER': '☝️',
        'FOOT': '🦶',
        'HAND': '✋',
        'HEAD': '🙂',
        'LEG': '🦵',
        'MOUTH': '👄',
        'NOSE': '👃',
      },
      'Clothes': {
        'DRESS': '👗',
        'GLOVES': '🧤',
        'HAT': '👒',
        'JACKET': '🧥',
        'PANTS': '👖',
        'SCARF': '🧣',
        'SHIRT': '👕',
        'SHOES': '👟',
        'SOCKS': '🧦',
        'CAP': '🧢',
      },
      'Vehicles': {
        'AIRPLANE': '✈️',
        'BICYCLE': '🚲',
        'BOAT': '⛵',
        'BUS': '🚌',
        'CAR': '🚗',
        'HELICOPTER': '🚁',
        'MOTORCYCLE': '🏍️',
        'TRAIN': '🚆',
        'TRUCK': '🚚',
      },
    },
    'pre_intermediate': {
      'My Morning Routine': {
        'I WAKE UP': '⏰',
        'I BRUSH MY TEETH': '🪥',
        'I WASH MY FACE': '🧼',
        'I EAT BREAKFAST': '🥣',
        'I GET DRESSED': '👕',
        'I COMB MY HAIR': '💇',
      },
      'My Feelings': {
        'I AM HAPPY': '😊',
        'I AM SAD': '😢',
        'I AM SLEEPY': '😴',
        'I AM ANGRY': '😠',
        'I AM SCARED': '😨',
        'I AM HUNGRY': '😋',
        'I AM TIRED': '🥱',
      },
      'Things I Like': {
        'I LIKE TO PLAY': '⚽',
        'I LIKE TO DRAW': '🖍️',
        'I LIKE TO SING': '🎤',
        'I LIKE TO DANCE': '💃',
        'I LIKE TO READ': '📖',
        'I LIKE TO SWIM': '🏊',
      },
      'School & Classroom': {
        'MY TEACHER': '👩‍🏫',
        'MY BAG': '🎒',
        'READ A BOOK': '📖',
        'MY PENCIL': '✏️',
        'SIT DOWN': '🪑',
        'RAISE YOUR HAND': '✋',
      },
      'Hobbies & Free Time': {
        'PLAYING FOOTBALL': '⚽',
        'READING BOOKS': '📚',
        'LISTENING TO MUSIC': '🎵',
        'RIDING A BIKE': '🚲',
        'DRAWING PICTURES': '🎨',
        'FLYING A KITE': '🪁',
      },
      'Daily Routine': {
        'WAKE UP': '⏰',
        'EAT BREAKFAST': '🥣',
        'BRUSH TEETH': '🪥',
        'TAKE A BATH': '🛁',
        'GO TO SCHOOL': '🏫',
        'GO TO BED': '🛏️',
      },
      'Home & Rooms': {
        'LIVING ROOM': '🛋️',
        'BEDROOM': '🛏️',
        'KITCHEN': '🍳',
        'BATHROOM': '🛁',
        'MY HOUSE': '🏠',
        'DINING TABLE': '🍽️',
      },
      'Shopping & Toys': {
        'TEDDY BEAR': '🧸',
        'TOY CAR': '🚗',
        'SHOPPING BAG': '🛍️',
        'BIG BALL': '⚽',
        'NEW DOLL': '🪆',
        'BUY A TOY': '🛒',
      },
    },
    'special_words': {
      'R': {'RED': '🔴', 'RUN': '🏃', 'RICE': '🍚', 'RAIN': '🌧️', 'CARROT': '🥕', 'CAR': '🚗'},
      'S': {'SUN': '☀️', 'SIX': '6️⃣', 'SOCK': '🧦', 'BASKET': '🧺', 'BUS': '🚌', 'GLASS': '🥛'},
      'L': {'LION': '🦁', 'LEG': '🦵', 'LEAF': '🍃', 'BALLOON': '🎈', 'BALL': '⚽', 'BELL': '🔔'},
      'TH': {'THREE': '3️⃣', 'THUMB': '👍', 'MOTHER': '👩', 'FEATHER': '🪶', 'BATH': '🛁', 'TOOTH': '🦷'},
      'SH': {'SHIP': '🚢', 'SHOE': '👟', 'SHELL': '🐚', 'WASHING': '🧺', 'FISH': '🐟', 'BRUSH': '🪥'},
      'CH': {'CHIN': '🙂', 'CHAIR': '🪑', 'CHEESE': '🧀', 'TEACHER': '👩‍🏫', 'LUNCH': '🍱', 'WATCH': '⌚'},
      'V': {'VAN': '🚐', 'VEST': '🦺', 'VASE': '🏺', 'SEVEN': '7️⃣', 'OVEN': '♨️', 'FIVE': '5️⃣'},
      'W': {'WET': '💧', 'WIN': '🏆', 'WINDOW': '🪟', 'WATER': '💧', 'SANDWICH': '🥪', 'FLOWER': '🌸'},
    },
    'special_sentences': {
      'R': {
        'THE RED ROBOT RUNS IN THE RAIN': '🤖',
        'RABBITS RUN ON THE ROAD': '🐰',
        'I READ A RED BOOK IN MY ROOM': '📕',
        'THE RAIN FELL ON THE RED ROOF': '🌧️',
      },
      'S': {
        'SIX SUNNY SEALS SWIM': '🦭',
        'SAM SINGS SEVEN SONGS': '🎵',
        'THE SUN IS SO HOT': '☀️',
        'I SEE SIX SOCKS': '🧦',
      },
      'L': {
        'LITTLE LILY LOVES TO LAUGH': '😄',
        'THE LION LIKES TO LICK A LOLLIPOP': '🦁',
        'A LADYBUG LANDED ON A LEAF': '🐞',
        'LOOK AT THE BLUE BALLOON': '🎈',
      },
      'TH': {
        'THREE THICK THINGS': '3️⃣',
        'THANK YOU MOTHER FOR THE GIFT': '🎁',
        'THE FEATHER IS IN THE BATH': '🪶',
        'THIS IS MY THIN THUMB': '👍',
      },
      'SH': {
        'SHE SHOWS ME SHINY SHELLS': '🐚',
        'THE SHIP SHINES IN THE SHADE': '🚢',
        'SHE WASHED HER SHOES': '👟',
        'FISH IN THE SHALLOW SHORE': '🐟',
      },
      'CH': {
        'CHEESE AND CHIPS FOR LUNCH': '🧀',
        'THE CHILD SITS ON A CHAIR TO CHAT': '🪑',
        'CHOO CHOO SAYS THE CHUNKY TRAIN': '🚂',
        'MY TEACHER HAS A CHOCOLATE CHIP': '🍫',
      },
      'V': {
        'I HAVE FIVE VEGETABLES': '🥦',
        'DAD DRIVES THE VAN VERY FAST': '🚐',
        'SEVEN VIOLETS IN A VASE': '🏺',
        'I LOVE MY VELVET VEST': '🦺',
      },
      'W': {
        'WE WILL WALK IN THE WATER': '💧',
        'WE WASH THE WET WINDOW': '🪟',
        'WE WANT A WARM SANDWICH': '🥪',
        'WE WAVE TO THE WIND': '👋',
      },
    },
  };

  /// Recently shown words per level/topic, sent to the backend to avoid repeats.
  static final Map<String, List<String>> _recentWords = {};

  static Future<ExerciseResult> getExercises({required String level, required String topic, int count = 10}) async {
    final key = '$level/$topic';
    final recent = _recentWords[key] ?? const <String>[];

    try {
      final data = await postToBackend(ApiConfig.generateExercisesUrl, {
        'level': level,
        'topic': topic,
        'count': count,
        'exclude': recent,
      });

      final exercises = [
        for (final item in data['exercises'] as List) _buildExercise(item['word'] as String, item['emoji'] as String),
      ];
      if (exercises.isEmpty) {
        throw Exception('No exercises returned');
      }

      final updated = [...recent, ...exercises.map((e) => e.word)];
      _recentWords[key] = updated.sublist(max(0, updated.length - _recentLimit));

      return ExerciseResult(exercises: exercises, isOffline: false);
    } catch (_) {
      return ExerciseResult(exercises: _offlineExercises(level, topic, count), isOffline: true);
    }
  }

  static PracticeExercise _buildExercise(String word, String emoji) {
    return PracticeExercise(word: word.toUpperCase(), emoji: emoji.isEmpty ? _defaultEmoji : emoji);
  }

  static List<PracticeExercise> _offlineExercises(String level, String topic, int count) {
    final words = (_offlineWords[level]?[topic] ?? const <String, String>{}).entries.toList()..shuffle(Random());
    return words.take(count).map((entry) => _buildExercise(entry.key, entry.value)).toList();
  }
}