import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

// Flame draws text itself, so it does not get the app's font from the theme.
const List<String> _emojiFallback = ['NotoColorEmoji'];

/// The Flame game for Voice Rocket: the rocket flies up while the child makes
/// a long, loud sound, and slowly falls back when they stop.
class RocketGame extends FlameGame {
  final String destination;
  final void Function() onStar;
  final void Function() onArrived;

  RocketGame({required this.destination, required this.onStar, required this.onArrived});

  // Where the stars are on the way up (0 = Earth, 1 = destination).
  static const List<double> _starStops = [0.25, 0.5, 0.75];

  // Share of the way flown each second at full voice, and fallen when quiet.
  static const double _climbSpeed = 0.16;
  static const double _fallSpeed = 0.035;

  bool isRunning = false;

  /// True while the child holds the button and is loud enough.
  bool isThrusting = false;

  /// How loud the child is (0 to 1), to fly faster when louder.
  double loudness = 0;

  /// How far the rocket has flown, from 0 (Earth) to 1 (destination).
  double progress = 0;

  /// Longest time in seconds the child kept the sound going.
  double longestSound = 0;
  double _currentSound = 0;

  double _untilNextPuff = 0;
  final Random _random = Random();

  late final TextComponent _rocket;
  late final TextComponent _goal;
  final List<TextComponent> _stars = [];

  @override
  Color backgroundColor() => const Color(0x00000000);

  TextComponent _emoji(String emoji, double size) {
    return TextComponent(
      text: emoji,
      anchor: Anchor.center,
      textRenderer: TextPaint(style: TextStyle(fontSize: size, fontFamilyFallback: _emojiFallback)),
    );
  }

  // Starts above the message bubble at the bottom of the screen.
  double get _bottomY => size.y - 130;
  double get _topY => 70;

  /// The rocket's path: up, swaying a little left and right.
  Vector2 _pointAt(double p) {
    final x = size.x / 2 + sin(p * pi * 3) * size.x * 0.22;
    return Vector2(x, _bottomY - p * (_bottomY - _topY));
  }

  @override
  Future<void> onLoad() async {
    _goal = _emoji(destination, 56)..position = Vector2(size.x / 2, 34);
    add(_goal);

    for (final stop in _starStops) {
      final star = _emoji('⭐', 34)..position = _pointAt(stop);
      _stars.add(star);
      add(star);
    }

    _rocket = _emoji('🚀', 60)
      ..angle = -pi / 4
      ..position = _pointAt(0)
      ..priority = 10;
    add(_rocket);
  }

  void start() {
    progress = 0;
    longestSound = 0;
    _currentSound = 0;
    isRunning = true;
  }

  void stop() {
    isRunning = false;
    isThrusting = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded || !isRunning) return;

    if (isThrusting) {
      progress += _climbSpeed * (0.5 + loudness) * dt;
      _currentSound += dt;
      longestSound = max(longestSound, _currentSound);
      _puffSmoke(dt);
    } else {
      progress -= _fallSpeed * dt;
      _currentSound = 0;
    }
    progress = progress.clamp(0.0, 1.0);
    _rocket.position = _pointAt(progress);

    // Collect the stars the rocket has passed.
    for (var i = 0; i < _starStops.length; i++) {
      final star = _stars[i];
      if (star.isMounted && progress >= _starStops[i]) {
        _collect(star);
      }
    }

    if (progress >= 1) {
      stop();
      onArrived();
    }
  }

  void _collect(TextComponent star) {
    star.removeFromParent();
    add(TextComponent(
      text: '+1 ⭐',
      anchor: Anchor.center,
      position: star.position.clone(),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontFamilyFallback: _emojiFallback,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Color(0xFFFFD54F),
        ),
      ),
      children: [
        MoveByEffect(Vector2(0, -60), EffectController(duration: 0.8)),
        RemoveEffect(delay: 0.8),
      ],
    ));
    onStar();
  }

  /// Little fire puffs behind the rocket while it flies.
  void _puffSmoke(double dt) {
    _untilNextPuff -= dt;
    if (_untilNextPuff > 0) return;
    _untilNextPuff = 0.05;

    add(ParticleSystemComponent(
      position: _rocket.position + Vector2(0, 30),
      particle: Particle.generate(
        count: 3,
        lifespan: 0.5,
        generator: (i) => AcceleratedParticle(
          speed: Vector2((_random.nextDouble() - 0.5) * 60, 80 + _random.nextDouble() * 60),
          child: CircleParticle(
            radius: 3 + _random.nextDouble() * 4,
            paint: Paint()..color = i.isEven ? const Color(0xFFFFA726) : const Color(0xFFFFEE58),
          ),
        ),
      ),
    ));
  }
}
