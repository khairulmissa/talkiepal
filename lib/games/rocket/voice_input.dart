import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:record/record.dart';

/// How loud the child is, from 0 (silent) to 1 (very loud).
/// Kept behind an interface so the game can be tested without a microphone.
abstract class VoiceInput {
  /// Asks for the microphone if needed. False when the child's parent said no.
  Future<bool> requestPermission();

  /// Starts listening and returns the loudness, several times a second.
  Future<Stream<double>> start();

  Future<void> stop();

  void dispose();
}

/// Listens to the real microphone. Nothing is saved: the sound is only used
/// to work out how loud it is, then thrown away.
class MicVoiceInput implements VoiceInput {
  final AudioRecorder _recorder = AudioRecorder();

  @override
  Future<bool> requestPermission() => _recorder.hasPermission();

  @override
  Future<Stream<double>> start() async {
    final audio = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    ));
    return audio.map(loudnessOf);
  }

  /// Loudness of one chunk of 16-bit sound: quiet room about 0.1, talking about 0.5+.
  static double loudnessOf(Uint8List bytes) {
    // Read the samples one by one: on a real phone a chunk can start at an odd
    // byte, which a direct Int16List view does not allow.
    final data = ByteData.sublistView(bytes);
    final count = bytes.lengthInBytes ~/ 2;
    if (count == 0) return 0;

    var sum = 0.0;
    for (var i = 0; i < count; i++) {
      final s = data.getInt16(i * 2, Endian.little);
      sum += s * s;
    }
    final rms = sqrt(sum / count) / 32768;
    if (rms <= 0) return 0;

    // From decibels: -60 dB (silence) is 0, -10 dB (shouting) is 1.
    final db = 20 * log(rms) / ln10;
    return ((db + 60) / 50).clamp(0.0, 1.0);
  }

  @override
  Future<void> stop() async {
    if (await _recorder.isRecording()) await _recorder.stop();
  }

  @override
  void dispose() {
    _recorder.dispose();
  }
}
