import 'package:flutter/material.dart';
import 'package:talkiepal/practice/practice_session.dart';
import 'package:talkiepal/practice/widgets/practice_scaffold.dart';
import 'package:talkiepal/practice/widgets/result_widgets.dart';
import 'package:talkiepal/practice/widgets/score_dialog.dart';
import 'package:talkiepal/services/current_kid.dart';
import 'package:talkiepal/services/progress_store.dart';
import 'package:talkiepal/widgets/dino_mascot.dart';

/// Results at the end of a practice: stars and overall score for the child,
/// and every word with its score and tries for parents and therapists.
class ResultPage extends StatefulWidget {
  final PracticeSession session;
  final PracticeLook look;

  /// e.g. "Animals" or "Sound R".
  final String title;

  /// Opens the same practice with only the given items (the hard ones).
  final Widget Function(List<String> labels)? practiseAgain;

  const ResultPage({super.key, required this.session, required this.look, required this.title, this.practiseAgain});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  static const Color _green = Color(0xFF2BB673);
  static const Color _pink = Color(0xFFEC407A);

  PracticeSession get session => widget.session;
  PracticeLook get look => widget.look;
  String get title => widget.title;

  @override
  void initState() {
    super.initState();
    // Saved for the Progress pages.
    ProgressStore.instance.save(SessionRecord.fromPractice(session, level: look.name, topic: title));
  }

  String get _cheer {
    final name = CurrentKid.name;
    final score = session.overallScore;
    final who = (name == null || name.isEmpty) ? '' : ', $name';
    if (score >= ScoreBand.great) return 'Amazing$who! 🌟';
    if (score >= ScoreBand.pass) return 'Great job$who! 🎉';
    return 'Good try$who! Keep practising 💪';
  }

  String get _time {
    final minutes = session.duration.inMinutes;
    return minutes < 1 ? '<1 min' : '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final hard = session.hardItems;
    final items = session.items;

    return ResultCard(
      child: Column(
        children: [
          // ---- For the child ----
          DinoMascot(color: look.dinoColor, size: 90),
          Text(
            '$title Complete!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _green),
          ),
          Text(
            look.name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: PracticeColors.soft),
          ),
          const SizedBox(height: 6),
          ResultStars(count: ScoreBand.starsFor(session.overallScore)),
          const SizedBox(height: 4),
          Text(
            _cheer,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: _pink),
          ),
          const SizedBox(height: 14),
          ScoreBar(
            score: session.overallScore,
            label: session.isQuiz ? 'RIGHT ON THE FIRST TRY' : 'OVERALL SPEAKING SCORE',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ResultStatBox(
                emoji: '✅',
                value: '${session.passedCount}/${items.length}',
                label: session.isQuiz ? 'first try' : 'words passed',
              ),
              const SizedBox(width: 8),
              ResultStatBox(emoji: session.isQuiz ? '👆' : '🎤', value: '${session.totalTries}', label: 'tries'),
              const SizedBox(width: 8),
              ResultStatBox(emoji: '⏱', value: _time, label: 'time'),
            ],
          ),
          const SizedBox(height: 16),

          // ---- For parents & therapists ----
          const ResultDetailsTitle(),
          if (!session.isQuiz)
            const Wrap(
              spacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _Legend(color: ScoreBand.greatColor, text: '85%+ great'),
                _Legend(color: ScoreBand.almostColor, text: '70–84% almost'),
                _Legend(color: ScoreBand.lowColor, text: 'below 70% practise'),
              ],
            ),
          const SizedBox(height: 8),
          for (final item in items) _ResultRow(item: item, isQuiz: session.isQuiz),
          if (hard.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(14)),
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '🎯 Practise again: ',
                      style: TextStyle(color: ScoreBand.lowColor),
                    ),
                    TextSpan(text: hard.map((i) => i.label).join(', ')),
                  ],
                ),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: PracticeColors.ink),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (hard.isNotEmpty && widget.practiseAgain != null) ...[
            ResultButton(
              label: hard.length == 1
                  ? '🔁 PRACTISE THE HARD ONE'
                  : '🔁 PRACTISE ${hard.length} HARD ${session.isQuiz ? 'QUESTIONS' : 'WORDS'}',
              filled: true,
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => widget.practiseAgain!(hard.map((i) => i.label).toList())),
              ),
            ),
            const SizedBox(height: 12),
          ],
          ResultButton(
            label: '🏠 DONE',
            filled: hard.isEmpty || widget.practiseAgain == null,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final PracticeItemResult item;
  final bool isQuiz;

  const _ResultRow({required this.item, required this.isQuiz});

  @override
  Widget build(BuildContext context) {
    final score = item.bestScore ?? 0;

    final String pill;
    final Color pillColor;
    if (item.wasSkipped) {
      pill = 'skipped';
      pillColor = const Color(0xFFBDBDBD);
    } else if (isQuiz) {
      pill = score == 100 ? '1st try' : '${item.tries} tries';
      pillColor = score == 100 ? ScoreBand.greatColor : ScoreBand.almostColor;
    } else {
      pill = '$score%';
      pillColor = ScoreBand.colorFor(score);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: item.wasSkipped ? const Color(0xFFF5F5F5) : ScoreBand.lightColorFor(isQuiz && score < 100 ? 75 : score),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              item.emoji ?? (isQuiz ? '❓' : item.label),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: item.emoji != null || isQuiz ? 22 : 18, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isQuiz || item.label.length > 14 ? 13 : 15,
                fontWeight: FontWeight.w900,
                color: PracticeColors.ink,
              ),
            ),
          ),
          if (!isQuiz)
            Text(
              '${item.tries}× 🎤',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: PracticeColors.soft),
            ),
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(minWidth: 56),
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: pillColor, borderRadius: BorderRadius.circular(10)),
            child: Text(
              pill,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: PracticeColors.soft),
        ),
      ],
    );
  }
}
