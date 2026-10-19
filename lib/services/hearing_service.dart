import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Listens to the child and turns what they said into text (speech-to-text).
/// The child holds the SPEAK button: [start] when they press, [finish] when
/// they let go. Every page uses [HearingService.instance], so tests can swap
/// in a fake.
abstract class HearingService {
  static HearingService instance = PhoneHearingService();

  /// Sets up the phone's speech recognition and asks for the microphone.
  /// False when it is not allowed or the phone has none.
  Future<bool> isAvailable();

  /// Starts listening. [onReady] is called once the phone is really
  /// listening, so the child knows they can talk.
  Future<void> start({void Function()? onReady});

  /// Stops listening and returns what was heard, best guess first.
  /// Keeps listening a moment longer first, so the last sound is not cut off.
  /// Empty when nothing was heard.
  Future<List<String>> finish();

  /// Stops straight away and throws away what was heard.
  Future<void> stop();
}

/// Uses the phone's own speech recognition (Google on Android). Free.
class PhoneHearingService implements HearingService {
  final SpeechToText _speech = SpeechToText();
  Future<bool>? _setUp;

  // The listen that is going on now. Events from an earlier listen that
  // arrive late must not end it.
  Completer<void>? _session;
  Completer<void>? _ready;
  bool _hasStarted = false;
  List<String> _heard = [];

  @override
  Future<bool> isAvailable() {
    return _setUp ??= _speech
        .initialize(onStatus: _onStatus, onError: (e) => _onError(e.errorMsg))
        .catchError((_) => false)
        .then((ok) {
          // Try again next time if it failed (e.g. permission was refused).
          if (!ok) _setUp = null;
          return ok;
        });
  }

  void _onStatus(String status) {
    debugPrint('[STT] status: $status');
    if (status == SpeechToText.listeningStatus) {
      _markStarted();
    } else if ((status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) && _hasStarted) {
      // Only end the listen once it has really started.
      _endSession();
    }
  }

  void _onError(String message) {
    debugPrint('[STT] error: $message');
    _endSession();
  }

  void _markStarted() {
    _hasStarted = true;
    final ready = _ready;
    if (ready != null && !ready.isCompleted) ready.complete();
  }

  void _endSession() {
    final session = _session;
    if (session != null && !session.isCompleted) session.complete();
    // Wake up anyone still waiting for "ready".
    final ready = _ready;
    if (ready != null && !ready.isCompleted) ready.complete();
  }

  @override
  Future<void> start({void Function()? onReady}) async {
    if (!await isAvailable()) return;

    // Make sure the last listen is fully finished first; the phone says
    // "busy" if a new one starts too soon.
    if (_speech.isListening) await _speech.cancel();

    for (var attempt = 0; attempt < 2; attempt++) {
      await _beginListen();
      await _ready!.future.timeout(const Duration(milliseconds: 1500), onTimeout: () {});
      if (_hasStarted) {
        onReady?.call();
        return;
      }
      // The phone was not ready yet; try once more.
      debugPrint('[STT] did not start, trying again');
      await _speech.cancel();
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  Future<void> _beginListen() async {
    _heard = [];
    _hasStarted = false;
    _session = Completer<void>();
    _ready = Completer<void>();

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          // Hearing words means it has started, even if no status came.
          _markStarted();
          final words = [
            result.recognizedWords,
            for (final alt in result.alternates) alt.recognizedWords,
          ].where((w) => w.trim().isNotEmpty).toSet().toList();
          if (words.isNotEmpty) _heard = words;
          if (result.finalResult) _endSession();
        },
        listenOptions: SpeechListenOptions(
          // The child decides when to stop by letting go of the button.
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 6),
          localeId: 'en_US',
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        ),
      );
    } catch (e) {
      debugPrint('[STT] could not start: $e');
      _endSession();
    }
  }

  @override
  Future<List<String>> finish() async {
    final session = _session;
    if (session == null) return const [];

    // Keep listening a little after the button is let go.
    await Future.delayed(const Duration(milliseconds: 700));
    if (_speech.isListening) await _speech.stop();

    // Wait for the phone's final answer, but not for ever.
    await session.future.timeout(const Duration(seconds: 3), onTimeout: () {});
    _session = null;
    debugPrint('[STT] heard $_heard');
    return _heard;
  }

  @override
  Future<void> stop() async {
    _session = null;
    _endSession();
    await _speech.cancel();
  }
}
