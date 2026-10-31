import 'package:flutter/material.dart';
import 'package:talkiepal/widgets/dino_mascot.dart';
import 'package:talkiepal/widgets/kids_bottom_nav.dart';

/// Colours for one level, used by every practice page.
class PracticeLook {
  final String letter;
  final String name;
  final Color color;
  final Color darkColor;
  final Color lightColor;
  final Color dinoColor;

  const PracticeLook(this.letter, this.name, this.color, this.darkColor, this.lightColor, this.dinoColor);

  static const beginner = PracticeLook(
      'A', 'Beginner', Color(0xFF4CAF50), Color(0xFF2E7D32), Color(0xFFE8F5E9), Color(0xFF8BD17C));
  static const preIntermediate = PracticeLook(
      'B', 'Pre Intermediate', Color(0xFF42A5F5), Color(0xFF1565C0), Color(0xFFE3F2FD), Color(0xFF7EC3F2));
  static const intermediate = PracticeLook(
      'C', 'Intermediate', Color(0xFFFF8A3D), Color(0xFFD84315), Color(0xFFFFF0E3), Color(0xFFFFA569));
  static const specialSound = PracticeLook(
      'D', 'Special Sound', Color(0xFFD81B8C), Color(0xFF9C1361), Color(0xFFFCE4F1), Color(0xFFE77BC3));

  static PracticeLook forLevel(String level) {
    switch (level) {
      case 'pre_intermediate':
        return preIntermediate;
      case 'intermediate':
        return intermediate;
      case 'special_words':
      case 'special_sentences':
        return specialSound;
      default:
        return beginner;
    }
  }
}

/// Colours of the LISTEN and SPEAK buttons, also used to light up words.
class PracticeColors {
  static const Color listen = Color(0xFF29B6F6);
  static const Color listenDark = Color(0xFF0277BD);
  static const Color speak = Color(0xFFEC407A);
  static const Color speakDark = Color(0xFFC2185B);
  static const Color ink = Color(0xFF4A3B57);
  static const Color soft = Color(0xFF7A6A85);
}

/// Shared layout for every practice page: header, progress, dino tip,
/// the page's own content and the bottom menu.
class PracticeScaffold extends StatelessWidget {
  final PracticeLook look;
  final String title;
  final int current;
  final int total;
  final String dinoTip;
  final bool isLoading;
  final String loadingText;
  final VoidCallback? onRefresh;
  final void Function(KidsTab tab) onNavTap;
  final List<Widget> children;

  const PracticeScaffold({
    super.key,
    required this.look,
    required this.title,
    required this.current,
    required this.total,
    required this.dinoTip,
    required this.onNavTap,
    required this.children,
    this.isLoading = false,
    this.loadingText = 'Creating new practice for you... ✨',
    this.onRefresh,
  });

  static const Color _cream = Color(0xFFFFF8EC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: _buildBlob(170, look.lightColor)),
          Positioned(top: 520, left: -80, child: _buildBlob(160, const Color(0xFFFFE0F0))),
          Positioned(bottom: 140, right: -60, child: _buildBlob(170, const Color(0xFFE3EEFF))),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Column(
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 14),
                        if (!isLoading && total > 0) ...[
                          _buildProgress(),
                          const SizedBox(height: 14),
                        ],
                        _buildDinoTip(),
                        const SizedBox(height: 16),
                        if (isLoading) _buildLoadingCard() else ...children,
                      ],
                    ),
                  ),
                ),
                KidsBottomNav(onTap: onNavTap),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.4 : 1,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: look.color, width: 2.5),
            boxShadow: [BoxShadow(color: look.darkColor, offset: const Offset(0, 3))],
          ),
          child: Icon(icon, color: look.darkColor),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildCircleButton(Icons.arrow_back_rounded, () => Navigator.pop(context)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: look.darkColor),
              ),
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: look.color, shape: BoxShape.circle),
                    child: Text(
                      look.letter,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    look.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: PracticeColors.soft),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (onRefresh != null) _buildCircleButton(Icons.refresh_rounded, isLoading ? null : onRefresh),
      ],
    );
  }

  /// Dots for short practices, one bar for long ones (e.g. A to Z).
  Widget _buildProgress() {
    final Widget track;

    if (total > 10) {
      track = Container(
        height: 12,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(color: const Color(0xFFEDE4F2), borderRadius: BorderRadius.circular(8)),
        child: FractionallySizedBox(
          widthFactor: (current / total).clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(color: look.color, borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    } else {
      track = Row(
        children: [
          for (var i = 0; i < total; i++)
            Expanded(
              child: Container(
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i < current ? look.color : const Color(0xFFEDE4F2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: track),
        const SizedBox(width: 10),
        Text(
          '$current / $total',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: look.darkColor),
        ),
      ],
    );
  }

  Widget _buildDinoTip() {
    return Row(
      children: [
        Container(
          width: 74,
          height: 74,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: look.lightColor, width: 3),
          ),
          child: DinoMascot(color: look.dinoColor, size: 64),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0xFFE6DCEB), offset: Offset(0, 4))],
            ),
            child: Text(
              dinoTip,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: PracticeColors.ink),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return PracticeCard(
      look: look,
      child: Column(
        children: [
          CircularProgressIndicator(color: look.color),
          const SizedBox(height: 16),
          Text(
            loadingText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: PracticeColors.ink),
          ),
        ],
      ),
    );
  }
}

/// White card with a thick border in the level colour.
class PracticeCard extends StatelessWidget {
  final PracticeLook look;
  final Widget child;

  const PracticeCard({super.key, required this.look, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: look.color, width: 4),
        boxShadow: [BoxShadow(color: look.darkColor, offset: const Offset(0, 7))],
      ),
      child: child,
    );
  }
}

