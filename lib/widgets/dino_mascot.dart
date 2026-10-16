import 'dart:math';

import 'package:flutter/material.dart';

/// Cute dino mascot that bounces, waves and blinks.
/// [color] is the body colour, so each level can have its own dino.
class DinoMascot extends StatefulWidget {
  final Color color;
  final double size;

  const DinoMascot({
    super.key,
    required this.color,
    this.size = 120,
  });

  @override
  State<DinoMascot> createState() => _DinoMascotState();
}

class _DinoMascotState extends State<DinoMascot> with SingleTickerProviderStateMixin {
  // One loop = one bounce cycle. The dino blinks once every loop.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final phase = t * 2 * pi;
        final bounce = -0.05 * widget.size * sin(phase).abs();
        final armAngle = -0.4 - 0.5 * sin(phase * 2);
        final blink = (t > 0.42 && t < 0.48) ? 1.0 : 0.0;

        return Transform.translate(
          offset: Offset(0, bounce),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _DinoPainter(color: widget.color, armAngle: armAngle, blink: blink),
            ),
          ),
        );
      },
    );
  }
}

/// Draws the dino on a 120 x 120 grid, scaled to the widget size.
class _DinoPainter extends CustomPainter {
  final Color color;
  final double armAngle;
  final double blink; // 0 = eyes open, 1 = closed

  _DinoPainter({required this.color, required this.armAngle, required this.blink});

  static const Color _ink = Color(0xFF2B2B3A);
  static const Color _spike = Color(0xFFFFB74D);
  static const Color _spikeEdge = Color(0xFFF57C00);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120);

    final hsl = HSLColor.fromColor(color);
    final dark = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
    final light = hsl.withLightness((hsl.lightness + 0.28).clamp(0.0, 1.0)).toColor();

    final fill = Paint()..color = color;
    final outline = Paint()
      ..color = dark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Tail
    final tail = Path()
      ..moveTo(78, 80)
      ..quadraticBezierTo(108, 84, 114, 64)
      ..quadraticBezierTo(104, 98, 80, 98)
      ..close();
    canvas.drawPath(tail, fill);
    canvas.drawPath(tail, outline);

    // Spikes on the head (drawn first so the head covers their base)
    final spikeEdge = Paint()
      ..color = _spikeEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final p in const [Offset(43, 10), Offset(60, 3), Offset(77, 10)]) {
      final spike = Path()
        ..moveTo(p.dx - 8, p.dy + 16)
        ..quadraticBezierTo(p.dx, p.dy - 8, p.dx + 8, p.dy + 16)
        ..close();
      canvas.drawPath(spike, Paint()..color = _spike);
      canvas.drawPath(spike, spikeEdge);
    }

    // Feet
    for (final x in const [46.0, 74.0]) {
      final foot = Rect.fromCenter(center: Offset(x, 106), width: 22, height: 12);
      canvas.drawOval(foot, fill);
      canvas.drawOval(foot, outline);
    }

    // Body and belly
    final body = Rect.fromCenter(center: const Offset(60, 80), width: 58, height: 50);
    canvas.drawOval(body, fill);
    canvas.drawOval(body, outline);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 86), width: 34, height: 30),
      Paint()..color = light,
    );

    // Right arm (still)
    canvas.drawOval(Rect.fromCenter(center: const Offset(86, 80), width: 12, height: 18), fill);

    // Left arm (waving)
    canvas.save();
    canvas.translate(36, 76);
    canvas.rotate(armAngle);
    final arm = Rect.fromCenter(center: const Offset(-4, -8), width: 12, height: 20);
    canvas.drawOval(arm, fill);
    canvas.drawOval(arm, outline);
    canvas.restore();

    // Head
    canvas.drawCircle(const Offset(60, 42), 30, fill);
    canvas.drawCircle(const Offset(60, 42), 30, outline);

    // Eyes
    for (final x in const [49.0, 71.0]) {
      final eyeHeight = 16 * (1 - blink) + 2;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 40), width: 13, height: eyeHeight),
        Paint()..color = _ink,
      );
      if (blink < 0.5) {
        canvas.drawCircle(Offset(x + 2.5, 36), 3, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(x - 2, 43), 1.5, Paint()..color = Colors.white);
      }
    }

    // Blush
    final blush = Paint()..color = const Color(0x88FF7AA2);
    canvas.drawOval(Rect.fromCenter(center: const Offset(40, 53), width: 11, height: 6), blush);
    canvas.drawOval(Rect.fromCenter(center: const Offset(80, 53), width: 11, height: 6), blush);

    // Smile
    final mouth = Path()
      ..moveTo(53, 54)
      ..quadraticBezierTo(60, 62, 67, 54);
    canvas.drawPath(
      mouth,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DinoPainter old) =>
      old.armAngle != armAngle || old.blink != blink || old.color != color;
}
