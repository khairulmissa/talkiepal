import 'dart:math';

import 'package:talkiepal/beginner/beginner_page.dart';
import 'package:talkiepal/intermediate/intermediate_page.dart';
import 'package:talkiepal/practice/widgets/practice_scaffold.dart';
import 'package:talkiepal/practice/widgets/score_dialog.dart';
import 'package:talkiepal/pre intermediate/pre_intermediate_page.dart';
import 'package:talkiepal/services/progress_store.dart';
import 'package:talkiepal/special_sound/specialsound_page.dart';

/// A practice topic or game with its average score.
class ScoreLine {
  /// Picture or short text at the start, e.g. "🐾" or "TH".
  final String lead;

  /// "Special Sound · Sound TH" or "Yes or No".
  final String label;

  /// Smaller text under it, e.g. "hardest: THREE, THUMB".
  final String sub;
  final int score;

  /// Which sessions it is about, to open their details.
  final String level;
  final String topic;

  const ScoreLine({
    required this.lead,
    required this.label,
    required this.sub,
    required this.score,
    required this.level,
    required this.topic,
  });
}

/// A topic or game whose score went clearly up or down.
class ScoreChange {
  final String label;
  final int from;
  final int to;

  const ScoreChange(this.label, this.from, this.to);

  bool get isUp => to > from;
}

/// Totals for one week, with the change from the week before.
class WeekTotals {
  final int sessions;
  final Duration time;
  final int days;

  /// Average speaking score (null when the child did not speak that week).
  final int? speaking;
  final int? speakingChange;

  /// Average game score (null when no game was played that week).
  final int? games;
  final int? gamesChange;

  const WeekTotals({
    required this.sessions,
    required this.time,
    required this.days,
    this.speaking,
    this.speakingChange,
    this.games,
    this.gamesChange,
  });
}

/// Average speaking score of one week, for the week-by-week chart.
class WeekScore {
  final DateTime monday;

  /// Null when the child did not speak that week.
  final int? score;

  const WeekScore(this.monday, this.score);
}

class LevelScore {
  final PracticeLook look;

  /// Null when not practiced yet.
  final int? score;
  final int done;
  final int total;
  final int sessions;

  const LevelScore(this.look, this.score, this.done, this.total, this.sessions);
}

class GameScore {
  final String emoji;
  final String name;

  /// Null when not played yet.
  final int? score;
  final String sub;

  const GameScore(this.emoji, this.name, this.score, this.sub);
}

class WordScore {
  final String word;
  final String? emoji;

  /// Best score the child got for it.
  final int score;

  const WordScore(this.word, this.emoji, this.score);
}

class MixedUp {
  /// "R ↔ W"
  final String pair;
  final int count;

  /// Games where it happened.
  final List<String> games;

  const MixedUp(this.pair, this.count, this.games);
}

/// How the child does on the target sound the parent picked.
class TargetSound {
  final String sound;
  final int sessions;

  /// Average of the first and of the latest few sessions (null when none).
  final int? first;
  final int? latest;
  final int weeks;

  const TargetSound(this.sound, this.sessions, this.first, this.latest, this.weeks);
}

/// The level or game page behind a line, e.g. all "Special Sound" sessions.
class DetailReport {
  final String title;
  final List<SessionRecord> sessions;

  /// Average score of these sessions (null when none).
  final int? score;

  /// Latest score minus the first ones, when there are enough sessions.
  final int? change;

  /// Up to the last 7 sessions, oldest first, for the chart.
  final List<SessionRecord> trend;

  /// Each topic (or, for Pop the Balloon, each sound).
  final List<ScoreLine> parts;

  const DetailReport({
    required this.title,
    required this.sessions,
    required this.score,
    required this.change,
    required this.trend,
    required this.parts,
  });
}

/// Derives everything on the parent's Progress page from one child's
/// sessions (newest first).
class ParentReport {
  final List<SessionRecord> sessions;
  final DateTime now;

  ParentReport(this.sessions, {DateTime? now}) : now = now ?? DateTime.now();

  /// The summary looks at the last two weeks.
  static const Duration summaryPeriod = Duration(days: 14);

  /// Minimum score movement that counts as a change.
  static const int bigChange = 10;

  static const int _chartWeeks = 6;

