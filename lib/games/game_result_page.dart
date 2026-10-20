import 'package:flutter/material.dart';
import 'package:talkiepal/games/widgets/game_scaffold.dart';
import 'package:talkiepal/practice/widgets/practice_scaffold.dart';
import 'package:talkiepal/practice/widgets/result_widgets.dart';
import 'package:talkiepal/practice/widgets/score_dialog.dart';
import 'package:talkiepal/services/current_kid.dart';
import 'package:talkiepal/widgets/dino_mascot.dart';

/// One line in the details for parents and therapists, e.g. one round,
/// one balloon sound or one rocket level.
class GameResultRow {
  /// Picture or short text at the start, e.g. "🐱" or "SH".
  final String lead;
  final String label;

  /// Smaller text under the label, e.g. 'heard RED · picked WED'.
  final String detail;

  /// Text in the coloured pill at the end, e.g. "1st try" or "3 ⭐".
  final String pill;

  /// 0-100, colours the row by the usual score bands.
  final int score;

  const GameResultRow({
    required this.lead,
    required this.label,
    required this.detail,
    required this.pill,
    required this.score,
  });
}

/// A number in one of the boxes under the stars, e.g. "✅ 8/10 first try".
class GameStat {
  final String emoji;
  final String value;
  final String label;

  const GameStat(this.emoji, this.value, this.label);
}

/// Everything shown on the results screen at the end of a game.
class GameResult {
  final String title;
  final GameLook look;

  /// 0-100, sets the stars and the cheer.
  final int score;

  /// What the child did well, e.g. "Great listening".
  final String praise;

  /// Big happy line for the child, e.g. "🎈 46 balloons popped!".
  final String win;

  final List<GameStat> stats;
  final List<GameResultRow> rows;

  /// Line under the details, e.g. ("🔎 Often mixed up: ", "R ↔ W (2 times)").
  /// Null when there is nothing to point out.
  final (String, String)? note;

  const GameResult({
    required this.title,
    required this.look,
    required this.score,
    required this.praise,
    required this.win,
    required this.stats,
    required this.rows,
    this.note,
  });
}

/// "<1 min" or "3 min".
String gameTime(Duration time) => time.inMinutes < 1 ? '<1 min' : '${time.inMinutes} min';

/// Keeps score in games where the child taps (or drags) one answer per
/// round and may try again until it is right: Sound Matcher, Minimal Pairs,
/// Yes or No and Feed the Dino. A round counts when it is right on the first try.
class FirstTryScore {
  final DateTime startedAt = DateTime.now();
  final List<_Round> _rounds = [];
  final Map<String, int> _mixedUp = {};

  /// Starts a new round. [lead] and [label] say what it was about (picture
  /// and word), [answer] is the right answer.
  void newRound({required String lead, required String label, required String answer}) {
    _rounds.add(_Round(lead, label, answer));
  }

  /// A wrong answer in the current round. [mixedUp] is what the child
  /// confused, e.g. "R ↔ W", to count in the note for parents.
  void wrong(String picked, {String? mixedUp}) {
    if (_rounds.isEmpty) return;
    _rounds.last.wrong.add(picked);
    if (mixedUp != null) _mixedUp[mixedUp] = (_mixedUp[mixedUp] ?? 0) + 1;
  }

  int get rightFirstTime => _rounds.where((r) => r.wrong.isEmpty).length;

  /// Every tap: the wrong ones and the right one in each round.
  int get taps => _rounds.fold(0, (sum, r) => sum + r.wrong.length + 1);

  int get percent => _rounds.isEmpty ? 0 : (rightFirstTime * 100 / _rounds.length).round();

  /// [heard] and [picked] name the right answer and the wrong ones in the
  /// details ("heard CAT · picked RAT"); [emoji] starts the line for the child.
  GameResult result({
    required String title,
    required GameLook look,
    required String praise,
    String emoji = '🎯',
    String heard = 'heard',
    String picked = 'picked',
  }) {
    final rows = [
      for (final r in _rounds)
        GameResultRow(
          lead: r.lead,
          label: r.label,
          detail: r.wrong.isEmpty ? '$heard ${r.answer}' : '$heard ${r.answer} · $picked ${r.wrong.join(', ')}',
          pill: r.wrong.isEmpty ? '1st try' : '${r.wrong.length + 1} tries',
          score: r.wrong.isEmpty ? 100 : ScoreBand.pass,
        ),
    ];

    final right = rightFirstTime;
    return GameResult(
      title: title,
      look: look,
      score: percent,
      praise: praise,
      win: right == 0 ? '🏁 You finished the game!' : '$emoji $right right on the first try!',
      stats: [
        GameStat('✅', '$right/${_rounds.length}', 'first try'),
        GameStat('👆', '$taps', 'taps'),
        GameStat('⏱', gameTime(DateTime.now().difference(startedAt)), 'time'),
      ],
      rows: rows,
      note: mixedUpNote(_mixedUp),
    );
  }
}

