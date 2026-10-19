import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Listens to the child and turns what they said into text (speech-to-text).
/// Every page uses [HearingService.instance], so tests can swap in a fake.
abstract class HearingService {
  static HearingService instance = PhoneHearingService();

  /// Sets up the phone's speech recognition and asks for the microphone.
  /// False when it is not allowed or the phone has none.
  Future<bool> isAvailable();

  /// Listens until the child stops talking and returns what was heard,
  /// best guess first. Empty when nothing was heard.
  Future<List<String>> listen();

  Future<void> stop();
}

/// Uses the phone's own speech recognition (Google on Android). Free.
class PhoneHearingService implements HearingService {
  final SpeechToText _speech = SpeechToText();
  Future<bool>? _setUp;

  // The listen that is going on now. Events from an earlier listen that
  // arrive late must not end it.
  Completer<void>? _session;
  bool _hasStarted = false;

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
      _hasStarted = true;
    } else if ((status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) && _hasStarted) {
      // Only end the listen once it has really started.
      _endSession();
    }
  }

  void _onError(String message) {
    debugPrint('[STT] error: $message');
    _endSession();
  }

  void _endSession() {
    final session = _session;
    if (session != null && !session.isCompleted) session.complete();
  }

  @override
  Future<List<String>> listen() async {
    if (!await isAvailable()) return const [];

    // Make sure the last listen is fully finished first; the phone says
    // "busy" if a new one starts too soon.
    if (_speech.isListening) await _speech.cancel();
    await Future.delayed(const Duration(milliseconds: 300));

    for (var attempt = 0; attempt < 2; attempt++) {
      final started = DateTime.now();
      final heard = await _listenOnce();
      final tookMs = DateTime.now().difference(started).inMilliseconds;
      debugPrint('[STT] heard $heard in ${tookMs}ms');

      // Ended straight away without hearing anything: the phone was not
      // ready yet. Try once more instead of telling the child "I can't hear you".
      if (heard.isNotEmpty || tookMs > 1500) return heard;
      await _speech.cancel();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return const [];
  }

  Future<List<String>> _listenOnce() async {
    var heard = <String>[];
    final session = _session = Completer<void>();
    _hasStarted = false;

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          // Hearing words means it has started, even if no status came.
          _hasStarted = true;
          heard = [
            result.recognizedWords,
            for (final alt in result.alternates) alt.recognizedWords,
          ].where((w) => w.trim().isNotEmpty).toSet().toList();
          if (result.finalResult) _endSession();
        },
        listenOptions: SpeechListenOptions(
          listenFor: const Duration(seconds: 8),
          pauseFor: const Duration(seconds: 2),
          localeId: 'en_US',
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        ),
      );
    } catch (e) {
      debugPrint('[STT] could not start: $e');
      return const [];
    }

    // If it never really starts, do not wait the full time.
    final notStarted = Timer(const Duration(seconds: 3), () {
      if (!_hasStarted && heard.isEmpty) _endSession();
    });

    // Never wait forever if the phone does not say it is done.
    await session.future.timeout(const Duration(seconds: 11), onTimeout: () => _speech.stop());
    notStarted.cancel();

    if (_speech.isListening) await _speech.stop();
    return heard;
  }

  @override
  Future<void> stop() async {
    await _speech.cancel();
    _endSession();
  }
}
