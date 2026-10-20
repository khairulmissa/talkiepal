import 'package:flutter/material.dart';
import 'package:talkiepal/parent/parent_profile_screen.dart';
import 'package:talkiepal/practice/widgets/score_dialog.dart';
import 'package:talkiepal/services/parent_report.dart';
import 'package:talkiepal/services/progress_store.dart';

// Colours of the parent area.
const Color _cream = Color(0xFFF5EFE8);
const Color _yellow = Color(0xFFFFEFA8);
const Color _purple = Color(0xFF8B5E9E);
const Color _ink = Color(0xFF3D3346);
const Color _soft = Color(0xFF7A6F82);
const Color _track = Color(0xFFECE6EF);
const Color _rowColor = Color(0xFFF7F3F9);

const List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "13 Oct"
String _date(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// "4:12 pm"
String _clock(DateTime d) {
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$hour:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'pm' : 'am'}';
}

/// "Today, 4:12 pm", "Yesterday, 8:30 pm" or "16 Oct, 8:01 pm".
String _when(DateTime d, DateTime now) {
  final day = DateTime(d.year, d.month, d.day);
  final today = DateTime(now.year, now.month, now.day);
  final ago = today.difference(day).inDays;
  final name = ago == 0 ? 'Today' : (ago == 1 ? 'Yesterday' : _date(d));
  return '$name, ${_clock(d)}';
}

/// "52 min" or "<1 min"
String _minutes(Duration t) => t.inMinutes < 1 ? '<1 min' : '${t.inMinutes} min';

/// "58%", "7/10" for game rounds or "—".
String _pillText(SessionRecord s) {
  if (s.isGame && s.topic != 'Pop the Balloon' && s.topic != 'Voice Rocket') return '${s.passedCount}/${s.itemCount}';
  if (s.isQuiz) return '${s.passedCount}/${s.itemCount}';
  return '${s.score}%';
}

String _sessionEmoji(SessionRecord s) {
  if (s.isGame) return ParentReport.games.firstWhere((g) => g.$2 == s.topic, orElse: () => ('🎮', '')).$1;
  for (final (look, emojis) in ParentReport.levels) {
    if (look.name == s.level) return emojis[s.topic] ?? look.letter;
  }
  return '📝';
}

String _sessionTitle(SessionRecord s) => s.isGame ? s.topic : '${s.level} · ${s.topic}';

/// Progress of the parent's children: summary, levels, games, words to
/// practise and every session, worked out from what each child saved.
class ParentProgressScreen extends StatefulWidget {
  const ParentProgressScreen({super.key});

  /// Open it with this route name, so Home in the menu can close it.
  static const String routeName = 'parentProgress';

  static Future<void> open(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (_) => const ParentProgressScreen(),
    ),
  );

  @override
  State<ParentProgressScreen> createState() => _ParentProgressScreenState();
}