  static final List<(PracticeLook, Map<String, String>)> levels = [
    (PracticeLook.beginner, BeginnerPage.topicEmojis),
    (PracticeLook.preIntermediate, PreIntermediatePage.topicEmojis),
    (PracticeLook.intermediate, IntermediatePage.topicEmojis),
    (PracticeLook.specialSound, SpecialSoundPage.topicEmojis),
  ];

  static const List<(String, String)> games = [
    ('🔊', 'Sound Matcher'),
    ('👂', 'Minimal Pairs'),
    ('👍', 'Yes or No'),
    ('🦕', 'Feed the Dino'),
    ('🎈', 'Pop the Balloon'),
    ('🚀', 'Voice Rocket'),
  ];

  static const String _balloon = 'Pop the Balloon';

  // Voice Rocket measures voice length/volume, not correctness.
  static const String _rocket = 'Voice Rocket';

  DateTime get _today => DateTime(now.year, now.month, now.day);
  DateTime get thisMonday => _today.subtract(Duration(days: _today.weekday - 1));

  List<SessionRecord> _since(Duration period) => sessions.where((s) => now.difference(s.finishedAt) <= period).toList();

  static int? average(Iterable<int> scores) =>
      scores.isEmpty ? null : (scores.reduce((a, b) => a + b) / scores.length).round();

  static bool _isSpeaking(SessionRecord s) => !s.isGame && !s.isQuiz;

  /// Groups [list] by topic or game; each Pop the Balloon sound is its own group.
  List<_Group> _groups(List<SessionRecord> list) {
    final groups = <String, _Group>{};
    for (final s in list) {
      if (s.isGame && s.topic == _rocket) continue;
      if (s.isGame && s.topic == _balloon) {
        for (final item in s.items.where((i) => i['score'] is num && i['label'] is String)) {
          final label = item['label'] as String;
          groups
              .putIfAbsent('$_balloon|$label', () => _Group('🎈', '$_balloon · $label', 'Game', _balloon))
              .add(s, (item['score'] as num).toInt());
        }
        continue;
      }
      final level = s.isGame ? 'Game' : s.level;
      groups.putIfAbsent('$level|${s.topic}', () => _Group(_leadFor(s), _labelFor(s), level, s.topic)).add(s, s.score);
    }
    return groups.values.toList();
  }

  static String _labelFor(SessionRecord s) => s.isGame ? s.topic : '${s.level} · ${s.topic}';

  static String _leadFor(SessionRecord s) {
    if (s.isGame) return games.firstWhere((g) => g.$2 == s.topic, orElse: () => ('🎮', '')).$1;
    for (final (look, emojis) in levels) {
      if (look.name == s.level) return emojis[s.topic] ?? look.letter;
    }
    return '📝';
  }

  ScoreLine _line(_Group g) {
    final String sub;
    if (g.level == 'Game') {
      sub = 'game · ${g.sessions.length} ${g.sessions.length == 1 ? 'time' : 'times'}';
    } else if (g.sessions.any((s) => s.isQuiz)) {
      sub = 'right on the 1st try · ${_count(g.sessions.length, 'session')}';
    } else {
      final hard = hardestWords(g.sessions, 2);
      sub = hard.isEmpty ? _count(g.sessions.length, 'session') : 'hardest: ${hard.map((w) => w.word).join(', ')}';
    }
    return ScoreLine(lead: g.lead, label: g.label, sub: sub, score: g.average, level: g.level, topic: g.topic);
  }

  /// Weakest first, below the pass score, from the last two weeks.
  List<ScoreLine> get needsAttention {
    final weak = _groups(_since(summaryPeriod)).where((g) => g.average < ScoreBand.pass).toList()
      ..sort((a, b) => a.average.compareTo(b.average));
    return weak.take(3).map(_line).toList();
  }

  /// Strongest first, from 85%, from the last two weeks.
  List<ScoreLine> get strongest {
    final strong = _groups(_since(summaryPeriod)).where((g) => g.average >= ScoreBand.great).toList()
      ..sort((a, b) => b.average.compareTo(a.average));
    return strong.take(3).map(_line).toList();
  }

