import 'package:flutter/material.dart';

import 'kid_page_ui.dart';

/// Questions children (and their grown-ups) often ask, in simple words.
class KidFaqPage extends StatelessWidget {
  const KidFaqPage({super.key});

  static const List<(String, String, String)> _faq = [
    (
      '🎤',
      'Why can\'t the app hear me?',
      'Hold the talk button while you speak, and let go when you finish. Talk in a quiet place, '
          'close to the phone. If it still can\'t hear you, ask a grown-up to allow the microphone.',
    ),
    (
      '⭐',
      'How do I get more stars?',
      'Say each word slowly and clearly. Green means great, yellow means almost, and red means '
          'try again. Every try makes you better!',
    ),
    (
      '🔁',
      'Can I try a word again?',
      'Yes! Press TRY AGAIN as many times as you like. Practice makes progress.',
    ),
    (
      '🎮',
      'Where are the games?',
      'Tap Game at the bottom of the screen. Pop the Balloon and Voice Rocket use your voice to play.',
    ),
    (
      '📊',
      'Where can I see how I am doing?',
      'Tap Progress at the bottom of the screen to see your stars and scores.',
    ),
    (
      '🤖',
      'Free Talk does not answer.',
      'Free Talk needs the TalkiePal AI to be switched on. Ask a grown-up to try again later.',
    ),
    (
      '👪',
      'How do I change to my brother or sister?',
      'Go to Profile and tap Switch Profile, then pick their picture.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return KidSubPage(
      emoji: '❓',
      title: 'FAQ',
      children: [
        for (final (emoji, question, answer) in _faq)
          KidCard(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                iconColor: KidColors.plum,
                collapsedIconColor: KidColors.plum,
                leading: Text(emoji, style: const TextStyle(fontSize: 24)),
                title: Text(
                  question,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: KidColors.ink),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                children: [
                  Text(
                    answer,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: KidColors.soft, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The rules of TalkiePal, written for children.
class KidTermsPage extends StatelessWidget {
  const KidTermsPage({super.key});

  static const List<(String, String, String)> _rules = [
    (
      '👪',
      'Play with a grown-up nearby',
      'TalkiePal is for practising at home. A parent or carer should know when you are using it.',
    ),
    (
      '🗣️',
      'Use your own voice',
      'The app listens to you only while you hold the talk button. It turns your voice into words '
          'to give you stars, and does not keep recordings of your voice.',
    ),
    (
      '💜',
      'Be kind',
      'Use kind words in Free Talk and when you chat. If something makes you sad or worried, tell a grown-up.',
    ),
    (
      '🔒',
      'Keep secrets safe',
      'Never share your password, home address or phone number in the app.',
    ),
    (
      '⏰',
      'Take breaks',
      'Short practice every day is best. Rest your eyes and voice after a while.',
    ),
    (
      '🩺',
      'Stars are not a doctor',
      'Your scores help you practise. Only a speech therapist can check how you talk.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return KidSubPage(
      emoji: '📄',
      title: 'Terms of Use',
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text(
            'By using TalkiePal, you and your grown-up agree to these rules:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: KidColors.soft),
          ),
        ),
        for (final (emoji, title, text) in _rules)
          KidCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: KidColors.ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        text,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: KidColors.soft, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
