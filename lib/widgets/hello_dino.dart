import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:talkiepal/widgets/dino_mascot.dart';

/// A short hello after a child picks their profile: Dino pops up, waves,
/// shows "Hi" with the child's name and "Ready to practice?", then "Let's go!" and
/// opens [next]. Tapping anywhere skips straight to [next].
class HelloDinoScreen extends StatefulWidget {
  final String name;

  /// Dino's colour, the same as the child's profile card.
  final Color color;

  /// The page to open afterwards (the kids Home).
  final Route<void> Function() next;

  const HelloDinoScreen({super.key, required this.name, required this.color, required this.next});

  @override
  State<HelloDinoScreen> createState() => _HelloDinoScreenState();
}

enum _Step { pop, hello, ready, go }

class _HelloDinoScreenState extends State<HelloDinoScreen> with TickerProviderStateMixin {
  static const Color _cream = Color(0xFFFDF7E7);
  static const Color _ink = Color(0xFF26272B);
  static const Color _soft = Color(0xFF7A7468);

  // Dino jumping up from the bottom.
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  // Dino shrinking away at the end.
  late final AnimationController _out = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  // Sparkles twinkling and confetti falling.
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(seconds: 2))
    ..repeat();

  _Step step = _Step.pop;
  bool _left = false;

  // Fixed positions so sparkles and confetti do not jump between frames.
  final Random _random = Random(7);
  late final List<(double, double, double, int)> _sparkles = [
    for (var i = 0; i < 9; i++)
      (_random.nextDouble() * 1.8 - 0.9, _random.nextDouble() * 1.0 - 0.6, 16 + _random.nextDouble() * 16, i % 4),
  ];
  late final List<(double, double, double, int)> _confetti = [
    for (var i = 0; i < 28; i++) (_random.nextDouble() * 2 - 1, _random.nextDouble(), _random.nextDouble() * pi, i % 5),
  ];

  static const List<String> _sparkleIcons = ['✨', '⭐', '🌟', '💛'];
  static const List<Color> _confettiColors = [
    Color(0xFFF6C445),
    Color(0xFFE8793A),
    Color(0xFF5FAFA6),
    Color(0xFFD9779F),
    Color(0xFF6E9BD8),
  ];

  @override
  void initState() {
    super.initState();
    _run();
  }

  /// Shows the current bubble for [time] (no voice: just the animation).
  Future<void> _hold(Duration time) => Future.delayed(time);

  Future<void> _run() async {
    await _pop.forward();
    if (!mounted || _left) return;

    setState(() => step = _Step.hello);
    await _hold(const Duration(milliseconds: 1800));
    if (!mounted || _left) return;

    setState(() => step = _Step.ready);
    await _hold(const Duration(milliseconds: 1800));
    if (!mounted || _left) return;

    setState(() => step = _Step.go);
    await _hold(const Duration(milliseconds: 1100));
    if (!mounted || _left) return;
    await _out.forward();
    _leave();
  }

  void _leave() {
    if (_left || !mounted) return;
    _left = true;
    Navigator.pushReplacement(context, widget.next());
  }

  @override
  void dispose() {
    _pop.dispose();
    _out.dispose();
    _loop.dispose();
    super.dispose();
  }

  String get _bubbleText => switch (step) {
    _Step.pop => '',
    _Step.hello => 'Hi ${widget.name}! 👋',
    _Step.ready => 'Ready to practice? 🎉',
    _Step.go => 'Let\'s go! 🚀',
  };

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dinoSize = min(220.0, size.width * 0.56);

    return Scaffold(
      backgroundColor: _cream,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _leave,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pop, _out, _loop]),
          builder: (context, _) {
            final popped = Curves.elasticOut.transform(_pop.value);
            final rise = Curves.easeOutBack.transform(_pop.value);
            final out = Curves.easeIn.transform(_out.value);

            return Stack(
              children: [
                // Sparkles around Dino.
                for (final (x, y, s, i) in _sparkles)
                  Align(
                    alignment: Alignment(x, y + 0.25),
                    child: Opacity(
                      opacity: (_pop.value * (0.5 + 0.5 * sin((_loop.value + i / 4) * 2 * pi)).abs() * (1 - out)).clamp(
                        0.0,
                        1.0,
                      ),
                      child: Text(_sparkleIcons[i], style: TextStyle(fontSize: s)),
                    ),
                  ),

                // Confetti falling from "Ready to practice?" on.
                if (step == _Step.ready || step == _Step.go)
                  for (final (x, y, angle, c) in _confetti)
                    Align(
                      alignment: Alignment(x, ((y + _loop.value) % 1.0) * 2.2 - 1.1),
                      child: Opacity(
                        opacity: 1 - out,
                        child: Transform.rotate(
                          angle: angle + _loop.value * 2 * pi,
                          child: Container(
                            width: 8,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _confettiColors[c],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),

                // Speech bubble.
                Align(
                  alignment: const Alignment(0, -0.42),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: step == _Step.pop
                        ? const SizedBox.shrink()
                        : Opacity(
                            key: ValueKey(step),
                            opacity: 1 - out,
                            child: _Bubble(text: _bubbleText),
                          ),
                  ),
                ),

                // Dino: jumps up, waves, then shrinks away.
                Align(
                  alignment: Alignment(0, 0.35 + (1 - rise) * 1.2),
                  child: Opacity(
                    opacity: (1 - out).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: (0.4 + 0.6 * popped) * (1 - 0.6 * out),
                      child: DinoMascot(color: widget.color, size: dinoSize),
                    ),
                  ),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 22 + MediaQuery.of(context).padding.bottom,
                  child: Text(
                    'Tap anywhere to skip',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _soft.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;

  const _Bubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 48),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF6C445), width: 3),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _HelloDinoScreenState._ink),
      ),
    );
  }
}