  /// Topics or games whose last week clearly differs from the 4 weeks before.
  List<ScoreChange> get changes {
    final recent = {for (final g in _groups(_since(const Duration(days: 7)))) g.label: g.average};
    final before = {
      for (final g in _groups(
        sessions.where((s) {
          final age = now.difference(s.finishedAt);
          return age > const Duration(days: 7) && age <= const Duration(days: 35);
        }).toList(),
      ))
        g.label: g.average,
    };
    final list = [
      for (final label in recent.keys)
        if (before[label] != null && (recent[label]! - before[label]!).abs() >= bigChange)
          ScoreChange(label.startsWith(_balloon) ? label : label.split(' · ').last, before[label]!, recent[label]!),
    ]..sort((a, b) => (b.to - b.from).abs().compareTo((a.to - a.from).abs()));
    return list.take(3).toList();
  }

  WeekTotals _week(DateTime monday) {
    final end = monday.add(const Duration(days: 7));
    final list = sessions.where((s) => !s.finishedAt.isBefore(monday) && s.finishedAt.isBefore(end)).toList();
    return WeekTotals(
      sessions: list.length,
      time: list.fold(Duration.zero, (sum, s) => sum + s.time),
      days: list.map((s) => DateTime(s.finishedAt.year, s.finishedAt.month, s.finishedAt.day)).toSet().length,
      speaking: average(list.where(_isSpeaking).map((s) => s.score)),
      games: average(list.where((s) => s.isGame && s.topic != _rocket).map((s) => s.score)),
    );
  }

  WeekTotals get thisWeek {
    final week = _week(thisMonday);
    final last = _week(thisMonday.subtract(const Duration(days: 7)));
    int? change(int? now, int? before) => now == null || before == null ? null : now - before;
    return WeekTotals(
      sessions: week.sessions,
      time: week.time,
      days: week.days,
      speaking: week.speaking,
      speakingChange: change(week.speaking, last.speaking),
      games: week.games,
      gamesChange: change(week.games, last.games),
    );
  }

  /// Average speaking score for each of the last [_chartWeeks] weeks, oldest first.
  List<WeekScore> get weeks => [
    for (var i = _chartWeeks - 1; i >= 0; i--) _weekScore(thisMonday.subtract(Duration(days: 7 * i))),
  ];

  WeekScore _weekScore(DateTime monday) => WeekScore(monday, _week(monday).speaking);

  /// Sessions of the last 4 weeks, or all of them when there are none.
  static List<SessionRecord> _recentOrAll(List<SessionRecord> list, DateTime now) {
    final recent = list.where((s) => now.difference(s.finishedAt) <= const Duration(days: 28)).toList();
    return recent.isEmpty ? list : recent;
  }

  List<LevelScore> get levelScores => [for (final (look, emojis) in levels) _levelScore(look, emojis)];

  LevelScore _levelScore(PracticeLook look, Map<String, String> emojis) {
    final list = sessions.where((s) => !s.isGame && s.level == look.name).toList();
    return LevelScore(
      look,
      average(_recentOrAll(list, now).map((s) => s.score)),
      emojis.keys.where((t) => list.any((s) => s.topic == t)).length,
      emojis.length,
      list.length,
    );
  }

  List<GameScore> get gameScores => [for (final (emoji, name) in games) _gameScore(emoji, name)];

  GameScore _gameScore(String emoji, String name) {
    final list = sessions.where((s) => s.isGame && s.topic == name).toList();
    if (list.isEmpty) return GameScore(emoji, name, null, 'not played yet');

    final what = switch (name) {
      _balloon => 'right pops',
      _rocket => 'stars collected',
      _ => 'right on the 1st try',
    };
    return GameScore(
      emoji,
      name,
      average(_recentOrAll(list, now).map((s) => s.score)),
      '$what · ${_count(list.length, 'game')}',
    );
  }

  /// Words with the lowest best score in [list], below 85%.
  static List<WordScore> hardestWords(List<SessionRecord> list, int count) {
    final best = <String, WordScore>{};
    for (final s in list.where(_isSpeaking)) {
      for (final item in s.items) {
        final word = item['label'];
        final score = item['score'];
        if (word is! String || score is! num) continue;
        final old = best[word];
        if (old == null || score > old.score) best[word] = WordScore(word, item['emoji'] as String?, score.toInt());
      }
    }
    final hard = best.values.where((w) => w.score < ScoreBand.great).toList()
      ..sort((a, b) => a.score.compareTo(b.score));
    return hard.take(count).toList();
  }