class _ParentProgressScreenState extends State<ParentProgressScreen> {
  List<ChildProfile> children = [];
  ChildProfile? child;
  ParentReport? report;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      final list = await ProgressStore.instance.children();
      if (!mounted) return;
      setState(() {
        children = list;
      });
      if (list.isEmpty) {
        setState(() {
          isLoading = false;
        });
      } else {
        await _open(list.first);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Unable to load progress: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _open(ChildProfile picked) async {
    setState(() {
      child = picked;
      isLoading = true;
      error = null;
    });
    try {
      final sessions = await ProgressStore.instance.sessions(childId: picked.id);
      if (!mounted || child != picked) return;
      setState(() {
        report = ParentReport(sessions);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Unable to load progress: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ParentFrame(
      title: 'Progress',
      icon: Icons.bar_chart,
      children: [
        if (children.length > 1) _buildPicker(),
        if (children.length <= 1) const SizedBox(height: 12),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 120),
            child: Center(child: CircularProgressIndicator(color: _purple)),
          )
        else if (error != null)
          _Card(
            child: Text(error!, style: const TextStyle(color: Colors.red)),
          )
        else if (child == null)
          const _Card(child: Text('No children added yet. Add a child on the Home page to see their progress.'))
        else if (report!.sessions.isEmpty)
          _Card(
            child: Text(
              '${child!.name} has not finished a practice or game yet. '
              'Their progress will show here after the first one. 🦖',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink),
            ),
          )
        else
          ..._buildReport(report!, child!),
      ],
    );
  }

  Widget _buildPicker() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          for (final kid in children)
            GestureDetector(
              onTap: kid == child ? null : () => _open(kid),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
                decoration: BoxDecoration(
                  color: kid == child ? _purple : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _purple, width: 1.5),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: _yellow,
                      backgroundImage: kid.photo != null ? MemoryImage(kid.photo!) : null,
                      child: kid.photo == null ? const Icon(Icons.child_care, size: 16, color: _ink) : null,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      kid.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: kid == child ? Colors.white : _purple,
                      ),
                    ),
                    if (kid == child) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.check_circle, size: 15, color: Colors.white),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildReport(ParentReport r, ChildProfile kid) {
    final target = r.targetSound(kid.targetSound);
    final week = r.thisWeek;
    final weak = r.needsAttention;
    final strong = r.strongest;
    final changes = r.changes;
    final words = r.wordsToPractise;
    final mixed = r.mixedUp;
    final recent = r.sessions.take(4).toList();

    void openDetail({required String level, String? topic}) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProgressDetailScreen(
            report: r.detail(level: level, topic: topic),
            childName: kid.name,
          ),
        ),
      );
    }

    void openLine(ScoreLine line) => openDetail(level: line.level, topic: line.level == 'Game' ? line.topic : null);

    return [
      if (target != null) _Card(child: _TargetSoundCard(target: target)),
      if (weak.isNotEmpty || strong.isNotEmpty || changes.isNotEmpty)
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Heading('📌 Summary', right: 'last 2 weeks'),
              if (weak.isNotEmpty) ...[
                const _GroupTitle('⚠️ Needs attention (below 70%)', ScoreBand.lowColor),
                for (final line in weak) _LineRow(line: line, onTap: () => openLine(line)),
              ],
              if (strong.isNotEmpty) ...[
                const _GroupTitle('⭐ Strongest (85% and up)', ScoreBand.greatColor),
                for (final line in strong) _LineRow(line: line, onTap: () => openLine(line)),
              ],
              if (changes.isNotEmpty) ...[
                const _GroupTitle('📈 Changes', _purple),
                for (final c in changes) _ChangeRow(change: c),
              ],
            ],
          ),
        ),
      _Card(
        child: Column(
          children: [
            _Heading(
              'This week',
              right: '${_date(r.thisMonday)} – ${_date(r.thisMonday.add(const Duration(days: 6)))}',
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Number('${week.sessions}', 'sessions'),
                _Number(_minutes(week.time), 'practice'),
                _Number('${week.days}/7', 'days'),
                _Number(
                  week.speaking == null ? '—' : '${week.speaking}%',
                  'speaking',
                  change: week.speakingChange,
                  color: week.speaking == null ? null : ScoreBand.colorFor(week.speaking!),
                ),
                _Number(
                  week.games == null ? '—' : '${week.games}%',
                  'games',
                  change: week.gamesChange,
                  color: week.games == null ? null : ScoreBand.colorFor(week.games!),
                ),
              ],
            ),
          ],
        ),
      ),
      _Card(
        child: Column(
          children: [
            const _Heading('Speaking score, week by week'),
            _WeekChart(weeks: r.weeks),
          ],
        ),
      ),
      _Card(
        child: Column(
          children: [
            const _Heading('Levels'),
            for (final level in r.levelScores)
              _LevelRow(
                level: level,
                onTap: () => openDetail(level: level.look.name),
              ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Intermediate questions count as right on the first try.',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _soft),
              ),
            ),
          ],
        ),
      ),
      _Card(
        child: Column(
          children: [
            const _Heading('Games'),
            for (final game in r.gameScores)
              _ScoreRow(
                lead: game.emoji,
                label: game.name,
                sub: game.sub,
                score: game.score,
                onTap: game.score == null ? null : () => openDetail(level: 'Game', topic: game.name),
              ),
          ],
        ),
      ),
      if (words.isNotEmpty)
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Heading('🎯 Words to practise'),
              const Text(
                'Lowest best score in the last 2 weeks',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _soft),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [for (final w in words) _WordChip(word: w)]),
            ],
          ),
        ),
      if (mixed.isNotEmpty)
        _Card(
          child: Column(
            children: [
              const _Heading('🔎 Sounds often mixed up'),
              for (final m in mixed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          m.pair,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          m.games.join(', '),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _soft),
                        ),
                      ),
                      Text(
                        '${m.count}×',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _ink),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      _Card(
        child: Column(
          children: [
            _Heading(
              '🕑 Recent activity',
              right: r.sessions.length > recent.length ? 'See all' : null,
              onRightTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AllSessionsScreen(sessions: r.sessions, childName: kid.name),
                ),
              ),
            ),
            for (final s in recent) _SessionRow(session: s, childName: kid.name, now: r.now),
          ],
        ),
      ),
    ];
  }
}

