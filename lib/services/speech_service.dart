import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

/// Reads words and sentences aloud with the phone's own voice (text-to-speech).
/// Every page uses [SpeechService.instance], so tests can swap in a fake.
abstract class SpeechService {
  static SpeechService instance = PhoneSpeechService();

  /// Says [text] and finishes when the voice is done (or stopped).
  /// [onWord] is called with the index of each word as it is spoken, so the
  /// page can light it up in time with the voice.
  /// [cheerful] is Dino's own voice: higher and quicker, like a cartoon.
  /// Practice words never use it, so they stay clear.
  Future<void> speak(String text, {void Function(int wordIndex)? onWord, bool slow = false, bool cheerful = false});

  /// Stops talking straight away, e.g. when the child leaves the page.
  Future<void> stop();
}

/// Uses the phone's text-to-speech voice (Google on Android). Free and works offline.
class PhoneSpeechService implements SpeechService {
  final FlutterTts _tts = FlutterTts();
  Future<void>? _setUp;

  // Normal speed is 0.5 on Android; slower is clearer for children.
  static const double _rate = 0.36;
  static const double _slowRate = 0.30;

  // Normal pitch is 1.0. Practice uses a little higher; Dino's cheerful
  // voice much higher and quicker, so it sounds young and excited.
  static const double _pitch = 1.1;
  static const double _cheerfulPitch = 1.65;
  static const double _cheerfulRate = 0.48;

  // Bumped for every new sentence, so word events from an old one are ignored.
  int _run = 0;
  void Function(int)? _onWord;
  String _text = '';

  Future<void> _ready() {
    return _setUp ??= () async {
      await _tts.setLanguage('en-US');
      await _tts.setPitch(_pitch);
      await _tts.setVolume(1.0);
      // speak() then only finishes when the voice is done.
      await _tts.awaitSpeakCompletion(true);

      _tts.setProgressHandler((text, start, end, word) {
        _onWord?.call(_wordIndexAt(start));
      });
    }();
  }

  /// Which word of the text starts at character [offset].
  int _wordIndexAt(int offset) {
    final before = _text.substring(0, offset.clamp(0, _text.length)).trim();
    return before.isEmpty ? 0 : before.split(RegExp(r'\s+')).length;
  }

  @override
  Future<void> speak(
    String text, {
    void Function(int wordIndex)? onWord,
    bool slow = false,
    bool cheerful = false,
  }) async {
    await _ready();
    await _tts.stop();

    final run = ++_run;
    _text = text;
    _onWord = (i) {
      if (run == _run) onWord?.call(i);
    };

    await _tts.setSpeechRate(cheerful ? _cheerfulRate : (slow ? _slowRate : _rate));
    await _tts.setPitch(cheerful ? _cheerfulPitch : _pitch);
    onWord?.call(0);

    try {
      // Some phones never say they are done; never wait forever.
      await _tts.speak(text).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      await _tts.stop();
    }
    if (run == _run) _onWord = null;
  }

  @override
  Future<void> stop() async {
    _run++;
    _onWord = null;
    await _tts.stop();
  }
}

/// Says a sentence one word at a time, with a short pause after each word,
/// so a child can follow along. [onWord] lights each word as it is said.
/// Stops early (and returns false) as soon as [keepGoing] says no, e.g. when
/// the child moves on.
Future<bool> speakWordByWord(
  String text, {
  required bool Function() keepGoing,
  void Function(int wordIndex)? onWord,
  bool slow = false,
}) async {
  final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  for (var i = 0; i < words.length; i++) {
    if (!keepGoing()) return false;
    onWord?.call(i);

    if (_saidWithNext.contains(words[i].toLowerCase()) && i + 1 < words.length) {
      // "the" said alone sounds like "thee", so say it with the next word
      // ("the rabbit") and move the light on part-way through.
      final next = i + 1;
      final light = Future.delayed(Duration(milliseconds: slow ? 450 : 350), () {
        if (keepGoing()) onWord?.call(next);
      });
      await SpeechService.instance.speak('${words[i]} ${words[next]}', slow: slow);
      await light;
      i = next;
    } else {
      await SpeechService.instance.speak(words[i], slow: slow);
    }

    if (!keepGoing()) return false;
    await Future.delayed(const Duration(milliseconds: 280));
  }
  return keepGoing();
}

/// Small words that sound wrong when said on their own.
const Set<String> _saidWithNext = {'the', 'a', 'an'};

/// Turns a word written in capitals into something the voice reads as a word,
/// not letter by letter: "LION" becomes "lion". A single letter stays a capital
/// so it is read as its name ("A" is "ay", not "uh").
String toSpoken(String text) => text.trim().length == 1 ? text.trim().toUpperCase() : text.toLowerCase();
