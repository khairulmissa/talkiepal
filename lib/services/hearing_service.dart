import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Speech-to-text driven by a press-and-hold SPEAK button: [start] on press,
/// [finish] on release.
///
/// Pages go through [HearingService.instance] so tests can swap in a fake.
abstract class HearingService {
  static HearingService instance = PhoneHearingService();

  /// Initialises recognition and requests microphone permission.
  /// Returns false when unavailable or permission is denied.
  Future<bool> isAvailable();

  /// Starts listening.
  ///
  /// [onRecording] is called with true once the microphone is actually
  /// capturing audio and false while recognition restarts. Set [shortAnswer]
  /// for single words or letters to use the short-phrase model.
  Future<void> start({void Function(bool isRecording)? onRecording, bool shortAnswer = false});

  /// Stops listening and returns the recognised alternatives, best first.
  /// Returns an empty list when nothing was heard.
  Future<List<String>> finish();

  /// Stops immediately and discards anything heard.
  Future<void> stop();
}

/// On-device speech recognition (Google on Android).
///
/// Android's recogniser can stop on its own while the button is still held
/// (late "busy"/"client" errors, short silences), so it is restarted until
/// the child lets go.
///
/// The plugin reports "listening" immediately even when the recogniser is
/// stuck, so only incoming sound levels are trusted as proof that the
/// microphone is recording.
class PhoneHearingService implements HearingService {
  static const int _maxRestarts = 5;
  static const int _maxStartAttempts = 3;
  static const double _silentLevel = -100;
  static const String _localeId = 'en_US';

  static const Duration _restartDelay = Duration(milliseconds: 300);
  static const Duration _firstSoundTimeout = Duration(milliseconds: 1200);
  static const Duration _retryDelay = Duration(milliseconds: 400);
  static const Duration _watchdogInterval = Duration(milliseconds: 500);
  static const Duration _quietLimit = Duration(milliseconds: 1500);
  static const Duration _releaseTail = Duration(milliseconds: 700);
  static const Duration _shortAnswerPoll = Duration(milliseconds: 100);
  static const int _shortAnswerPolls = 10;
  static const Duration _finalResultTimeout = Duration(seconds: 3);

  /// Errors that retrying will not fix.
  static const Set<String> _hardErrors = {
    'error_permission',
    'error_insufficient_permissions',
    'error_language_not_supported',
    'error_language_unavailable',
  };

  final SpeechToText _speech = SpeechToText();
  Future<bool>? _setUp;

  /// True while the button is held (from [start] until [finish]/[stop]).
  bool _wanted = false;
  int _restarts = 0;

  Completer<void>? _session;
  bool _hasStarted = false;
  bool _gotFinalWords = false;
  List<String> _heard = [];

  Completer<void>? _recording;
  DateTime? _lastSound;
  double _maxLevel = _silentLevel;
  Timer? _watchdog;
  bool _isRecording = false;
  void Function(bool)? _onRecording;
  bool _shortAnswer = false;

  @override
  Future<bool> isAvailable() {
    return _setUp ??= _speech
        .initialize(onStatus: _onStatus, onError: (e) => _onError(e.errorMsg))
        .catchError((_) => false)
        .then((ok) {
          // Allow a retry later, e.g. after permission is granted.
          if (!ok) _setUp = null;
          return ok;
        });
  }

  void _onStatus(String status) {
    debugPrint('[STT] status: $status (holding: $_wanted)');
    if (status == SpeechToText.listeningStatus) {
      _hasStarted = true;
    } else if ((status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) && _hasStarted) {
      _listenEnded();
    }
  }

  void _onError(String message) {
    debugPrint('[STT] error: $message (holding: $_wanted)');
    if (_hardErrors.contains(message)) _restarts = _maxRestarts;
    _listenEnded();
  }

  /// Restarts listening while the button is held, otherwise ends the session.
  void _listenEnded() {
    if (_wanted && !_gotFinalWords && _restarts < _maxRestarts) {
      _restarts++;
      debugPrint('[STT] stopped early, listening again ($_restarts)');
      final restartFor = _session;
      Future.delayed(_restartDelay, () async {
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

    final recording = _recording;
    if (recording != null && !recording.isCompleted && !_wanted) recording.complete();
  }

  @override
  Future<void> start({void Function(bool isRecording)? onRecording, bool shortAnswer = false}) async {
    if (!await isAvailable()) return;
    _onRecording = onRecording;
    _shortAnswer = shortAnswer;

    if (_speech.isListening) await _speech.cancel();

    _wanted = true;
    _restarts = 0;
    _heard = [];
    _maxLevel = _silentLevel;

    for (var attempt = 0; attempt < _maxStartAttempts && _wanted; attempt++) {
      await _beginListen(keepHeard: false);
      await _recording!.future.timeout(_firstSoundTimeout, onTimeout: () {});
      if (_recording!.isCompleted) break;

      debugPrint('[STT] no sound from the microphone, starting again');
      await _speech.cancel();
      await Future<void>.delayed(_retryDelay);
    }

    if (_wanted) _startWatchdog();
  }

  void _setRecording(bool value) {
    if (_isRecording == value) return;
    _isRecording = value;
    if (_wanted || !value) _onRecording?.call(value);
  }

  /// Restarts listening if sound levels stop arriving while the button is held.
  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(_watchdogInterval, (_) {
      if (!_wanted) {
        _watchdog?.cancel();
        return;
      }
      final last = _lastSound;
      if (last != null && DateTime.now().difference(last) > _quietLimit) {
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

  void _onResult(SpeechRecognitionResult result) {
    // Receiving words proves the listen started, even without a status event.
    _hasStarted = true;

    final words = [
      result.recognizedWords,
      for (final alt in result.alternates) alt.recognizedWords,
    ].where((w) => w.trim().isNotEmpty).toSet().toList();

    if (words.isNotEmpty) _heard = words;
    if (result.finalResult && words.isNotEmpty) {
      _gotFinalWords = true;
      _completeSession();
    }
  }

  Future<void> _beginListen({required bool keepHeard}) async {
    if (!keepHeard) _heard = [];
    _hasStarted = false;
    _gotFinalWords = false;
    _setRecording(false);
    _recording = Completer<void>();
    // Start the quiet timer now so a listen that never sends sound is caught.
    _lastSound = DateTime.now();
    _session = Completer<void>();

    try {
      await _speech.listen(
        onResult: _onResult,
        onSoundLevelChange: _onSound,
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 6),
          localeId: _localeId,
          partialResults: true,
          cancelOnError: true,
          // The "search" model handles single words and letters far better.
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

    // Keep listening briefly after release so the last sound is not cut off.
    await Future<void>.delayed(_releaseTail);

    // Short answers get up to an extra second to be recognised.
    if (_shortAnswer) {
      for (var i = 0; i < _shortAnswerPolls && _heard.isEmpty && _session != null && !_session!.isCompleted; i++) {
        await Future<void>.delayed(_shortAnswerPoll);
      }
    }

    _wanted = false;
    _watchdog?.cancel();
    _setRecording(false);
    if (_speech.isListening) await _speech.stop();

    final session = _session;
    if (session != null) {
      await session.future.timeout(_finalResultTimeout, onTimeout: () {});
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