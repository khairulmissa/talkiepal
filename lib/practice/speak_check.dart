import 'package:flutter/material.dart';
import 'package:talkiepal/services/hearing_service.dart';
import 'package:talkiepal/services/speech_score.dart';
import 'package:talkiepal/services/speech_service.dart';

/// What the child said and how close it was to the target.
class SpeechCheck {
  final int score;
  final List<String> heard;

  const SpeechCheck(this.score, this.heard);
}

/// Listens to the child once and scores it against [target].
/// Returns null (after telling the child why) when the phone cannot listen.
Future<SpeechCheck?> listenAndScore(BuildContext context, String target) async {
  // The app's own voice must not be heard as the child's.
  await SpeechService.instance.stop();

  final hearing = HearingService.instance;
  if (!await hearing.isAvailable()) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎤 Please allow the microphone for TalkiePal so Dino can hear you.'),
          backgroundColor: Color(0xFFFFB347),
          duration: Duration(seconds: 3),
        ),
      );
    }
    return null;
  }

  final heard = await hearing.listen();
  return SpeechCheck(scoreSpeech(target, heard), heard);
}