/// A level (e.g. Special Sound) or a game: score over time, each topic and
/// every session.
class ProgressDetailScreen extends StatelessWidget {
  final DetailReport report;
  final String childName;

  const ProgressDetailScreen({super.key, required this.report, required this.childName});

  @override
  Widget build(BuildContext context) {
    final r = report;
    final now = DateTime.now();

    return _ParentFrame(
      title: r.title,
      sub: childName,
      back: true,
      children: [
        const SizedBox(height: 12),
        if (r.sessions.isEmpty)
          const _Card(child: Text('Nothing practised here yet.'))
        else ...[
          _Card(
            child: Row(
              children: [
                _Number(
                  '${r.score}%',
                  r.sessions.any((s) => s.isGame) ? 'average' : 'avg score',
                  color: ScoreBand.colorFor(r.score!),
                  big: true,
                ),
                _Number('${r.sessions.length}', 'sessions', big: true),
                if (r.change != null)
                  _Number(
                    '${r.change! >= 0 ? '+' : ''}${r.change}%',
                    'since the start',
                    color: r.change! >= 0 ? ScoreBand.greatColor : ScoreBand.lowColor,
                    big: true,
                  ),
              ],
            ),
          ),
          _Card(
            child: Column(
              children: [
                const _Heading('Score over time'),
                _SessionChart(sessions: r.trend),
              ],
            ),
          ),
          if (r.parts.isNotEmpty)
            _Card(
              child: Column(
                children: [
                  _Heading(r.sessions.first.isGame ? 'By sound' : 'By topic'),
                  for (final p in r.parts)
                    _ScoreRow(lead: p.lead, label: p.label, sub: p.sub, score: p.score, filled: true),
                ],
              ),
            ),
          _Card(
            child: Column(
              children: [
                const _Heading('Sessions'),
                for (final s in r.sessions.take(20)) _SessionRow(session: s, childName: childName, now: now),
                const Text(
                  'Tap a session to see every word',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _soft),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Every session of a child, newest first.
class AllSessionsScreen extends StatelessWidget {
  final List<SessionRecord> sessions;
  final String childName;

  const AllSessionsScreen({super.key, required this.sessions, required this.childName});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return _ParentFrame(
      title: 'All activity',
      sub: childName,
      back: true,
      children: [
        const SizedBox(height: 12),
        _Card(
          child: Column(
            children: [for (final s in sessions) _SessionRow(session: s, childName: childName, now: now)],
          ),
        ),
      ],
    );
  }
}

/// One finished practice or game: its numbers and every word or round.
class SessionDetailScreen extends StatelessWidget {
  final SessionRecord session;
  final String childName;

  const SessionDetailScreen({super.key, required this.session, required this.childName});

  @override
  Widget build(BuildContext context) {
    final s = session;
    final rows = s.items.where((i) => i['label'] != null).toList();
    final notes = s.items.where((i) => i['note'] != null).map((i) => i['note'] as String).toList();

    return _ParentFrame(
      title: s.topic,
      sub: '$childName · ${_when(s.finishedAt, DateTime.now())}',
      back: true,
      children: [
        const SizedBox(height: 12),
        _Card(
          child: Row(
            children: [
              _Number(
                '${s.score}%',
                s.isGame ? 'score' : (s.isQuiz ? '1st try' : 'speaking'),
                color: ScoreBand.colorFor(s.score),
                big: true,
              ),
              _Number('${s.passedCount}/${s.itemCount}', s.isGame ? 'rounds passed' : 'passed', big: true),
              if (!s.isGame) _Number('${s.tries}', 'tries', big: true),
              _Number(_minutes(s.time), 'time', big: true),
            ],
          ),
        ),
        _Card(
          child: Column(
            children: [
              _Heading(s.isGame ? 'Every round' : (s.isQuiz ? 'Every question' : 'Every word')),
              for (final item in rows) s.isGame ? _GameItemRow(item: item) : _WordRow(item: item, isQuiz: s.isQuiz),
            ],
          ),
        ),
        for (final note in notes)
          _Card(
            child: Text(
              note,
              style: const TextStyle(fontWeight: FontWeight.bold, color: _ink),
            ),
          ),
      ],
    );
  }
}

// ---------------- Shared pieces ----------------

/// Yellow top bar, cream page and the parent menu at the bottom.
class _ParentFrame extends StatelessWidget {
  final String title;
  final String? sub;
  final IconData icon;
  final bool back;
  final List<Widget> children;

  const _ParentFrame({
    required this.title,
    required this.children,
    this.sub,
    this.icon = Icons.bar_chart,
    this.back = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(8, 12, 16, 14),
                      decoration: const BoxDecoration(
                        color: _yellow,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
                      ),
                      child: Row(
                        children: [
                          if (back)
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: _ink),
                              onPressed: () => Navigator.pop(context),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.bar_chart, color: _ink),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: _ink),
                                ),
                                if (sub != null)
                                  Text(
                                    sub!,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _soft),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...children,
                  ],
                ),
              ),
            ),
            const _ParentNav(),
          ],
        ),
      ),
    );
  }
}

