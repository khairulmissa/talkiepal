import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:talkiepal/config/api_config.dart';
import 'package:talkiepal/services/hearing_service.dart';

class ServerHearingService implements HearingService {
  ServerHearingService({http.Client? client}) : _client = client ?? http.Client();

  static const int _sampleRate = 16000;
  static const Duration _releaseTail = Duration(milliseconds: 400);
  static const Duration _uploadTimeout = Duration(seconds: 25);
  static const Duration _healthTimeout = Duration(milliseconds: 1500);
  static const Duration _healthCache = Duration(seconds: 30);

  static const String transcribeUrl = '${ApiConfig.baseUrl}/speech/transcribe';
  static const String healthUrl = '${ApiConfig.baseUrl}/speech/health';

  final http.Client _client;
  final AudioRecorder _recorder = AudioRecorder();
  final BytesBuilder _pcm = BytesBuilder(copy: false);

  StreamSubscription<Uint8List>? _subscription;
  void Function(bool)? _onRecording;
  bool _shortAnswer = false;
  bool _active = false;
  bool _gotSound = false;

  bool? _reachable;
  DateTime? _checkedAt;

  Future<bool> isReachable() async {
    final checkedAt = _checkedAt;
    if (_reachable != null && checkedAt != null && DateTime.now().difference(checkedAt) < _healthCache) {
      return _reachable!;
    }
    try {
      final response = await _client.get(Uri.parse(healthUrl)).timeout(_healthTimeout);
      _reachable = response.statusCode == 200;
    } catch (_) {
      _reachable = false;
    }
    _checkedAt = DateTime.now();
    debugPrint('[STT] speech server reachable: $_reachable');
    return _reachable!;
  }

  void markUnreachable() {
    _reachable = false;
    _checkedAt = DateTime.now();
  }

  @override
  Future<bool> isAvailable() async {
    try {
      return await _recorder.hasPermission();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> start({void Function(bool isRecording)? onRecording, bool shortAnswer = false}) async {
    if (!await isAvailable()) return;
    await _closeStream();

    _pcm.clear();
    _onRecording = onRecording;
    _shortAnswer = shortAnswer;
    _gotSound = false;
    _active = true;

    try {
      final stream = await _recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
        autoGain: true,
        echoCancel: false,
        noiseSuppress: false,
      ));
      _subscription = stream.listen(_onChunk, onError: (Object e) {
        debugPrint('[STT] recorder error: $e');
      });
    } catch (e) {
      debugPrint('[STT] could not start recorder: $e');
      _active = false;
    }
  }

  void _onChunk(Uint8List chunk) {
    if (!_active) return;
    _pcm.add(chunk);
    if (!_gotSound && chunk.isNotEmpty) {
      _gotSound = true;
      _onRecording?.call(true);
    }
  }

  @override
  Future<List<String>> finish() async {
    if (!_active) return const [];

    await Future<void>.delayed(_releaseTail);
    _active = false;
    await _closeStream();
    _onRecording?.call(false);

    final pcm = _pcm.takeBytes();
    if (pcm.isEmpty) return const [];

    final wav = _toWav(pcm);
    debugPrint('[STT] sending ${(pcm.length / 2 / _sampleRate).toStringAsFixed(2)}s of audio');

    try {
      final request = http.MultipartRequest('POST', Uri.parse(transcribeUrl))
        ..fields['short'] = _shortAnswer ? 'true' : 'false'
        ..files.add(http.MultipartFile.fromBytes('audio', wav, filename: 'speech.wav'));
      final streamed = await _client.send(request).timeout(_uploadTimeout);
      final response = await http.Response.fromStream(streamed).timeout(_uploadTimeout);

      if (response.statusCode != 200) {
        debugPrint('[STT] server said ${response.statusCode}: ${response.body}');
        if (response.statusCode >= 500) markUnreachable();
        return const [];
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final alternatives = (body['alternatives'] as List<dynamic>? ?? const [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      debugPrint('[STT] server heard $alternatives (${body['reason']})');
      return alternatives;
    } catch (e) {
      debugPrint('[STT] could not reach speech server: $e');
      markUnreachable();
      return const [];
    }
  }

  @override
  Future<void> stop() async {
    _active = false;
    await _closeStream();
    _pcm.clear();
    _onRecording?.call(false);
  }

  Future<void> _closeStream() async {
    try {
      if (await _recorder.isRecording()) await _recorder.stop();
    } catch (_) {}
    await _subscription?.cancel();
    _subscription = null;
  }

  static Uint8List _toWav(Uint8List pcm) {
    final header = ByteData(44);
    const channels = 1;
    const bitsPerSample = 16;
    const byteRate = _sampleRate * channels * bitsPerSample ~/ 8;
    const blockAlign = channels * bitsPerSample ~/ 8;
    final dataLength = pcm.length - pcm.length % 2;

    void ascii(int offset, String text) {
      for (var i = 0; i < text.length; i++) {
        header.setUint8(offset + i, text.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    header.setUint32(4, 36 + dataLength, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, _sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    ascii(36, 'data');
    header.setUint32(40, dataLength, Endian.little);

    return Uint8List.fromList([...header.buffer.asUint8List(), ...pcm.sublist(0, dataLength)]);
  }
}