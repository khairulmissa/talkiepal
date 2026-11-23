class SoundMistake {
  final String expected;
  final String? heard;

  const SoundMistake(this.expected, this.heard);

  factory SoundMistake.fromJson(Map<String, dynamic> json) {
    return SoundMistake(json['expected'].toString(), json['heard']?.toString());
  }
}

class PronunciationResult {
  static PronunciationResult? latest;

  final String target;
  final int score;
  final List<SoundMistake> mistakes;

  const PronunciationResult({required this.target, required this.score, required this.mistakes});

  factory PronunciationResult.fromJson(String target, Map<String, dynamic> json) {
    return PronunciationResult(
      target: target,
      score: (json['score'] as num? ?? 0).round().clamp(0, 100),
      mistakes: (json['mistakes'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SoundMistake.fromJson)
          .toList(),
    );
  }

  String? get tip {
    if (mistakes.isEmpty) return null;
    final first = mistakes.first;
    if (first.heard == null) return "Don't forget the ${first.expected} sound! 👂";
    return 'Try the ${first.expected} sound. It sounded like ${first.heard}. 👄';
  }

  String get summary {
    return mistakes
        .map((m) => m.heard == null ? '${m.expected} missing' : '${m.expected} → ${m.heard}')
        .join(', ');
  }
}