/// The parent menu, with Progress selected.
class _ParentNav extends StatelessWidget {
  const _ParentNav();

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String label, {bool selected = false, VoidCallback? onTap}) => InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 27, color: selected ? _purple : Colors.grey),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selected ? _purple : Colors.grey),
            ),
          ],
        ),
      ),
    );

    return Container(
      height: 68,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          item(Icons.home, 'Home', onTap: () => _goHome(context)),
          item(Icons.bar_chart, 'Progress', selected: true),
          item(Icons.medical_services, 'Therapist'),
          item(
            Icons.person,
            'Profile',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentProfileScreen())),
          ),
        ],
      ),
    );
  }
}

/// Back to the parent home: closes Progress and every page opened from it.
void _goHome(BuildContext context) {
  Navigator.popUntil(context, (route) => route.settings.name == ParentProgressScreen.routeName || route.isFirst);
  if (Navigator.canPop(context)) Navigator.pop(context);
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: child,
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  final String? right;
  final VoidCallback? onRightTap;

  const _Heading(this.text, {this.right, this.onRightTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _ink),
            ),
          ),
          if (right != null)
            GestureDetector(
              onTap: onRightTap,
              child: Text(
                right!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _purple),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  final String text;
  final Color color;

  const _GroupTitle(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}

/// Picture or short text at the start of a row.
class _Lead extends StatelessWidget {
  final String text;

  const _Lead(this.text);

  @override
  Widget build(BuildContext context) {
    final isText = text.runes.every((r) => r < 128);
    return SizedBox(
      width: 32,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: isText ? 15 : 19, fontWeight: FontWeight.bold, color: _ink),
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  final ScoreLine line;
  final VoidCallback onTap;

  const _LineRow({required this.line, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _ScoreRow(lead: line.lead, label: line.label, sub: line.sub, score: line.score, onTap: onTap, filled: true);
  }
}

/// A row with a coloured score pill, optionally tappable.
class _ScoreRow extends StatelessWidget {
  final String lead;
  final String label;
  final String sub;

  /// Null shows a grey "—".
  final int? score;
  final VoidCallback? onTap;

  /// Coloured background by score band.
  final bool filled;

  const _ScoreRow({
    required this.lead,
    required this.label,
    required this.sub,
    required this.score,
    this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: EdgeInsets.symmetric(horizontal: filled ? 8 : 0, vertical: filled ? 6 : 2),
        decoration: filled && score != null
            ? BoxDecoration(color: ScoreBand.lightColorFor(score!), borderRadius: BorderRadius.circular(12))
            : null,
        child: Row(
          children: [
            _Lead(lead),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: _ink),
                  ),
                  if (sub.isNotEmpty)
                    Text(
                      sub,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _soft),
                    ),
                ],
              ),
            ),
            _Pill(
              score == null ? '—' : '$score%',
              score == null ? const Color(0xFFBDBDBD) : ScoreBand.colorFor(score!),
            ),
            SizedBox(
              width: 20,
              child: onTap == null ? null : const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  final ScoreChange change;

  const _ChangeRow({required this.change});

  @override
  Widget build(BuildContext context) {
    final c = change;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          _Lead(c.isUp ? '📈' : '📉'),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${c.label}: ${c.isUp ? 'up' : 'down'} from ${c.from}% to ${c.to}%',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: c.isUp ? ScoreBand.greatColor : ScoreBand.lowColor,
                  ),
                ),
                Text(
                  c.isUp
                      ? 'this week, compared with before · keep going!'
                      : 'this week, compared with before · practise again',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _soft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetSoundCard extends StatelessWidget {
  final TargetSound target;

  const _TargetSoundCard({required this.target});

  @override
  Widget build(BuildContext context) {
    final t = target;
    final String sub;
    if (t.sessions == 0) {
      sub = 'Not practised yet · try Special Sound ${t.sound}';
    } else if (t.sessions <= 3 || t.weeks == 0) {
      sub = '${t.sessions} ${t.sessions == 1 ? 'session' : 'sessions'} so far';
    } else {
      sub =
          '${t.first}% to ${t.latest}% in ${t.weeks} ${t.weeks == 1 ? 'week' : 'weeks'}'
          '${t.latest! >= t.first! ? ' · keep going!' : ''}';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: t.latest == null ? _rowColor : ScoreBand.lightColorFor(t.latest!),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Target sound /${t.sound}/',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _ink),
                ),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _soft),
                ),
              ],
            ),
          ),
          if (t.latest != null) _Pill('${t.latest}%', ScoreBand.colorFor(t.latest!)),
        ],
      ),
    );
  }
}