  List<WordScore> get wordsToPractice => hardestWords(_since(summaryPeriod), 8);

  List<MixedUp> get mixedUp {
    final counts = <String, int>{};
    final from = <String, Set<String>>{};
    for (final s in _since(const Duration(days: 28)).where((s) => s.isGame)) {
      s.mixedUp.forEach((pair, n) {
        counts[pair] = (counts[pair] ?? 0) + n;
        from.putIfAbsent(pair, () => {}).add(s.topic);
      });
    }
    final list = [for (final e in counts.entries) MixedUp(e.key, e.value, from[e.key]!.toList())]
      ..sort((a, b) => b.count.compareTo(a.count));
    return list.take(5).toList();
  }

  TargetSound? targetSound(String? sound) {
    if (sound == null) return null;
    final list =
        sessions
            .where(
              (s) =>
                  s.level == PracticeLook.specialSound.name &&
                  (s.topic == 'Sound $sound' || s.topic == 'Mini Challenge $sound'),
            )
            .toList()
          ..sort((a, b) => a.finishedAt.compareTo(b.finishedAt));
    if (list.isEmpty) return TargetSound(sound, 0, null, null, 0);
    final few = min(3, list.length);
    return TargetSound(
      sound,
      list.length,
      average(list.take(few).map((s) => s.score)),
      average(list.skip(list.length - few).map((s) => s.score)),
      list.last.finishedAt.difference(list.first.finishedAt).inDays ~/ 7,
    );
  }

  /// All sessions of a level (e.g. "Special Sound") or a game.
  DetailReport detail({required String level, String? topic}) {
    final list = sessions
        .where((s) => level == 'Game' ? s.isGame && s.topic == topic : !s.isGame && s.level == level)
        .toList();
    final oldestFirst = list.reversed.toList();
    final few = min(3, list.length);
    final change = list.length < 4
        ? null
        : average(list.take(few).map((s) => s.score))! - average(oldestFirst.take(few).map((s) => s.score))!;

    final List<ScoreLine> parts;
    if (level != 'Game') {
      final groups = <String, _Group>{};
      for (final s in list) {
        groups.putIfAbsent(s.topic, () => _Group(_leadFor(s), s.topic, level, s.topic)).add(s, s.score);
      }
      parts = [for (final g in groups.values) _topicLine(g, level)]..sort((a, b) => b.score.compareTo(a.score));
    } else if (topic == _balloon) {
      parts = [
        for (final g in _groups(list))
          ScoreLine(
            lead: g.label.split(' ').last,
            label: g.label.split(' · ').last,
            sub: _count(g.sessions.length, 'game'),
            score: g.average,
            level: level,
            topic: _balloon,
          ),
      ]..sort((a, b) => b.score.compareTo(a.score));
    } else {
      parts = const [];
    }

    return DetailReport(
      title: topic ?? level,
      sessions: list,
      score: average(list.map((s) => s.score)),
      change: change,
      trend: oldestFirst.skip(max(0, oldestFirst.length - 7)).toList(),
      parts: parts,
    );
  }

  static ScoreLine _topicLine(_Group g, String level) {
    final hard = hardestWords(g.sessions, 2);
    final tries = g.sessions.fold(0, (sum, s) => sum + s.tries);
    return ScoreLine(
      lead: g.lead,
      label: g.topic,
      sub: [
        _count(g.sessions.length, 'session'),
        _count(tries, 'try', 'tries'),
        if (hard.isNotEmpty) 'hardest: ${hard.map((w) => '${w.word} ${w.score}%').join(', ')}',
      ].join(' · '),
      score: g.average,
      level: level,
      topic: g.topic,
    );
  }

  static String _count(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';
}

class _Group {
  final String lead;
  final String label;
  final String level;
  final String topic;
  final List<SessionRecord> sessions = [];
  final List<int> _scores = [];

  _Group(this.lead, this.label, this.level, this.topic);

  void add(SessionRecord s, int score) {
    sessions.add(s);
    _scores.add(score);
  }

  int get average => ParentReport.average(_scores) ?? 0;
}