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

  PracticeItemResult(this.label, this.emoji);

  bool get wasSkipped => bestScore == null;
}

/// Everything the child did in one practice, for the results screen.
class PracticeSession {
  /// Questions (Intermediate) are scored by answering right the first time,
  /// not by a speaking score.
  final bool isQuiz;

  final DateTime startedAt = DateTime.now();
  final Map<String, PracticeItemResult> _items = {};

  /// Speaking score needed to pass an item.
  static const int passScore = 70;

  PracticeSession({this.isQuiz = false});

  /// Adds an item to the list, in the order it is practised.
  void addItem(String label, {String? emoji}) {
    _items.putIfAbsent(label, () => PracticeItemResult(label, emoji));
  }

  /// A speaking try: keeps the best score.
  void recordScore(String label, int score) {
    final item = _items.putIfAbsent(label, () => PracticeItemResult(label, null));
    item.tries++;
    if (item.bestScore == null || score > item.bestScore!) item.bestScore = score;
  }

  /// A question answer: 100 when right on the first try, 0 otherwise.
  void recordAnswer(String label, {required bool correct}) {
    final item = _items.putIfAbsent(label, () => PracticeItemResult(label, null));
    item.tries++;
    if (correct) item.bestScore ??= item.tries == 1 ? 100 : 0;
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

  Duration get duration => DateTime.now().difference(startedAt);

  /// Items to practise again: below the pass score, or skipped.
  List<PracticeItemResult> get hardItems =>
      _items.values.where((i) => (i.bestScore ?? 0) < passScore).toList();
}
