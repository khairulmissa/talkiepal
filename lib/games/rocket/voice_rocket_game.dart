import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:talkiepal/games/game_result_page.dart';
import 'package:talkiepal/games/rocket/rocket_world.dart';
import 'package:talkiepal/games/rocket/voice_input.dart';
import 'package:talkiepal/games/widgets/game_scaffold.dart';
import 'package:talkiepal/practice/widgets/practice_scaffold.dart';
import 'package:talkiepal/widgets/dino_mascot.dart';

/// One level: where the rocket flies and the sound that makes it fly.
class _Level {
  final String emoji;
  final String place;
  final String sound;

  const _Level(this.emoji, this.place, this.sound);
}

/// How the child did on one level, for the results screen.
class _LevelScore {
  int tries = 1;

  /// Seconds the child kept the sound going, at most.
  double longestVoice = 0;

  /// Seconds it took to reach the place.
  int flightTime = 0;
}

/// Voice Rocket (Flame): the child holds the button and makes a long, loud
/// sound (AAAH, OOOO...) to fly the rocket. Only how loud they are is used;
/// nothing is recorded or saved.
class VoiceRocketGame extends StatefulWidget {
  final int seconds;

  /// Where the loudness comes from. Tests pass a fake microphone.
  final VoiceInput Function()? voiceInput;

  const VoiceRocketGame({super.key, this.seconds = 45, this.voiceInput});

  @override
  State<VoiceRocketGame> createState() => _VoiceRocketGameState();
}

enum _Phase { ready, noMic, calibrating, playing, levelDone, won, timeUp }

class _VoiceRocketGameState extends State<VoiceRocketGame> {
  static const GameLook _look = GameLook.voiceRocket;
  static const Color _pink = Color(0xFFD81B8C);

  static const List<_Level> _levels = [
    _Level('🌙', 'the Moon', 'AAAH'),
    _Level('🔴', 'Mars', 'OOOO'),
    _Level('🪐', 'Saturn', 'EEEE'),
    _Level('⭐', 'the Star', 'MMMM'),
    _Level('🌌', 'the Galaxy', 'SSSS'),
  ];

  // How long the room noise is measured before each level.
  static const Duration _calibrateTime = Duration(seconds: 2);

  late final VoiceInput _voice = (widget.voiceInput ?? MicVoiceInput.new)();
  StreamSubscription<double>? _listening;

  _Phase phase = _Phase.ready;
  int level = 0;
  RocketGame? game;

  int stars = 0;
  int starsThisLevel = 0;
  int secondsLeft = 0;
  Timer? _timer;

  bool isHolding = false;
  double loudness = 0;

  // Stars and the longest voice for each level, and when the game started.
  final Map<int, _LevelScore> _scores = {};
  final DateTime _startedAt = DateTime.now();

  // Loudness needed to fly, set from the room noise so a noisy room still works.
  double threshold = 0.35;
  final List<double> _roomNoise = [];

  _Level get currentLevel => _levels[level];
  bool get isLastLevel => level == _levels.length - 1;
  bool get isLoudEnough => loudness >= threshold;