/// Big 3D button, e.g. LISTEN or SPEAK.
class ChunkyButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final Color darkColor;
  final VoidCallback? onTap;
  final bool busy;
  final bool small;

  const ChunkyButton({
    super.key,
    required this.emoji,
    required this.label,
    required this.color,
    required this.darkColor,
    required this.onTap,
    this.busy = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: busy ? 0.7 : 1,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: small ? 12 : 16, horizontal: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: darkColor, offset: const Offset(0, 6))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: TextStyle(fontSize: small ? 20 : 24)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    busy ? '...' : label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: small ? 16 : 19,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// LISTEN and SPEAK buttons side by side.
class ListenSpeakButtons extends StatelessWidget {
  final VoidCallback onListen;
  final VoidCallback onSpeakDown;
  final VoidCallback onSpeakUp;
  final bool isPlaying;
  final bool isListening;
  final bool isMicReady;

  const ListenSpeakButtons({
    super.key,
    required this.onListen,
    required this.onSpeakDown,
    required this.onSpeakUp,
    required this.isPlaying,
    required this.isListening,
    required this.isMicReady,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ChunkyButton(
            emoji: '🔊',
            label: 'LISTEN',
            color: PracticeColors.listen,
            darkColor: PracticeColors.listenDark,
            busy: isPlaying,
            onTap: onListen,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: HoldToSpeakButton(
            onDown: onSpeakDown,
            onUp: onSpeakUp,
            isListening: isListening,
            isMicReady: isMicReady,
          ),
        ),
      ],
    );
  }
}

/// Button the child holds while talking.
/// HOLD & SPEAK → GET READY... (phone starting) → 🔴 LISTENING... (talk now).
class HoldToSpeakButton extends StatefulWidget {
  final VoidCallback onDown;
  final VoidCallback onUp;
  final bool isListening;
  final bool isMicReady;

  const HoldToSpeakButton({
    super.key,
    required this.onDown,
    required this.onUp,
    required this.isListening,
    required this.isMicReady,
  });

  @override
  State<HoldToSpeakButton> createState() => _HoldToSpeakButtonState();
}

class _HoldToSpeakButtonState extends State<HoldToSpeakButton> {
  static const Color _live = Color(0xFFE53935);
  static const Color _liveDark = Color(0xFFB71C1C);

  // Only the first finger counts, so a second finger or a palm touching
  // the button cannot stop the recording early.
  int? _pointer;

  void _down(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    widget.onDown();
  }

  void _up(PointerEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    widget.onUp();
  }

  @override
  Widget build(BuildContext context) {
    final isMicReady = widget.isMicReady;
    final isListening = widget.isListening;

    final String emoji;
    final String label;
    if (isMicReady) {
      emoji = '🔴';
      label = 'LISTENING...';
    } else if (isListening) {
      emoji = '⏳';
      label = 'GET READY...';
    } else {
      emoji = '🎤';
      label = 'HOLD & SPEAK';
    }

    final color = isMicReady ? _live : PracticeColors.speak;
    final dark = isMicReady ? _liveDark : PracticeColors.speakDark;

    return Semantics(
      button: true,
      label: label,
      child: Listener(
        onPointerDown: _down,
        onPointerUp: _up,
        onPointerCancel: _up,
        child: AnimatedScale(
          scale: isMicReady ? 1.06 : 1,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white, width: isMicReady ? 5 : 3),
              boxShadow: [BoxShadow(color: dark, offset: Offset(0, isListening ? 2 : 6))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One word that can light up. Letters of [target] are coloured.
class WordChip extends StatelessWidget {
  final String text;
  final bool isLit;
  final Color litColor;
  final String? target;
  final double size;

  const WordChip({
    super.key,
    required this.text,
    this.isLit = false,
    this.litColor = PracticeColors.listen,
    this.target,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isLit ? Colors.white : PracticeColors.ink;
    final targetColor = isLit ? const Color(0xFFFFF59D) : const Color(0xFFD81B8C);
    final spans = <TextSpan>[];

    if (target != null && target!.isNotEmpty && text.contains(target!)) {
      final parts = text.split(target!);
      for (var i = 0; i < parts.length; i++) {
        if (parts[i].isNotEmpty) {
          spans.add(TextSpan(text: parts[i], style: TextStyle(color: baseColor)));
        }
        if (i < parts.length - 1) {
          spans.add(TextSpan(text: target, style: TextStyle(color: targetColor)));
        }
      }
    } else {
      spans.add(TextSpan(text: text, style: TextStyle(color: baseColor)));
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isLit ? litColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text.rich(
        TextSpan(children: spans),
        style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }
}

/// Big emoji in a soft circle. With [onTap], tapping it plays the word like LISTEN.
class BigEmoji extends StatelessWidget {
  final String emoji;
  final Color background;
  final VoidCallback? onTap;

  const BigEmoji({super.key, required this.emoji, required this.background, this.onTap});

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: 140,
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(emoji, style: const TextStyle(fontSize: 80)),
    );
    return onTap == null ? circle : TapToListen(onTap: onTap!, child: circle);
  }
}

/// Turns a practice picture into a second LISTEN button, since children
/// often tap the picture. The page's LISTEN handler decides whether to play.
class TapToListen extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const TapToListen({super.key, required this.child, required this.onTap});

  @override
  State<TapToListen> createState() => _TapToListenState();
}

class _TapToListenState extends State<TapToListen> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Listen',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 120),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              widget.child,
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: PracticeColors.listen, width: 2.5),
                    boxShadow: const [BoxShadow(color: PracticeColors.listenDark, offset: Offset(0, 2))],
                  ),
                  child: const Text('🔊', style: TextStyle(fontSize: 17)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}