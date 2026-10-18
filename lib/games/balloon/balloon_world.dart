import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// The Flame game for Pop the Balloon: balloons with words float up and the
/// child pops the ones with the target sound.
class BalloonGame extends FlameGame {
  final String sound;
  final List<String> targetWords;
  final List<String> otherWords;
  final void Function(String word) onCorrect;
  final void Function(String word) onWrong;

  BalloonGame({
    required this.sound,
    required this.targetWords,
    required this.otherWords,
    required this.onCorrect,
    required this.onWrong,
  });

  static const List<Color> _colors = [
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFFFFA726),
    Color(0xFF26A69A),
    Color(0xFFEC407A),
    Color(0xFF5C6BC0),
  ];

  // Seconds between new balloons.
  static const double _spawnEvery = 1.2;

  final Random _random = Random();

  bool isRunning = false;
  double _untilNextBalloon = 0;
  int _lastLane = -1;
  int _colorIndex = 0;

  // Keeps the same word from coming up again and again.
  final List<String> _recent = [];

  @override
  Color backgroundColor() => const Color(0x00000000);

  /// Starts a new round: clears the sky and sends up balloons.
  void start() {
    children.whereType<Balloon>().toList().forEach((b) => b.removeFromParent());
    _untilNextBalloon = 0;
    isRunning = true;
  }

  void stop() {
    isRunning = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isRunning || size.x == 0) return;

    _untilNextBalloon -= dt;
    if (_untilNextBalloon <= 0) {
      _untilNextBalloon = _spawnEvery;
      _spawnBalloon();
    }
  }

  void _spawnBalloon() {
    final isTarget = _random.nextBool();
    final word = _pickWord(isTarget ? targetWords : otherWords);

    // Three lanes, never the same lane twice in a row, so balloons do not overlap.
    const lanes = 3;
    var lane = _random.nextInt(lanes);
    if (lane == _lastLane) lane = (lane + 1 + _random.nextInt(lanes - 1)) % lanes;
    _lastLane = lane;

    final laneWidth = size.x / lanes;
    final half = Balloon.balloonSize.x / 2;
    final wobble = (_random.nextDouble() - 0.5) * 20;
    // Keep the whole balloon on screen.
    final x = (laneWidth * (lane + 0.5) + wobble).clamp(half + 2, size.x - half - 2);

    add(Balloon(
      word: word,
      sound: sound,
      isTarget: isTarget,
      color: _colors[_colorIndex++ % _colors.length],
      // Almost the same speed, so balloons do not catch up with each other.
      speed: 82 + _random.nextDouble() * 8,
      position: Vector2(x, size.y + Balloon.balloonSize.y),
    ));
  }

  String _pickWord(List<String> words) {
    final fresh = words.where((w) => !_recent.contains(w)).toList();
    final pool = fresh.isEmpty ? words : fresh;
    final word = pool[_random.nextInt(pool.length)];

    _recent.add(word);
    if (_recent.length > 4) _recent.removeAt(0);
    return word;
  }
}

// Flame draws text itself, so it does not get the app's font from the theme.
const String _fontFamily = 'Roboto';
const List<String> _emojiFallback = ['NotoColorEmoji'];

/// One balloon with a word.
class Balloon extends PositionComponent with TapCallbacks, HasGameReference<BalloonGame> {
  static final Vector2 balloonSize = Vector2(96, 112);
  static const double _stringLength = 40;

  final String word;
  final String sound;
  final bool isTarget;
  final Color color;
  final double speed;

  bool _isWrong = false;
  late final TextPainter _label = _buildLabel();

  Balloon({
    required this.word,
    required this.sound,
    required this.isTarget,
    required this.color,
    required this.speed,
    required super.position,
  }) : super(
          size: Vector2(balloonSize.x, balloonSize.y + _stringLength),
          anchor: Anchor.topCenter,
        );

  TextPainter _buildLabel() {
    // Smaller letters for long words, so they fit inside the balloon.
    final fontSize = min(20.0, (balloonSize.x - 14) / (word.length * 0.68));

    // All letters are white: colouring the sound would give the answer away.
    return TextPainter(
      text: TextSpan(
        text: word,
        style: TextStyle(
          fontFamily: _fontFamily,
          fontFamilyFallback: _emojiFallback,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= speed * dt;

    // Gone off the top of the screen.
    if (position.y + size.y < 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final w = balloonSize.x;
    final h = balloonSize.y;
    final body = Rect.fromLTWH(0, 0, w, h);
    final fill = _isWrong ? const Color(0xFFBDBDBD) : color;

    // String
    canvas.drawLine(
      Offset(w / 2, h),
      Offset(w / 2, h + _stringLength),
      Paint()
        ..color = const Color(0xFF9E9E9E)
        ..strokeWidth = 2,
    );
    // Knot
    canvas.drawPath(
      Path()
        ..moveTo(w / 2 - 6, h + 6)
        ..lineTo(w / 2 + 6, h + 6)
        ..lineTo(w / 2, h - 2)
        ..close(),
      Paint()..color = fill,
    );
    // Shadow, body, white border and shine
    canvas.drawOval(body.shift(const Offset(0, 5)), Paint()..color = fill.withValues(alpha: 0.35));
    canvas.drawOval(body, Paint()..color = fill);
    canvas.drawOval(
      body.deflate(1.5),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawOval(
      Rect.fromLTWH(w * 0.2, h * 0.12, w * 0.18, h * 0.22),
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );

    _label.paint(canvas, Offset((w - _label.width) / 2, (h - _label.height) / 2));
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    // Only the balloon itself, not the string, can be tapped.
    return point.x >= 0 && point.x <= balloonSize.x && point.y >= 0 && point.y <= balloonSize.y;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_isWrong) return;

    if (isTarget) {
      _pop();
      game.onCorrect(word);
    } else {
      _isWrong = true;
      add(SequenceEffect([
        MoveByEffect(Vector2(-8, 0), EffectController(duration: 0.05)),
        MoveByEffect(Vector2(16, 0), EffectController(duration: 0.1, repeatCount: 2, alternate: true)),
        MoveByEffect(Vector2(-8, 0), EffectController(duration: 0.05)),
      ]));
      game.onWrong(word);
    }
  }

  void _pop() {
    final center = position + Vector2(0, balloonSize.y / 2);
    final random = Random();

    // Burst of little pieces in the balloon's colour
    game.add(ParticleSystemComponent(
      position: center,
      particle: Particle.generate(
        count: 18,
        lifespan: 0.6,
        generator: (i) {
          final angle = i / 18 * 2 * pi;
          final speed = 120 + random.nextDouble() * 80;
          return AcceleratedParticle(
            speed: Vector2(cos(angle), sin(angle)) * speed,
            acceleration: Vector2(0, 300),
            child: CircleParticle(radius: 4 + random.nextDouble() * 3, paint: Paint()..color = color),
          );
        },
      ),
    ));

    // "+1 ⭐" floating up
    game.add(TextComponent(
      text: '💥 +1 ⭐',
      anchor: Anchor.center,
      position: center,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: _fontFamily,
          fontFamilyFallback: _emojiFallback,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Color(0xFFF57C00),
        ),
      ),
      children: [
        MoveByEffect(Vector2(0, -70), EffectController(duration: 0.8)),
        RemoveEffect(delay: 0.8),
      ],
    ));

    removeFromParent();
  }
}
