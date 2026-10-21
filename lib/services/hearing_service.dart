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

  /// Starts listening. [onRecording] is told true once the microphone is
  /// really recording (the child can talk) and false while the phone is
  /// starting again. [shortAnswer] is for one word or letter: the phone then
  /// uses its model for short phrases and waits a little longer for it.
  Future<void> start({void Function(bool isRecording)? onRecording, bool shortAnswer = false});

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
///
/// The plugin says "listening" straight away, even when the recogniser is
/// stuck and records nothing. Only sound levels from the microphone prove it
/// is really recording, so those are used to tell the child to talk, and a
/// listen that sends none is started again.
class PhoneHearingService implements HearingService {
  final SpeechToText _speech = SpeechToText();
  Future<bool>? _setUp;

  // True from start() until finish()/stop(): the child is holding the button.
  bool _wanted = false;
  int _restarts = 0;
  static const int _maxRestarts = 5;

  // The listen going on now, and whether it has really started.
  Completer<void>? _session;
  bool _hasStarted = false;
  bool _gotFinalWords = false;
  List<String> _heard = [];

  // Sound levels prove the microphone is really recording.
  Completer<void>? _recording;
  DateTime? _lastSound;
  double _maxLevel = -100;
  Timer? _watchdog;
  bool _isRecording = false;
  void Function(bool)? _onRecording;
  bool _shortAnswer = false;

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
    // Wake up anyone still waiting for the microphone.
    final recording = _recording;
    if (recording != null && !recording.isCompleted && !_wanted) recording.complete();
  }

  @override
  Future<void> start({void Function(bool isRecording)? onRecording, bool shortAnswer = false}) async {
    if (!await isAvailable()) return;
    _onRecording = onRecording;
    _shortAnswer = shortAnswer;

    // Make sure the last listen is fully finished first.
    if (_speech.isListening) await _speech.cancel();

    _wanted = true;
    _restarts = 0;
    _heard = [];
    _maxLevel = -100;

    for (var attempt = 0; attempt < 3 && _wanted; attempt++) {
      await _beginListen(keepHeard: false);
      // Really recording once the microphone sends sound levels.
      await _recording!.future.timeout(const Duration(milliseconds: 1200), onTimeout: () {});
      if (_recording!.isCompleted) break;
      debugPrint('[STT] no sound from the microphone, starting again');
      await _speech.cancel();
      await Future.delayed(const Duration(milliseconds: 400));
    }

    if (_wanted) _startWatchdog();
  }

  void _setRecording(bool value) {
    if (_isRecording == value) return;
    _isRecording = value;
    if (_wanted || !value) _onRecording?.call(value);
  }

  /// While the button is held, start again if the microphone goes quiet
  /// (no sound levels at all, not even from a silent room).
  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_wanted) {
        _watchdog?.cancel();
        return;
      }
      final last = _lastSound;
      if (last != null && DateTime.now().difference(last) > const Duration(milliseconds: 1500)) {
        _lastSound = DateTime.now();
        debugPrint('[STT] microphone went quiet');
        _listenEnded();
      }
    });
  }

  void _onSound(double level) {
    _lastSound = DateTime.now();
    if (level > _maxLevel) _maxLevel = level;
    if (_wanted) _setRecording(true);
    final recording = _recording;
    if (recording != null && !recording.isCompleted) recording.complete();
  }

  Future<void> _beginListen({required bool keepHeard}) async {
    if (!keepHeard) _heard = [];
    _hasStarted = false;
    _gotFinalWords = false;
    _setRecording(false);
    _recording = Completer<void>();
    // Counts from now, so a listen that never sends any sound is noticed too.
    _lastSound = DateTime.now();
    _session = Completer<void>();

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
        onSoundLevelChange: _onSound,
        listenOptions: SpeechListenOptions(
          // The child decides when to stop by letting go of the button.
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 6),
          localeId: 'en_US',
          partialResults: true,
          cancelOnError: true,
          // Android's "web search" model is made for short phrases and hears
          // single words and letters much better than the dictation model.
          listenMode: _shortAnswer ? ListenMode.search : ListenMode.dictation,
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

    // A single word is short: give the phone up to a second more to
    // recognise it before stopping, instead of cutting it off.
    if (_shortAnswer) {
      for (var i = 0; i < 10 && _heard.isEmpty && _session != null && !_session!.isCompleted; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    _wanted = false;
    _watchdog?.cancel();
    _setRecording(false);
    if (_speech.isListening) await _speech.stop();

    // Wait for the phone's final answer, but not for ever.
    final session = _session;
    if (session != null) {
      await session.future.timeout(const Duration(seconds: 3), onTimeout: () {});
    }
    _session = null;
    debugPrint('[STT] heard $_heard (restarted $_restarts times, loudest ${_maxLevel.toStringAsFixed(1)})');
    return _heard;
  }

  @override
  Future<void> stop() async {
    _wanted = false;
    _watchdog?.cancel();
    _setRecording(false);
    _completeSession();
    _session = null;
    if (_speech.isListening) await _speech.cancel();
  }
}