  @override
  void initState() {
    super.initState();
    _openLevel(0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _listening?.cancel();
    _voice.stop();
    _voice.dispose();
    super.dispose();
  }

  void _openLevel(int i) {
    _timer?.cancel();
    setState(() {
      level = i;
      starsThisLevel = 0;
      _scores.putIfAbsent(i, _LevelScore.new);
      isHolding = false;
      game = RocketGame(
        destination: _levels[i].emoji,
        onStar: _onStar,
        onArrived: _onArrived,
      );
      phase = _Phase.ready;
    });
  }

  Future<void> _start() async {
    if (_listening == null) {
      final allowed = await _voice.requestPermission();
      if (!mounted) return;
      if (!allowed) {
        setState(() {
          phase = _Phase.noMic;
        });
        return;
      }

      final stream = await _voice.start();
      if (!mounted) return;
      _listening = stream.listen(_onLoudness);
    }

    // Measure the room first, then play.
    _roomNoise.clear();
    setState(() {
      phase = _Phase.calibrating;
    });

    await Future.delayed(_calibrateTime);
    if (!mounted || phase != _Phase.calibrating) return;

    final noise = _roomNoise.isEmpty ? 0.0 : _roomNoise.reduce((a, b) => a + b) / _roomNoise.length;
    threshold = (noise + 0.15).clamp(0.25, 0.7);

    setState(() {
      secondsLeft = widget.seconds;
      phase = _Phase.playing;
    });
    game?.start();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        secondsLeft--;
      });
      if (secondsLeft <= 0) _onTimeUp();
    });
  }

  void _onLoudness(double value) {
    if (!mounted) return;
    if (phase == _Phase.calibrating) _roomNoise.add(value);

    setState(() {
      // Smooth it a little so the meter does not jump around.
      loudness = loudness * 0.5 + value * 0.5;
    });
    _updateThrust();
  }

  void _setHolding(bool holding) {
    if (isHolding == holding) return;
    setState(() {
      isHolding = holding;
    });
    _updateThrust();
  }

  void _updateThrust() {
    final g = game;
    if (g == null) return;
    g.loudness = loudness;
    g.isThrusting = phase == _Phase.playing && isHolding && isLoudEnough;
  }

  /// Keeps the longest sound of this level for the results screen.
  void _endVoice() {
    final score = _scores[level];
    final g = game;
    if (score != null && g != null && g.longestSound > score.longestVoice) score.longestVoice = g.longestSound;
  }

  void _onStar() {
    if (!mounted) return;
    setState(() {
      stars++;
      starsThisLevel++;
    });
  }

  void _onArrived() {
    if (!mounted) return;
    _timer?.cancel();
    _endVoice();
    _scores[level]?.flightTime = widget.seconds - secondsLeft;
    if (!isLastLevel) {
      setState(() {
        phase = _Phase.levelDone;
        isHolding = false;
      });
      return;
    }

    setState(() {
      phase = _Phase.won;
      isHolding = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameResultPage(
          result: _result(),
          playAgain: () => VoiceRocketGame(seconds: widget.seconds, voiceInput: widget.voiceInput),
        ),
      ),
    );
  }

  /// The longest voice for each level. No speaking score: this game is
  /// only about a long, strong voice, and every level ends with all stars.
  GameResult _result() {
    String seconds(double s) => '${s.toStringAsFixed(1)} s';
    // 3 seconds of voice is good, 2 is almost there.
    int scoreFor(double voice) => voice >= 3 ? 100 : (voice >= 2 ? 75 : 40);

    final played = [for (var i = 0; i < _levels.length; i++) if (_scores[i] != null) (_levels[i], _scores[i]!)];
    final longest = played.fold(0.0, (best, p) => max(best, p.$2.longestVoice));

    // The sound held for the shortest time is the one to practise.
    final hardest = played.where((p) => p.$2.longestVoice < 3).toList()
      ..sort((a, b) => a.$2.longestVoice.compareTo(b.$2.longestVoice));

    return GameResult(
      title: 'Voice Rocket',
      look: _look,
      score: (stars * 100 / (_levels.length * 3)).round().clamp(0, 100).toInt(),
      praise: 'What a strong voice',
      win: '${_levels.last.emoji} Flew all the way to ${_levels.last.place}!',
      stats: [
        GameStat('⭐', '$stars', 'stars'),
        GameStat('🗣️', seconds(longest), 'longest voice'),
        GameStat('⏱', gameTime(DateTime.now().difference(_startedAt)), 'time'),
      ],
      rows: [
        for (final (lvl, score) in played)
          GameResultRow(
            lead: lvl.emoji,
            label: '${lvl.sound} to ${lvl.place}',
            detail: score.tries > 1
                ? 'flew in ${score.flightTime} s · ${score.tries} tries'
                : 'flew in ${score.flightTime} s',
            pill: '🗣️ ${seconds(score.longestVoice)}',
            score: scoreFor(score.longestVoice),
          ),
      ],
      note: hardest.isEmpty
          ? null
          : ('💪 Harder: ', 'long ${hardest.first.$1.sound} (longest ${seconds(hardest.first.$2.longestVoice)})'),
    );
  }

  /// Plays the same level again; its stars from the last try do not count twice.
  void _retryLevel() {
    setState(() {
      stars -= starsThisLevel;
    });
    _scores[level]?.tries++;
    _openLevel(level);
    _start();
  }

  void _onTimeUp() {
    _timer?.cancel();
    game?.stop();
    _endVoice();
    setState(() {
      phase = _Phase.timeUp;
      isHolding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1340), Color(0xFF3B2378), Color(0xFF7E57C2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            ..._buildSpace(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: GameHeader(look: _look, title: 'Voice Rocket 🚀', stars: stars),
                    ),
                    const SizedBox(height: 12),
                    _buildInstruction(),
                    const SizedBox(height: 8),
                    Expanded(child: _buildFlight()),
                    if (phase == _Phase.playing) ...[
                      const SizedBox(height: 8),
                      _buildHoldButton(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Twinkling dots and the Earth at the bottom.
  List<Widget> _buildSpace() {
    const dots = [
      [0.08, 0.07], [0.77, 0.05], [0.31, 0.18], [0.87, 0.25], [0.13, 0.36],
      [0.64, 0.39], [0.46, 0.11], [0.82, 0.5], [0.23, 0.54], [0.51, 0.62],
    ];

    return [
      for (final d in dots)
        Positioned.fill(
          child: Align(
            alignment: Alignment(d[0] * 2 - 1, d[1] * 2 - 1),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
            ),
          ),
        ),
      const Positioned(
        left: 0,
        right: 0,
        bottom: -60,
        child: Center(child: Text('🌍', style: TextStyle(fontSize: 150))),
      ),
    ];
  }

  Widget _buildInstruction() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _look.color, width: 3),
            ),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: 'Level ${level + 1}/${_levels.length}  ', style: TextStyle(color: _look.color)),
                const TextSpan(text: 'Say '),
                TextSpan(text: currentLevel.sound, style: const TextStyle(color: _pink, fontSize: 20)),
                const TextSpan(text: ' long!'),
              ]),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: PracticeColors.ink),
            ),
          ),
        ),
        if (phase == _Phase.playing) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: secondsLeft <= 10 ? const Color(0xFFE53935) : const Color(0xFFFF7043),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '⏱ 0:${secondsLeft.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFlight() {
    final showGame = phase == _Phase.playing || phase == _Phase.timeUp || phase == _Phase.levelDone;

    return Stack(
      children: [
        if (game != null)
          Positioned.fill(
            child: Row(
              children: [
                SizedBox(width: 30, child: _buildHeightBar()),
                Expanded(
                  child: Opacity(
                    opacity: showGame ? 1 : 0,
                    child: GameWidget(key: ValueKey(game), game: game!),
                  ),
                ),
                SizedBox(width: 60, child: _buildMeter()),
              ],
            ),
          ),
        if (phase == _Phase.playing)
          Positioned(left: 30, right: 60, bottom: 12, child: Center(child: _buildMessage())),
        if (phase == _Phase.ready) Center(child: _buildStartCard()),
        if (phase == _Phase.noMic) Center(child: _buildNoMicCard()),
        if (phase == _Phase.calibrating) Center(child: _buildCalibratingCard()),
        if (phase == _Phase.levelDone) Center(child: _buildLevelDoneCard()),
        if (phase == _Phase.timeUp) Center(child: _buildTimeUpCard()),
      ],
    );
  }

  /// How far the rocket has flown, from Earth to the destination.
  Widget _buildHeightBar() {
    final progress = game?.progress ?? 0;

    return Column(
      children: [
        Text(currentLevel.emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Expanded(
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 12,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
              ),
              FractionallySizedBox(
                heightFactor: progress,
                child: Container(
                  width: 12,
                  decoration: BoxDecoration(color: const Color(0xFFFFD54F), borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text('🌍', style: TextStyle(fontSize: 18)),
      ],
    );
  }

  /// How loud the child is, with a white line for "loud enough".
  Widget _buildMeter() {
    final loudEnough = isLoudEnough;

    return Column(
      children: [
        const Text('🎤', style: TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Expanded(
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: 30,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              FractionallySizedBox(
                heightFactor: loudness.clamp(0.02, 1.0),
                child: Container(
                  width: 26,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFFFFEE58), Color(0xFFFF7043)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              FractionallySizedBox(
                heightFactor: threshold,
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(width: 44, child: Divider(color: Colors.white, thickness: 3, height: 3)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          loudEnough ? 'GOOD!' : 'LOUDER!',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: loudEnough ? const Color(0xFFC8E6C9) : const Color(0xFFFFCDD2),
          ),
        ),
      ],
    );
  }

  Widget _buildMessage() {
    final String text;
    final Color color;

    if (!isHolding) {
      text = '👇 Hold the button and say ${currentLevel.sound}!';
      color = _look.color;
    } else if (isLoudEnough) {
      text = '🔥 Great! Keep saying ${currentLevel.sound}!';
      color = const Color(0xFF2E7D32);
    } else {
      text = "🙉 I can't hear you! Say it LOUDER!";
      color = const Color(0xFFE53935);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 3),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }

  /// Pressed down = listening; let go = rocket slows down.
  Widget _buildHoldButton() {
    return Listener(
      onPointerDown: (_) => _setHolding(true),
      onPointerUp: (_) => _setHolding(false),
      onPointerCancel: (_) => _setHolding(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isHolding ? const Color(0xFFC2185B) : PracticeColors.speak,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white, width: isHolding ? 5 : 3),
          boxShadow: [BoxShadow(color: PracticeColors.speakDark, offset: Offset(0, isHolding ? 2 : 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isHolding ? '🔴' : '🎤', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isHolding ? 'LISTENING... KEEP GOING!' : 'HOLD & SAY ${currentLevel.sound}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartCard() {
    return _buildCard(children: [
      DinoMascot(color: _look.dinoColor, size: 90),
      Text(
        'LEVEL ${level + 1} OF ${_levels.length}',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _look.color, letterSpacing: 1),
      ),
      const SizedBox(height: 6),
      Text.rich(
        TextSpan(children: [
          const TextSpan(text: 'Fly the rocket to '),
          TextSpan(
            text: '${currentLevel.place} ${currentLevel.emoji}',
            style: TextStyle(color: _look.color),
          ),
          const TextSpan(text: '!'),
        ]),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: PracticeColors.ink),
      ),
      const SizedBox(height: 8),
      Text.rich(
        TextSpan(children: [
          const TextSpan(text: 'Hold the button and say '),
          TextSpan(text: currentLevel.sound, style: const TextStyle(color: _pink, fontWeight: FontWeight.w900)),
          const TextSpan(text: ' loud and long. Stop and the rocket slows down!'),
        ]),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PracticeColors.soft),
      ),
      const SizedBox(height: 16),
      _buildButton('🚀', 'START', _start),
    ]);
  }

  Widget _buildNoMicCard() {
    return _buildCard(children: [
      const Text('🎤', style: TextStyle(fontSize: 56)),
      const Text(
        'Dino needs the microphone',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: PracticeColors.ink),
      ),
      const SizedBox(height: 6),
      const Text(
        'Ask a grown-up to allow the microphone for TalkiePal, then try again. Nothing is recorded.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PracticeColors.soft),
      ),
      const SizedBox(height: 16),
      _buildButton('🔄', 'TRY AGAIN', _start),
    ]);
  }

  Widget _buildCalibratingCard() {
    return _buildCard(children: [
      const Text('🤫', style: TextStyle(fontSize: 56)),
      const Text(
        'Shhh... get ready!',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: PracticeColors.ink),
      ),
      const SizedBox(height: 6),
      const Text(
        'Dino is listening to the room.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PracticeColors.soft),
      ),
      const SizedBox(height: 14),
      CircularProgressIndicator(color: _look.color),
    ]);
  }

  Widget _buildLevelDoneCard() {
    final next = _levels[level + 1];
    final longest = (game?.longestSound ?? 0).toStringAsFixed(1);

    return _buildCard(children: [
      Text('${currentLevel.emoji}🚀', style: const TextStyle(fontSize: 52)),
      Text(
        'You reached ${currentLevel.place}!',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32)),
      ),
      const SizedBox(height: 6),
      Text(
        'Your longest ${currentLevel.sound}: $longest seconds ⭐',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: PracticeColors.ink),
      ),
      const SizedBox(height: 10),
      Text.rich(
        TextSpan(children: [
          TextSpan(text: 'Next: fly to ${next.place} ${next.emoji}, say '),
          TextSpan(text: next.sound, style: const TextStyle(color: _pink, fontSize: 22)),
        ]),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: PracticeColors.ink),
      ),
      const SizedBox(height: 16),
      _buildButton('➡️', 'NEXT LEVEL', () => _openLevel(level + 1)),
    ]);
  }

  Widget _buildTimeUpCard() {
    final flown = ((game?.progress ?? 0) * 100).round();

    return _buildCard(children: [
      const Text('⏰', style: TextStyle(fontSize: 56)),
      const Text(
        "Time's up!",
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFE65100)),
      ),
      const SizedBox(height: 6),
      Text(
        'You flew $flown% of the way to ${currentLevel.place}. Try again!',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: PracticeColors.ink),
      ),
      const SizedBox(height: 16),
      _buildButton('🔄', 'PLAY AGAIN', _retryLevel),
    ]);
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _look.color, width: 4),
        boxShadow: [BoxShadow(color: _look.darkColor, offset: const Offset(0, 7))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _buildButton(String emoji, String label, VoidCallback onTap) {
    return SizedBox(
      width: 230,
      child: ChunkyButton(
        emoji: emoji,
        label: label,
        color: _look.color,
        darkColor: _look.darkColor,
        onTap: onTap,
      ),
    );
  }
}
