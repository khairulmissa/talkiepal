import 'dart:math';

import 'package:talkiepal/config/api_config.dart';
import 'package:talkiepal/services/backend_client.dart';

class PracticeQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  const PracticeQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  String get correctAnswer => options[correctIndex];
}

class QuestionResult {
  final List<PracticeQuestion> questions;

  /// True when the AI could not be reached and offline questions were used.
  final bool isOffline;

  const QuestionResult({required this.questions, required this.isOffline});
}

/// Gets question-and-answer practice from the AI backend, with offline
/// questions as backup.
class QuestionService {
  // Backup questions: [question, correct answer, wrong answer, wrong answer].
  static const Map<String, List<List<String>>> _offlineQuestions = {
    'About Me': [
      ['What is your name?', 'My name is Ahmad.', 'I am 9 years old.', 'I like blue.'],
      ['How old are you?', 'I am 8 years old.', 'I am fine.', 'My name is Ali.'],
      ['Where do you live?', 'I live in Kuala Lumpur.', 'I go to school.', 'I eat rice.'],
      ['What is your favourite colour?', 'My favourite colour is red.', 'I am happy.', 'I have a cat.'],
      ['When is your birthday?', 'My birthday is in May.', 'I am 10 years old.', 'I like cake.'],
    ],
    'Daily Routine': [
      ['What time do you wake up?', 'I wake up at 7 o\'clock.', 'I like football.', 'My bag is blue.'],
      ['What do you eat for breakfast?', 'I eat bread for breakfast.', 'I go by bus.', 'I am happy.'],
      ['How do you go to school?', 'I go to school by bus.', 'I eat rice.', 'My name is Sara.'],
      ['What do you do after school?', 'I play with my friends.', 'It is sunny.', 'I am 9 years old.'],
      ['What time do you sleep?', 'I sleep at 9 o\'clock.', 'I like red.', 'I live in Penang.'],
    ],
    'My School': [
      ['What is your favourite subject?', 'My favourite subject is science.', 'I wake up early.', 'It is raining.'],
      ['Who is your teacher?', 'My teacher is Cikgu Aminah.', 'I eat noodles.', 'I am 8 years old.'],
      ['What do you bring to school?', 'I bring my bag and books.', 'I like the park.', 'I feel sleepy.'],
      ['Do you like homework?', 'Yes, I like homework.', 'I go by car.', 'My shirt is green.'],
      ['What do you do at recess?', 'I eat and play with friends.', 'I live in Johor.', 'It is cold.'],
    ],
    'Travel & Holiday': [
      ['Where did you go on holiday?', 'I went to the beach.', 'I am 8 years old.', 'I like science.'],
      ['How did you travel?', 'I travelled by car.', 'My name is Adam.', 'I feel hungry.'],
      ['Who went with you?', 'I went with my family.', 'It is very hot.', 'I eat bread.'],
    ],
    'Weather & Seasons': [
      ['What is the weather today?', 'It is sunny today.', 'I go to school.', 'My name is Mei.'],
      ['What do you wear when it rains?', 'I wear a raincoat.', 'I am 9 years old.', 'I like cats.'],
      ['Do you like rainy days?', 'Yes, I like rainy days.', 'I go by bus.', 'My teacher is kind.'],
    ],
    'Feelings & Emotion': [
      ['How do you feel today?', 'I feel happy today.', 'I live in Melaka.', 'I eat rice.'],
      ['What makes you happy?', 'Playing with friends makes me happy.', 'It is cloudy.', 'I go by car.'],
      ['What do you do when you are sad?', 'I talk to my mother.', 'My bag is red.', 'I am 10 years old.'],
    ],
    'Places Around Town': [
      ['Where do you buy food?', 'I buy food at the market.', 'I feel sleepy.', 'My name is Ravi.'],
      ['Where do you borrow books?', 'I borrow books at the library.', 'It is sunny.', 'I like red.'],
      ['Where do you go when you are sick?', 'I go to the clinic.', 'I play football.', 'I am happy.'],
    ],
  };

  // Questions shown in recent sessions, sent to the AI so it asks new ones.
  static final Map<String, List<String>> _recentQuestions = {};

  static Future<QuestionResult> getQuestions({
    required String topic,
    int count = 10,
  }) async {
    final recent = _recentQuestions[topic] ?? [];

    try {
      final data = await postToBackend(ApiConfig.generateQuestionsUrl, {
        'topic': topic,
        'count': count,
        'exclude': recent,
      });

      final questions = (data['questions'] as List)
          .map((item) => PracticeQuestion(
                question: item['question'] as String,
                options: List<String>.from(item['options'] as List),
                correctIndex: item['correct_index'] as int,
              ))
          .toList();

      if (questions.isEmpty) {
        throw Exception('No questions returned');
      }

      // Remember the last 20 questions for this topic.
      final updated = [...recent, ...questions.map((q) => q.question)];
      _recentQuestions[topic] = updated.sublist(max(0, updated.length - 20));

      return QuestionResult(questions: questions, isOffline: false);
    } catch (_) {
      return QuestionResult(questions: _offlineQuestionsFor(topic, count), isOffline: true);
    }
  }

  static List<PracticeQuestion> _offlineQuestionsFor(String topic, int count) {
    final random = Random();
    final items = [...?_offlineQuestions[topic]]..shuffle(random);

    return items.take(count).map((item) {
      final options = item.sublist(1)..shuffle(random);
      return PracticeQuestion(
        question: item[0],
        options: options,
        correctIndex: options.indexOf(item[1]),
      );
    }).toList();
  }
}
