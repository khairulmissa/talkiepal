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
///
/// Android's recogniser sometimes stops on its own while the child is still
/// holding the button: a late "busy" or "client" error left over from an
/// earlier listen, or a short silence. While the button is held it is
/// simply started again, so whatever the child says before letting go is
/// still heard.
class PhoneHearingService implements HearingService {
  final SpeechToText _speech = SpeechToText();
  Future<bool>? _setUp;

  // True from start() until finish()/stop(): the child is holding the button.
  bool _wanted = false;
  int _restarts = 0;
  static const int _maxRestarts = 5;

  // The listen going on now, and whether it has really started.
  Completer<void>? _session;
  Completer<void>? _ready;
  bool _hasStarted = false;
  bool _gotFinalWords = false;
  List<String> _heard = [];

  // Errors that will not get better by trying again.
  static const Set<String> _hardErrors = {
    'error_permission',
    'error_insufficient_permissions',
    'error_language_not_supported',
    'error_language_unavailable',
  };

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
    debugPrint('[STT] status: $status (holding: $_wanted)');
    if (status == SpeechToText.listeningStatus) {
      _markStarted();
    } else if ((status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) && _hasStarted) {
      _listenEnded();
    }
  }

  void _onError(String message) {
    debugPrint('[STT] error: $message (holding: $_wanted)');
    if (_hardErrors.contains(message)) _restarts = _maxRestarts;
    _listenEnded();
  }

  void _markStarted() {
    _hasStarted = true;
    final ready = _ready;
    if (ready != null && !ready.isCompleted) ready.complete();
  }

  /// The phone stopped listening. If the child is still holding the button,
  /// listen again; otherwise this listen is over.
  void _listenEnded() {
    if (_wanted && !_gotFinalWords && _restarts < _maxRestarts) {
      _restarts++;
      debugPrint('[STT] stopped early, listening again ($_restarts)');
      final restartFor = _session;
      Future.delayed(const Duration(milliseconds: 300), () async {
        if (!_wanted || _session != restartFor) return;
        if (_speech.isListening) await _speech.cancel();
        await _beginListen(keepHeard: true);
      });
      return;
    }
    _completeSession();
  }

  void _completeSession() {
    final session = _session;
    if (session != null && !session.isCompleted) session.complete();
    // Wake up anyone still waiting for "ready".
    final ready = _ready;
    if (ready != null && !ready.isCompleted) ready.complete();
  }

  @override
  Future<void> start({void Function()? onReady}) async {
    if (!await isAvailable()) return;

    // Make sure the last listen is fully finished first.
    if (_speech.isListening) await _speech.cancel();

    _wanted = true;
    _restarts = 0;
    _heard = [];
    await _beginListen(keepHeard: false);

    // Tell the child to talk once the phone is really listening (or after
    // a moment, so the button never stays on "get ready").
    await _ready!.future.timeout(const Duration(milliseconds: 1500), onTimeout: () {});
    if (_wanted) onReady?.call();
  }

  Future<void> _beginListen({required bool keepHeard}) async {
    if (!keepHeard) _heard = [];
    _hasStarted = false;
    _gotFinalWords = false;
    _session = Completer<void>();
    _ready ??= Completer<void>();
    if (_ready!.isCompleted && !keepHeard) _ready = Completer<void>();

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
          if (result.finalResult && words.isNotEmpty) {
            _gotFinalWords = true;
            _completeSession();
          }
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
      _listenEnded();
    }
  }

  @override
  Future<List<String>> finish() async {
    if (_session == null) return const [];

    // Keep listening a little after the button is let go.
    await Future.delayed(const Duration(milliseconds: 700));
    _wanted = false;
    if (_speech.isListening) await _speech.stop();

    // Wait for the phone's final answer, but not for ever.
    final session = _session;
    if (session != null) {
      await session.future.timeout(const Duration(seconds: 3), onTimeout: () {});
    }
    _session = null;
    _ready = null;
    debugPrint('[STT] heard $_heard (restarted $_restarts times)');
    return _heard;
  }

  @override
  Future<void> stop() async {
    _wanted = false;
    _completeSession();
    _session = null;
    _ready = null;
    if (_speech.isListening) await _speech.cancel();
  }
}