/// A number with a label under it, and an optional change ("+6%").
class _Number extends StatelessWidget {
  final String value;
  final String label;
  final int? change;
  final Color? color;
  final bool big;

  const _Number(this.value, this.label, {this.change, this.color, this.big = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: big ? 24 : 18, fontWeight: FontWeight.bold, color: color ?? _ink),
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _soft),
          ),
          if (change != null && change != 0)
            Text(
              '${change! > 0 ? '+' : ''}$change%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: change! > 0 ? ScoreBand.greatColor : ScoreBand.lowColor,
              ),
            ),
        ],
      ),
    );
  }
}

/// Bars with a score on top and a date under them.
class _Bars extends StatelessWidget {
  final List<(String, int?)> bars;

  const _Bars({required this.bars});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final (label, score) in bars)
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  score == null ? '' : '$score%',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: score == null ? _soft : ScoreBand.colorFor(score),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 28,
                  height: score == null ? 3 : 4 + score * 0.85,
                  decoration: BoxDecoration(
                    color: score == null ? _track : ScoreBand.colorFor(score),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _soft),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  final List<WeekScore> weeks;

  const _WeekChart({required this.weeks});

  @override
  Widget build(BuildContext context) => _Bars(bars: [for (final w in weeks) (_date(w.monday), w.score)]);
}

class _SessionChart extends StatelessWidget {
  final List<SessionRecord> sessions;

  const _SessionChart({required this.sessions});

