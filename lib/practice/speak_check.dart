import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:talkiepal/services/hearing_service.dart';
import 'package:talkiepal/services/speech_score.dart';
import 'package:talkiepal/services/speech_service.dart';

/// What the child said and how close it was to the target.
class SpeechCheck {
  final int score;
  final List<String> heard;

  const SpeechCheck(this.score, this.heard);
}

/// Hold-to-talk for practice pages: the child holds SPEAK, talks, lets go,
/// and the page gets a [SpeechCheck] in [onSpeechChecked].
mixin HoldToSpeak<T extends StatefulWidget> on State<T> {
  /// True from pressing SPEAK until the score is ready.
  bool isListening = false;

  /// True once the phone is really listening (the button turns red).
  bool isMicReady = false;

  bool _isHolding = false;
  bool _heldLongEnough = false;
  Timer? _shortHold;
  Timer? _maxHold;

  /// A press shorter than this is a tap, not a hold.
  static const Duration _shortestHold = Duration(milliseconds: 450);

  /// Talking stops on its own after this long.
  static const Duration _longestHold = Duration(seconds: 8);

  /// The word or sentence the child should say.
  String get speakTarget;

  /// True when SPEAK should do nothing, e.g. while LISTEN is playing.
  bool get speakBlocked;

  /// Called with the result after the child lets go.
  void onSpeechChecked(SpeechCheck check);

  Future<void> onSpeakDown() async {
    if (speakBlocked || isListening) return;
    _isHolding = true;
    _heldLongEnough = false;
    _shortHold?.cancel();
    _shortHold = Timer(_shortestHold, () => _heldLongEnough = true);

    // The app's own voice must not be heard as the child's.
    await SpeechService.instance.stop();

    final hearing = HearingService.instance;
    if (!await hearing.isAvailable()) {
      _isHolding = false;
      _showTip('🎤 Please allow the microphone for TalkiePal so Dino can hear you.');
      return;
    }
    // Let go already (a quick tap): onSpeakUp has shown the tip.
    if (!mounted || !_isHolding) return;

    setState(() {
      isListening = true;
      isMicReady = false;
    });
    _maxHold?.cancel();
    _maxHold = Timer(_longestHold, onSpeakUp);

    final target = speakTarget.trim();
    await hearing.start(
      // One word or letter: the phone listens in a way that suits short answers.
      shortAnswer: !target.contains(' '),
      // Red (talk now) only while the microphone is really recording; back
      // to "get ready" while the phone starts listening again.
      onRecording: (recording) {
        if (!mounted) return;
        final ready = recording && _isHolding;
        if (ready && !isMicReady) HapticFeedback.mediumImpact();
        setState(() {
          isMicReady = ready;
        });
      },
    );
  }

  Future<void> onSpeakUp() async {
    if (!_isHolding) return;
    _isHolding = false;
    _maxHold?.cancel();
    _shortHold?.cancel();

    final hearing = HearingService.instance;
    final target = speakTarget;

    setState(() {
      isMicReady = false;
    });

    if (!_heldLongEnough) {
      await hearing.stop();
      if (!mounted) return;
      setState(() {
        isListening = false;
      });
      _showTip('👆 Hold the SPEAK button while you talk, then let go.');
      return;
    }

    final heard = await hearing.finish();
    if (!mounted || !isListening) return;
    setState(() {
      isListening = false;
    });
    onSpeechChecked(SpeechCheck(scoreSpeech(target, heard), heard));
  }

  /// Stops listening without a result, e.g. when moving to the next word.
  /// Call inside setState.
  void cancelSpeaking() {
    _isHolding = false;
    _maxHold?.cancel();
    _shortHold?.cancel();
    isListening = false;
    isMicReady = false;
    HearingService.instance.stop();
  }

  @override
  void dispose() {
    _maxHold?.cancel();
    _shortHold?.cancel();
    if (_isHolding || isListening) HearingService.instance.stop();
    super.dispose();
  }

  void _showTip(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: const Color(0xFFFFB347),
        duration: const Duration(seconds: 2),
      ));
  }
}
