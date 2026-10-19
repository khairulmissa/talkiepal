import 'dart:async';

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

  // Ends the current listen when the phone says it has stopped.
  Completer<void>? _stopped;

  @override
  Future<bool> isAvailable() {
    return _setUp ??= _speech
        .initialize(
          onStatus: (status) {
            if (status == SpeechToText.doneStatus || status == SpeechToText.notListeningStatus) {
              _markStopped();
            }
          },
          onError: (_) => _markStopped(),
        )
        .catchError((_) => false)
        .then((ok) {
          // Try again next time if it failed (e.g. permission was refused).
          if (!ok) _setUp = null;
          return ok;
        });
  }

  void _markStopped() {
    final stopped = _stopped;
    if (stopped != null && !stopped.isCompleted) stopped.complete();
  }

  @override
  Future<List<String>> listen() async {
    if (!await isAvailable()) return const [];

    var heard = <String>[];
    final stopped = _stopped = Completer<void>();

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        heard = [
          result.recognizedWords,
          for (final alt in result.alternates) alt.recognizedWords,
        ].where((w) => w.trim().isNotEmpty).toSet().toList();
        if (result.finalResult) _markStopped();
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

    // Never wait forever if the phone does not say it is done.
    await stopped.future.timeout(const Duration(seconds: 11), onTimeout: () => _speech.stop());
    return heard;
  }

  @override
  Future<void> stop() async {
    await _speech.stop();
    _markStopped();
  }
}