class _Round {
  final String lead;
  final String label;
  final String answer;
  final List<String> wrong = [];

  _Round(this.lead, this.label, this.answer);
}

/// "🔎 Often mixed up: R ↔ W (2 times), SH ↔ S" from what the child mixed
/// up and how often, most often first. Null when nothing was mixed up.
(String, String)? mixedUpNote(Map<String, int> mixedUp) {
  if (mixedUp.isEmpty) return null;
  final top = mixedUp.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final text = top.take(3).map((e) => e.value > 1 ? '${e.key} (${e.value} times)' : e.key).join(', ');
  return ('🔎 Often mixed up: ', text);
}

/// Results at the end of a game: stars and a happy line for the child,
/// and every round for parents and therapists. No red score for the child,
/// so games stay fun.
class GameResultPage extends StatefulWidget {
  final GameResult result;

  /// Opens the same game again from the start.
  final Widget Function() playAgain;

  const GameResultPage({super.key, required this.result, required this.playAgain});

  @override
  State<GameResultPage> createState() => _GameResultPageState();
}

class _GameResultPageState extends State<GameResultPage> {
  static const Color _green = Color(0xFF2BB673);
  static const Color _pink = Color(0xFFEC407A);

  /// Rows shown before "+ N more".
  static const int _firstRows = 4;

  bool showAll = false;

  String get _cheer {
    final name = CurrentKid.name;
    final who = (name == null || name.isEmpty) ? '' : ', $name';
    final score = widget.result.score;
    if (score >= ScoreBand.great) return 'Amazing$who! 🌟';
    if (score >= ScoreBand.pass) return '${widget.result.praise}$who! 🎉';
    return 'Good try$who! Keep playing 💪';
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final look = result.look;

    // Rounds with mistakes first: those matter most to parents and therapists.
    final rows = [...result.rows.where((r) => r.score < 100), ...result.rows.where((r) => r.score >= 100)];
    final shown = showAll || rows.length <= _firstRows + 1 ? rows : rows.take(_firstRows).toList();

    return ResultCard(
      child: Column(
        children: [
          // ---- For the child ----
          DinoMascot(color: look.dinoColor, size: 90),
          Text(
            '${result.title} Complete!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _green),
          ),
          const Text(
            'Game',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: PracticeColors.soft),
          ),
          const SizedBox(height: 6),
          ResultStars(count: ScoreBand.starsFor(result.score)),
          const SizedBox(height: 4),
          Text(
            _cheer,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _pink),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(color: look.lightColor, borderRadius: BorderRadius.circular(18)),
            child: Text(
              result.win,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: look.darkColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < result.stats.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                ResultStatBox(
                  emoji: result.stats[i].emoji,
                  value: result.stats[i].value,
                  label: result.stats[i].label,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // ---- For parents & therapists ----
          const ResultDetailsTitle(),
          const SizedBox(height: 6),
          for (final row in shown) _Row(row: row),
          if (shown.length < rows.length)
            GestureDetector(
              onTap: () => setState(() {
                showAll = true;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '+ ${rows.length - shown.length} more',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: PracticeColors.soft),
                ),
              ),
            ),
          if (result.note != null) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFFF3D6), borderRadius: BorderRadius.circular(14)),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: result.note!.$1, style: const TextStyle(color: Color(0xFFE65100))),
                  TextSpan(text: result.note!.$2),
                ]),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: PracticeColors.ink),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ResultButton(
            label: '🔁 PLAY AGAIN',
            filled: true,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => widget.playAgain()),
            ),
          ),
          const SizedBox(height: 12),
          ResultButton(label: '🏠 DONE', filled: false, onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final GameResultRow row;

  const _Row({required this.row});

  @override
  Widget build(BuildContext context) {
    final isText = row.lead.runes.every((r) => r < 128);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ScoreBand.lightColorFor(row.score),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              row.lead,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: isText ? 18 : 22, fontWeight: FontWeight.w900, color: PracticeColors.ink),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: PracticeColors.ink),
                ),
                if (row.detail.isNotEmpty)
                  Text(
                    row.detail,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PracticeColors.soft),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(minWidth: 56),
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: ScoreBand.colorFor(row.score), borderRadius: BorderRadius.circular(10)),
            child: Text(
              row.pill,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
