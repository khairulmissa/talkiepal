import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talkiepal/services/exercise_service.dart';
import 'package:talkiepal/services/question_service.dart';

class StudyWord {
  final String word;
  final String emoji;

  const StudyWord({required this.word, this.emoji = StudySubtopic.defaultEmoji});

  factory StudyWord.fromMap(Map<String, dynamic> map) {
    final emoji = (map['emoji'] ?? '').toString().trim();
    return StudyWord(
      word: (map['word'] ?? '').toString().trim().toUpperCase(),
      emoji: emoji.isEmpty ? StudySubtopic.defaultEmoji : emoji,
    );
  }

  Map<String, dynamic> toMap() => {'word': word, 'emoji': emoji};
}


class StudyQuestion {
  final String question;
  final String answer;
  final List<String> wrong;

  const StudyQuestion({required this.question, required this.answer, required this.wrong});

  factory StudyQuestion.fromMap(Map<String, dynamic> map) => StudyQuestion(
        question: (map['question'] ?? '').toString().trim(),
        answer: (map['answer'] ?? '').toString().trim(),
        wrong: [
          for (final w in (map['wrong'] is List ? map['wrong'] as List : const [])) w.toString().trim(),
        ],
      );

  Map<String, dynamic> toMap() => {'question': question, 'answer': answer, 'wrong': wrong};

  bool get isValid => question.isNotEmpty && answer.isNotEmpty && wrong.length >= 2;
}


class StudySubtopic {
  static const String defaultEmoji = '⭐';

  final String id;
  final String level; 
  final String title; 
  final String emoji; 
  final String hint; 
  final String description; 
  final int group; 
  final List<StudyWord> words; 
  final List<StudyWord> sentences; 
  final List<StudyQuestion> questions; 
  final bool published;
  final int order;

  const StudySubtopic({
    this.id = '',
    required this.level,
    required this.title,
    this.emoji = defaultEmoji,
    this.hint = '',
    this.description = '',
    this.group = 1,
    this.words = const [],
    this.sentences = const [],
    this.questions = const [],
    this.published = false,
    this.order = 0,
  });

  static List<StudyWord> _wordList(dynamic raw) => [
        for (final w in (raw is List ? raw : const []))
          if (w is Map) StudyWord.fromMap(Map<String, dynamic>.from(w)),
      ].where((w) => w.word.isNotEmpty).toList();

  factory StudySubtopic.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final emoji = (data['emoji'] ?? '').toString().trim();
    final rawQuestions = data['questions'] is List ? data['questions'] as List : const [];

