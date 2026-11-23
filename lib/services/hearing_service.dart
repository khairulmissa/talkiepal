import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:talkiepal/services/pronunciation_result.dart';
import 'package:talkiepal/services/server_hearing_service.dart';

abstract class HearingService {
  static HearingService instance = SmartHearingService();

  Future<bool> isAvailable();

  Future<void> start({void Function(bool isRecording)? onRecording, bool shortAnswer = false, String? target});

  Future<List<String>> finish();

  Future<void> stop();

  PronunciationResult? get lastPronunciation;
}

class SmartHearingService implements HearingService {
  final ServerHearingService server = ServerHearingService();
  final PhoneHearingService phone = PhoneHearingService();

  HearingService? _current;
  PronunciationResult? _lastPronunciation;

  @override
  PronunciationResult? get lastPronunciation => _lastPronunciation;

  Future<HearingService> _pick() async {
    return await server.isReachable() ? server : phone;
  }

  @override
  Future<bool> isAvailable() async {
    final picked = await _pick();
    return picked.isAvailable();
  }

  @override
  Future<void> start({void Function(bool isRecording)? onRecording, bool shortAnswer = false, String? target}) async {
    await _current?.stop();
    _lastPronunciation = null;
    final picked = await _pick();
    _current = picked;
    debugPrint('[STT] using ${picked == server ? 'speech server' : 'phone recogniser'}');
    await picked.start(onRecording: onRecording, shortAnswer: shortAnswer, target: target);
  }

  @override
  Future<List<String>> finish() async {
    final current = _current;
    _current = null;
    if (current == null) return const [];
    final heard = await current.finish();
    _lastPronunciation = current.lastPronunciation;
    return heard;
  }

  @override
  Future<void> stop() async {
    final current = _current;
    _current = null;
    _lastPronunciation = null;
    await current?.stop();
  }
}

class PhoneHearingService implements HearingService {
  static const int _maxRestarts = 12;
  static const int _maxStartAttempts = 3;
  static const double _silentLevel = -100;
  static const String _localeId = 'en_US';

  static const Duration _restartDelay = Duration(milliseconds: 200);
  static const Duration _firstSoundTimeout = Duration(milliseconds: 1200);
  static const Duration _retryDelay = Duration(milliseconds: 400);
  static const Duration _watchdogInterval = Duration(milliseconds: 500);
  static const Duration _quietLimit = Duration(milliseconds: 2500);
  static const Duration _releaseTail = Duration(milliseconds: 700);
  static const Duration _shortAnswerPoll = Duration(milliseconds: 100);
  static const int _shortAnswerPolls = 15;
  static const Duration _finalResultTimeout = Duration(seconds: 3);

  static const Set<String> _hardErrors = {
    'error_permission',
    'error_insufficient_permissions',
    'error_language_not_supported',
    'error_language_unavailable',
  };

  final SpeechToText _speech = SpeechToText();
  Future<bool>? _setUp;

  @override
  PronunciationResult? get lastPronunciation => null;

  bool _wanted = false;
  int _restarts = 0;
  bool _restartPending = false;

  Completer<void>? _session;
  bool _hasStarted = false;

  final List<List<String>> _segments = [];
  List<String> _partial = [];

  Completer<void>? _recording;
  DateTime? _lastSound;
  double _maxLevel = _silentLevel;
  Timer? _watchdog;
  bool _isRecording = false;
  void Function(bool)? _onRecording;
  bool _shortAnswer = false;

  List<String> get _heard {
    final parts = [
      ..._segments,
      if (_partial.isNotEmpty) _partial,
    ];
    if (parts.isEmpty) return const [];
    if (parts.length == 1) return parts.first;

    final before = parts.sublist(0, parts.length - 1).map((p) => p.first).join(' ');
    return parts.last.map((last) => '$before $last').toSet().toList();
  }

  void _commitPartial() {
    if (_partial.isEmpty) return;
    _segments.add(_partial);
    _partial = [];
  }

  @override
  Future<bool> isAvailable() {
    return _setUp ??= _speech
        .initialize(onStatus: _onStatus, onError: (e) => _onError(e.errorMsg))
        .catchError((_) => false)
        .then((ok) {
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

  void _listenEnded() {
    if (_wanted && _restarts < _maxRestarts) {
      if (_restartPending) return;
      _restartPending = true;
      _restarts++;
      debugPrint('[STT] stopped early, listening again ($_restarts)');
      final restartFor = _session;
      Future.delayed(_restartDelay, () async {
        _restartPending = false;
        if (!_wanted || _session != restartFor) return;
        _commitPartial();
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
  Future<void> start({void Function(bool isRecording)? onRecording, bool shortAnswer = false, String? target}) async {
    if (!await isAvailable()) return;
    _onRecording = onRecording;
    _shortAnswer = shortAnswer;

    if (_speech.isListening) await _speech.cancel();

    _wanted = true;
    _restarts = 0;
    _restartPending = false;
    _segments.clear();
    _partial = [];
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
    _hasStarted = true;

    final words = [
      result.recognizedWords,
      for (final alt in result.alternates) alt.recognizedWords,
    ].map((w) => w.trim()).where((w) => w.isNotEmpty).toSet().toList();

    if (words.isEmpty) return;

    if (result.finalResult) {
      if (_partial.isEmpty && _segments.isNotEmpty && listEquals(_segments.last, words)) return;
      _partial = [];
      _segments.add(words);
      if (!_wanted) _completeSession();
    } else {
      _partial = words;
    }
  }

  Future<void> _beginListen({required bool keepHeard}) async {
    if (!keepHeard) {
      _segments.clear();
      _partial = [];
    }
    _hasStarted = false;
    _setRecording(false);
    _recording = Completer<void>();
    _lastSound = DateTime.now();
    _session = Completer<void>();

    try {
      await _speech.listen(
        onResult: _onResult,
        onSoundLevelChange: _onSound,
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 10),
          localeId: _localeId,
          partialResults: true,
          cancelOnError: true,
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

    await Future<void>.delayed(_releaseTail);

    if (_shortAnswer) {
      for (var i = 0; i < _shortAnswerPolls && _heard.isEmpty && _session != null && !_session!.isCompleted; i++) {
        await Future<void>.delayed(_shortAnswerPoll);
      }
    }

    _wanted = false;
    _watchdog?.cancel();
    _setRecording(false);
    if (_speech.isListening) {
      await _speech.stop();
    } else {
      _completeSession();
    }

    final session = _session;
    if (session != null) {
      await session.future.timeout(_finalResultTimeout, onTimeout: () {});
    }
    _session = null;

    final heard = _heard;
    debugPrint('[STT] heard $heard (restarted $_restarts times, loudest ${_maxLevel.toStringAsFixed(1)})');
    return heard;
  }

  @override
  Future<void> stop() async {
    _wanted = false;
    _watchdog?.cancel();
    _setRecording(false);
    _completeSession();
    _session = null;
    _segments.clear();
    _partial = [];
    if (_speech.isListening) await _speech.cancel();
  }
}