  @override
  Widget build(BuildContext context) =>
      _Bars(bars: [for (final s in sessions) ('${s.finishedAt.day}/${s.finishedAt.month}', s.score)]);
}

class _LevelRow extends StatelessWidget {
  final LevelScore level;
  final VoidCallback onTap;

  const _LevelRow({required this.level, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = level;
    final score = l.score;

    return GestureDetector(
      onTap: l.sessions == 0 ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: l.look.color,
              child: Text(
                l.look.letter,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 112,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.look.name,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: _ink),
                  ),
                  Text(
                    '${l.done}/${l.total} topics · ${l.sessions} ${l.sessions == 1 ? 'session' : 'sessions'}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _soft),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                height: 10,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(color: _track, borderRadius: BorderRadius.circular(10)),
                child: FractionallySizedBox(
                  widthFactor: (score ?? 0) / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: score == null ? _track : ScoreBand.colorFor(score),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 38,
              child: Text(
                score == null ? '—' : '$score%',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: score == null ? _soft : ScoreBand.colorFor(score),
                ),
              ),
            ),
            SizedBox(
              width: 20,
              child: l.sessions == 0 ? null : const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final WordScore word;

  const _WordChip({required this.word});

  @override
  Widget build(BuildContext context) {
    final color = ScoreBand.colorFor(word.score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: ScoreBand.lightColorFor(word.score),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        '${word.emoji == null ? '' : '${word.emoji} '}${word.word}  ${word.score}%',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _ink),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final SessionRecord session;
  final String childName;
  final DateTime now;

  const _SessionRow({required this.session, required this.childName, required this.now});

  @override
  Widget build(BuildContext context) {
    final s = session;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SessionDetailScreen(session: s, childName: childName),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: _rowColor, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            _Lead(_sessionEmoji(s)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _sessionTitle(s),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: _ink),
                  ),
                  Text(
                    '${_when(s.finishedAt, now)} · ${_minutes(s.time)}',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _soft),
                  ),
                ],
              ),
            ),
            _Pill(_pillText(s), ScoreBand.colorFor(s.score)),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

/// A word or question of a practice.
class _WordRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isQuiz;

  const _WordRow({required this.item, required this.isQuiz});

  @override
  Widget build(BuildContext context) {
    final label = item['label'] as String;
    final score = (item['score'] as num?)?.toInt();
    final tries = (item['tries'] as num?)?.toInt() ?? 0;
    final heard = item['heard'] as String?;

    final String pill;
    if (score == null) {
      pill = 'skipped';
    } else if (isQuiz) {
      pill = score == 100 ? '1st try' : '$tries tries';
    } else {
      pill = '$score%';
    }
    final band = score == null ? null : (isQuiz && score < 100 ? ScoreBand.pass : score);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: band == null ? _rowColor : ScoreBand.lightColorFor(band),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Lead(item['emoji'] as String? ?? (isQuiz ? '❓' : (label.length <= 2 ? label : '🗣️'))),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: _ink),
                ),
                if (heard != null && !isQuiz)
                  Text(
                    'heard "$heard"',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _soft),
                  ),
              ],
            ),
          ),
          if (!isQuiz)
            Text(
              '$tries× 🎤',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: _soft),
            ),
          const SizedBox(width: 8),
          _Pill(pill, band == null ? const Color(0xFFBDBDBD) : ScoreBand.colorFor(band)),
        ],
      ),
    );
  }
}

/// A round of a game, as on its results screen.
class _GameItemRow extends StatelessWidget {
  final Map<String, dynamic> item;

  const _GameItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final score = (item['score'] as num?)?.toInt() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: ScoreBand.lightColorFor(score), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _Lead(item['lead'] as String? ?? ''),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['label'] as String,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _ink),
                ),
                if ((item['detail'] as String? ?? '').isNotEmpty)
                  Text(
                    item['detail'] as String,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: _soft),
                  ),
              ],
            ),
          ),
          _Pill(item['pill'] as String? ?? '$score%', ScoreBand.colorFor(score)),
        ],
      ),
    );
  }
}