    return StudySubtopic(
      id: doc.id,
      level: (data['level'] ?? 'beginner').toString(),
      title: (data['title'] ?? '').toString().trim(),
      emoji: emoji.isEmpty ? defaultEmoji : emoji,
      hint: (data['hint'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      group: (data['group'] as num?)?.toInt() ?? 1,
      words: _wordList(data['words']),
      sentences: _wordList(data['sentences']),
      questions: [
        for (final q in rawQuestions)
          if (q is Map) StudyQuestion.fromMap(Map<String, dynamic>.from(q)),
      ].where((q) => q.isValid).toList(),
      published: data['published'] == true,
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'level': level,
        'title': title,
        'emoji': emoji.isEmpty ? defaultEmoji : emoji,
        'hint': hint,
        'description': description,
        'group': group,
        'words': [for (final w in words) w.toMap()],
        'sentences': [for (final s in sentences) s.toMap()],
        'questions': [for (final q in questions) q.toMap()],
        'published': published,
        'order': order,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

abstract final class StudyContentService {
  static final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('study_subtopics');


  static const Map<String, String> levels = {
    'beginner': 'Beginner',
    'pre_intermediate': 'Pre-Intermediate',
    'intermediate': 'Intermediate',
    'special_sound': 'Special Sound',
  };


  static const List<(String, String, String)> beginnerDefaults = [
    ('Colors', '🎨', 'basic colour names'),
    ('Animals', '🐾', 'common animals children know'),
    ('Fruits', '🍎', 'common fruits'),
    ('Body Parts', '🖐️', 'parts of the human body'),
    ('Clothes', '👕', 'everyday clothing items'),
    ('Vehicles', '🚗', 'common vehicles and transport'),
  ];


  static const List<(String, String, String)> preIntermediateDefaults = [
    ('My Morning Routine', '🌅', 'things a child does in the morning, e.g. I WAKE UP'),
    ('My Feelings', '😊', 'simple feelings, e.g. I AM HAPPY'),
    ('Things I Like', '❤️', 'activities a child likes, e.g. I LIKE TO DRAW'),
    ('School & Classroom', '🏫', 'people, objects and actions at school'),
    ('Hobbies & Free Time', '⚽', 'fun activities, e.g. PLAYING FOOTBALL'),
    ('Daily Routine', '⏰', 'everyday actions, e.g. EAT BREAKFAST'),
    ('Home & Rooms', '🏠', 'rooms and things at home, e.g. LIVING ROOM'),
    ('Shopping & Toys', '🧸', 'toys and shopping items, e.g. TEDDY BEAR'),
  ];


  static const List<(String, String, String)> intermediateDefaults = [
    ('About Me', '🙋', 'questions about the child, e.g. name, age, family, favourite things'),
    ('Daily Routine', '⏰', "questions about the child's day, e.g. waking up, meals, going to school"),
    ('My School', '🏫', 'questions about school, e.g. teacher, subjects, friends, recess'),
    ('Travel & Holiday', '✈️', 'questions about holidays and trips, e.g. where you went, how you travelled'),
    ('Weather & Seasons', '☀️', 'questions about the weather, e.g. sunny, rainy, hot, what you wear'),
    ('Feelings & Emotion', '😊', 'questions about feelings, e.g. how you feel, what makes you happy'),
    ('Places Around Town', '🏙️', 'questions about places, e.g. shop, park, library, hospital'),
  ];

  
  static const List<(String, String, String, int)> specialSoundDefaults = [
    ('R', '🐰', 'The Basic Tricky Sound - Roll your tongue', 1),
    ('S', '🐍', 'The Hissing Sound - Like a snake', 1),
    ('L', '🦁', 'The Light Sound - Tongue touches top', 1),
    ('TH', '👍', 'The Biting Sound - Tongue between teeth', 2),
    ('SH', '🤫', 'The Quiet Sound - Like "shhh"', 2),
    ('CH', '🚂', 'The Train Sound - Like a choo-choo train', 2),
    ('V', '🚐', 'The Buzzing Sound - Teeth on lip', 2),
    ('W', '💧', 'The Woo Sound - Round your lips', 2),
  ];

  static List<StudyWord> _toWords(Map<String, String> map) => [
        for (final e in map.entries) StudyWord(word: e.key, emoji: e.value),
      ];

  
  static List<StudySubtopic> defaultsFor(String level, {bool withContent = false}) {
    if (level == 'beginner' || level == 'pre_intermediate') {
        final list = level == 'beginner' ? beginnerDefaults : preIntermediateDefaults;
        return [
          for (var i = 0; i < list.length; i++)
            StudySubtopic(
              level: level,
              title: list[i].$1,
              emoji: list[i].$2,
              hint: list[i].$3,
              words: withContent ? _toWords(ExerciseService.offlineWordsFor(level, list[i].$1)) : const [],
              published: true,
              order: i,
            ),
        ];
    }
    if (level == 'intermediate') {
        return [
          for (var i = 0; i < intermediateDefaults.length; i++)
            StudySubtopic(
              level: level,
              title: intermediateDefaults[i].$1,
              emoji: intermediateDefaults[i].$2,
              hint: intermediateDefaults[i].$3,
              questions: withContent
                  ? [
                      for (final q in QuestionService.offlineQuestionsFor(intermediateDefaults[i].$1))
                        StudyQuestion(question: q[0], answer: q[1], wrong: q.sublist(2)),
                    ]
                  : const [],
              published: true,
              order: i,
            ),
        ];
    }
    if (level == 'special_sound') {
        return [
          for (var i = 0; i < specialSoundDefaults.length; i++)
            StudySubtopic(
              level: level,
              title: specialSoundDefaults[i].$1,
              emoji: specialSoundDefaults[i].$2,
              description: specialSoundDefaults[i].$3,
              group: specialSoundDefaults[i].$4,
              words: withContent
                  ? _toWords(ExerciseService.offlineWordsFor('special_words', specialSoundDefaults[i].$1))
                  : const [],
              sentences: withContent
                  ? _toWords(ExerciseService.offlineWordsFor('special_sentences', specialSoundDefaults[i].$1))
                  : const [],
              published: true,
              order: i,
            ),
        ];
    }
    return const [];
  }

  static List<StudySubtopic> _sorted(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = snap.docs.map(StudySubtopic.fromDoc).where((s) => s.title.isNotEmpty).toList();
    list.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.title.compareTo(b.title);
    });
    return list;
  }


  static Stream<List<StudySubtopic>> watchAll(String level) =>
      _col.where('level', isEqualTo: level).snapshots().map(_sorted);

  
  static Stream<List<StudySubtopic>> watchPublished(String level) => _col
      .where('level', isEqualTo: level)
      .where('published', isEqualTo: true)
      .snapshots()
      .map(_sorted);

 
  static Stream<List<StudySubtopic>> watchMenu(String level) =>
      watchPublished(level).map((list) => list.isEmpty ? defaultsFor(level) : list);

  
  static Future<void> save(StudySubtopic subtopic) async {
    if (subtopic.id.isEmpty) {
      await _col.add({...subtopic.toMap(), 'createdAt': FieldValue.serverTimestamp()});
    } else {
      await _col.doc(subtopic.id).set(subtopic.toMap(), SetOptions(merge: true));
    }
  }

  static Future<void> setPublished(String id, bool published) =>
      _col.doc(id).update({'published': published, 'updatedAt': FieldValue.serverTimestamp()});

  static Future<void> delete(String id) => _col.doc(id).delete();

  
  static Future<int> importDefaults(String level) async {
    var added = 0;
    for (final subtopic in defaultsFor(level, withContent: true)) {
      
      final slug = subtopic.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      final ref = _col.doc('${level}_$slug');
      if ((await ref.get()).exists) continue;
      await ref.set({...subtopic.toMap(), 'createdAt': FieldValue.serverTimestamp()});
      added++;
    }
    return added;
  }
}