import 'package:talkiepal/practice/widgets/score_dialog.dart';

/// How the child did on one word, letter, sentence or question.
class PracticeItemResult {
  final String label;

  /// Picture for the results list; null shows the label itself (e.g. "A").
  final String? emoji;

  /// How many times the child spoke or answered.
  int tries = 0;

  /// Best speaking score (0-100), or 100/0 for a question answered right
  /// first time / not. Null when the child skipped it.
  int? bestScore;

  /// What the phone heard on the best try, e.g. "wabbit" for RABBIT.
  String? heard;

  PracticeItemResult(this.label, this.emoji);

  bool get wasSkipped => bestScore == null;
}

/// Everything the child did in one practice, for the results screen.
class PracticeSession {
  /// Questions (Intermediate) are scored by answering right the first time,
  /// not by a speaking score.
  final bool isQuiz;

  final DateTime startedAt = DateTime.now();

  /// When the child last spoke or answered; the practice time ends here, so
  /// time spent looking at the results screen is not counted.
  DateTime? lastTryAt;

  final Map<String, PracticeItemResult> _items = {};

  /// Speaking score needed to pass an item; the same line the score popup uses.
  static const int passScore = ScoreBand.pass;

  PracticeSession({this.isQuiz = false});

  /// Adds an item to the list, in the order it is practiced.
  void addItem(String label, {String? emoji}) {
    _items.putIfAbsent(label, () => PracticeItemResult(label, emoji));
  }

  PracticeItemResult _newTry(String label) {
    final item = _items.putIfAbsent(label, () => PracticeItemResult(label, null));
    item.tries++;
    lastTryAt = DateTime.now();
    return item;
  }

  /// A speaking try: keeps the best score and what was heard then.
  void recordScore(String label, int score, {List<String> heard = const []}) {
    final item = _newTry(label);
    final clamped = score.clamp(0, 100);
    final heardNow = heard.isEmpty ? null : heard.first;

    if (item.bestScore == null || clamped > item.bestScore!) {
      item.bestScore = clamped;
      item.heard = heardNow;
    } else if (clamped == item.bestScore && item.heard == null) {
      // Same score, but this time the phone caught what was said.
      item.heard = heardNow;
    }
  }

  /// A question answer: 100 when right on the first try, 0 otherwise.
  /// The first answer decides, so a question that was tried but never
  /// answered right shows 0 instead of looking skipped.
  void recordAnswer(String label, {required bool correct}) {
    final item = _newTry(label);
    if (item.tries == 1) item.bestScore = correct ? 100 : 0;
  }

  List<PracticeItemResult> get items => _items.values.toList();

  /// Average of the best scores; skipped items count as 0.
  int get overallScore {
    if (_items.isEmpty) return 0;
    final total = _items.values.fold<int>(0, (sum, item) => sum + (item.bestScore ?? 0));
    return (total / _items.length).round();
  }

  int get passedCount => _items.values.where((i) => (i.bestScore ?? 0) >= passScore).length;

  int get totalTries => _items.values.fold<int>(0, (sum, item) => sum + item.tries);

  /// Time from the start to the last try (zero if the child did nothing).
  Duration get duration => (lastTryAt ?? startedAt).difference(startedAt);

  /// Items to practice again: below the pass score, or skipped.
  List<PracticeItemResult> get hardItems =>
      _items.values.where((i) => (i.bestScore ?? 0) < passScore).toList();
}