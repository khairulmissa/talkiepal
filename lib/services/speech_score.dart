import 'dart:math';

/// How close what the child said is to the target, from 0 to 100.
///
/// The phone's speech recognition gives its best guesses of the words it
/// heard. Each guess is compared with the target letter by letter and the
/// best one counts. For a sentence, every word of the target is matched with
/// the closest word that was heard and the results are averaged.
int scoreSpeech(String target, List<String> heard) {
  final targetWords = _words(target);
  if (targetWords.isEmpty || heard.isEmpty) return 0;

  var best = 0.0;
  for (final guess in heard) {
    final guessWords = _words(guess);
    if (guessWords.isEmpty) continue;

    final score = targetWords.length == 1
        ? _singleWordScore(targetWords.first, guessWords)
        : _sentenceScore(targetWords, guessWords);
    best = max(best, score);
  }
  return (best * 100).round().clamp(0, 100);
}

/// Lower case, letters only, numbers 0 to 10 written as words.
List<String> _words(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9' ]"), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => _numberWords[w] ?? w.replaceAll("'", ''))
      .toList();
}

double _singleWordScore(String target, List<String> guessWords) {
  // A letter of the alphabet: the phone writes "B" as "be", "bee" and so on.
  final sounds = _letterSounds[target];
  if (sounds != null && guessWords.any(sounds.contains)) return 1;

  // The word on its own ("lion"), or split by the phone ("ice cream" / "icecream").
  var best = _similarity(target, guessWords.join());
  for (final word in guessWords) {
    best = max(best, _similarity(target, word));
  }
  return best;
}

double _sentenceScore(List<String> target, List<String> guess) {
  var total = 0.0;
  for (final word in target) {
    var best = 0.0;
    for (final g in guess) {
      best = max(best, _similarity(word, g));
    }
    total += best;
  }
  // Extra words the child added lower the score a little.
  final extra = max(0, guess.length - target.length);
  final byWord = max(0.0, total / target.length - extra * 0.05);

  // The phone may join or split words ("ice cream" / "icecream").
  final asOne = _similarity(target.join(), guess.join());
  return max(byWord, asOne);
}

/// 1 when the same, lower the more letters differ (edit distance).
double _similarity(String a, String b) {
  if (a == b) return 1;
  if (a.isEmpty || b.isEmpty) return 0;

  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      current[j] = min(min(current[j - 1] + 1, previous[j] + 1), previous[j - 1] + cost);
    }
    previous = current;
  }
  return 1 - previous[b.length] / max(a.length, b.length);
}

const Map<String, String> _numberWords = {
  '0': 'zero', '1': 'one', '2': 'two', '3': 'three', '4': 'four', '5': 'five',
  '6': 'six', '7': 'seven', '8': 'eight', '9': 'nine', '10': 'ten',
  'to': 'two', 'too': 'two', 'for': 'four', 'won': 'one', 'ate': 'eight', 'tree': 'three',
};

/// How the phone may write each letter when a child says its name.
const Map<String, Set<String>> _letterSounds = {
  'a': {'a', 'ay', 'eh', 'hey', 'eight', 'ae', 'hay', 'aa'},
  'b': {'b', 'be', 'bee'},
  'c': {'c', 'see', 'sea', 'si'},
  'd': {'d', 'dee', 'de'},
  'e': {'e', 'ee', 'he', 'eee'},
  'f': {'f', 'ef', 'eff'},
  'g': {'g', 'gee', 'ji', 'jee'},
  'h': {'h', 'aitch', 'each', 'age', 'edge'},
  'i': {'i', 'eye', 'aye', 'hi', 'ai'},
  'j': {'j', 'jay', 'jae'},
  'k': {'k', 'kay', 'okay', 'ok', 'cay'},
  'l': {'l', 'el', 'elle', 'ell', 'hell'},
  'm': {'m', 'em', 'um'},
  'n': {'n', 'en', 'in', 'and'},
  'o': {'o', 'oh', 'owe', 'ow', 'zero'},
  'p': {'p', 'pee', 'pea'},
  'q': {'q', 'queue', 'cue', 'kyu', 'cute'},
  'r': {'r', 'are', 'ar', 'our', 'or'},
  's': {'s', 'es', 'ess', 'yes'},
  't': {'t', 'tea', 'tee'},
  'u': {'u', 'you', 'yu', 'ewe'},
  'v': {'v', 'vee', 've', 'we'},
  'w': {'w', 'doubleu', 'doubleyou', 'double'},
  'x': {'x', 'ex', 'eggs', 'axe'},
  'y': {'y', 'why', 'wye', 'wai'},
  'z': {'z', 'zee', 'zed', 'said'},
};
