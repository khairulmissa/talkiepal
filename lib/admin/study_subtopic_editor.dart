import 'package:flutter/material.dart';
import 'package:talkiepal/services/study_content_service.dart';
import 'widgets/admin_ui.dart';

class _WordRow {
  final TextEditingController word;
  final TextEditingController emoji;

  _WordRow([StudyWord? w])
      : word = TextEditingController(text: w?.word ?? ''),
        emoji = TextEditingController(
          text: (w == null || w.emoji == StudySubtopic.defaultEmoji) ? '' : w.emoji,
        );

  StudyWord toWord() {
    final e = emoji.text.trim();
    return StudyWord(
      word: word.text.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' '),
      emoji: e.isEmpty ? StudySubtopic.defaultEmoji : e,
    );
  }

  void dispose() {
    word.dispose();
    emoji.dispose();
  }
}

class _QuestionRow {
  final TextEditingController question;
  final TextEditingController answer;
  final TextEditingController wrong1;
  final TextEditingController wrong2;

  _QuestionRow([StudyQuestion? q])
      : question = TextEditingController(text: q?.question ?? ''),
        answer = TextEditingController(text: q?.answer ?? ''),
        wrong1 = TextEditingController(text: q != null && q.wrong.isNotEmpty ? q.wrong[0] : ''),
        wrong2 = TextEditingController(text: q != null && q.wrong.length > 1 ? q.wrong[1] : '');

  StudyQuestion toQuestion() => StudyQuestion(
        question: question.text.trim(),
        answer: answer.text.trim(),
        wrong: [wrong1.text.trim(), wrong2.text.trim()],
      );

  void dispose() {
    question.dispose();
    answer.dispose();
    wrong1.dispose();
    wrong2.dispose();
  }
}

class StudySubtopicEditor extends StatefulWidget {
  final String level;
  final StudySubtopic? current;
  final int nextOrder;

  const StudySubtopicEditor({
    super.key,
    required this.level,
    this.current,
    this.nextOrder = 0,
  });

  @override
  State<StudySubtopicEditor> createState() => _StudySubtopicEditorState();
}

class _StudySubtopicEditorState extends State<StudySubtopicEditor> {
  final _form = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _emoji;
  late final TextEditingController _hint;
  late final TextEditingController _description;
  late int _group;
  late bool _published;

  late final List<_WordRow> _words;
  late final List<_WordRow> _sentences;
  late final List<_QuestionRow> _questions;

  bool _saving = false;

  final List<Object> _removed = [];

  bool get _isQuestions => widget.level == 'intermediate';
  bool get _isSound => widget.level == 'special_sound';
  bool get _editing => widget.current != null;

  String get _itemName => switch (widget.level) {
        'beginner' => 'Word',
        'pre_intermediate' => 'Phrase',
        _ => 'Word',
      };

  @override
  void initState() {
    super.initState();
    final c = widget.current;
    _title = TextEditingController(text: c?.title ?? '');
    _emoji = TextEditingController(text: c?.emoji ?? '');
    _hint = TextEditingController(text: c?.hint ?? '');
    _description = TextEditingController(text: c?.description ?? '');
    _group = c?.group ?? 1;
    _published = c?.published ?? false;
    _words = [for (final w in c?.words ?? const <StudyWord>[]) _WordRow(w)];
    _sentences = [for (final s in c?.sentences ?? const <StudyWord>[]) _WordRow(s)];
    _questions = [for (final q in c?.questions ?? const <StudyQuestion>[]) _QuestionRow(q)];
  }

  @override
  void dispose() {
    for (final c in [_title, _emoji, _hint, _description]) {
      c.dispose();
    }
    for (final r in [..._words, ..._sentences]) {
      r.dispose();
    }
    for (final q in _questions) {
      q.dispose();
    }
    for (final r in _removed) {
      if (r is _WordRow) r.dispose();
      if (r is _QuestionRow) r.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _validateTitle(String? v) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return 'Required';
    if (_isSound && !RegExp(r'^[A-Za-z]{1,3}$').hasMatch(text)) {
      return 'Use 1-3 letters only, e.g. Z or PL';
    }
    return null;
  }

  String? _validateWord(String? v) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return 'Required';
    if (!RegExp(r'^[A-Za-z ]+$').hasMatch(text)) return 'Letters only';
    if (widget.level == 'beginner' && text.contains(' ')) return 'One word only';
    if (_isSound) {
      final sound = _title.text.trim().toUpperCase();
      if (sound.isNotEmpty && !text.toUpperCase().contains(sound)) {
        return 'Must contain "$sound"';
      }
    }
    return null;
  }

  String? _validateQuestion(String? v) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return 'Required';
    if (!text.endsWith('?')) return 'End with ?';
    return null;
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the boxes in red')),
      );
      return;
    }

    setState(() => _saving = true);

    final subtopic = StudySubtopic(
      id: widget.current?.id ?? '',
      level: widget.level,
      title: _isSound ? _title.text.trim().toUpperCase() : _title.text.trim(),
      emoji: _emoji.text.trim(),
      hint: _hint.text.trim(),
      description: _isSound ? _description.text.trim() : '',
      group: _isSound ? _group : 1,
      words: _isQuestions ? const [] : _unique(_words.map((r) => r.toWord())),
      sentences: _isSound ? _unique(_sentences.map((r) => r.toWord())) : const [],
      questions: _isQuestions ? _questions.map((q) => q.toQuestion()).toList() : const [],
      published: _published,
      order: widget.current?.order ?? widget.nextOrder,
    );

    try {
      await StudyContentService.save(subtopic);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  List<StudyWord> _unique(Iterable<StudyWord> words) {
    final seen = <String>{};
    return [
      for (final w in words)
        if (seen.add(w.word)) w,
    ];
  }

  Widget _sectionTitle(String text, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminColors.dark),
          ),
          if (subtitle != null)
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _addButton(String label, VoidCallback onPressed) {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add),
        label: Text(label),
      ),
    );
  }

  Widget _wordList(List<_WordRow> rows, {required String label}) {
    return Column(
      children: [
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'No ${label.toLowerCase()}s yet. AI will create them by itself.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        for (var i = 0; i < rows.length; i++)
          Padding(
            key: ObjectKey(rows[i]),
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text('${i + 1}.', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: rows[i].word,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: label,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: _validateWord,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 76,
                  child: TextFormField(
                    controller: rows[i].emoji,
                    textAlign: TextAlign.center,
                    maxLength: 8,
                    decoration: const InputDecoration(
                      labelText: 'Emoji',
                      hintText: '⭐',
                      border: OutlineInputBorder(),
                      isDense: true,
                      counterText: '',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => setState(() => _removed.add(rows.removeAt(i))),
                ),
              ],
            ),
          ),
        _addButton('Add ${label.toLowerCase()}', () => setState(() => rows.add(_WordRow()))),
      ],
    );
  }

  Widget _questionList() {
    InputDecoration box(String label, {Color? color}) => InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          enabledBorder: color == null
              ? null
              : OutlineInputBorder(borderSide: BorderSide(color: color, width: 1.5)),
          labelStyle: color == null ? null : TextStyle(color: color),
        );

    return Column(
      children: [
        if (_questions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'No example questions yet. AI will create them by itself.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        for (var i = 0; i < _questions.length; i++)
          Padding(
            key: ObjectKey(_questions[i]),
            padding: const EdgeInsets.only(bottom: 12),
            child: AdminCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Question ${i + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AdminColors.dark),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Remove',
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => setState(() => _removed.add(_questions.removeAt(i))),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _questions[i].question,
                    decoration: box('Question (e.g. What pet do you have?)'),
                    validator: _validateQuestion,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _questions[i].answer,
                    decoration: box('✅ Correct answer', color: Colors.green),
                    validator: _required,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _questions[i].wrong1,
                    decoration: box('❌ Wrong answer 1', color: Colors.redAccent),
                    validator: _required,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _questions[i].wrong2,
                    decoration: box('❌ Wrong answer 2', color: Colors.redAccent),
                    validator: _required,
                  ),
                ],
              ),
            ),
          ),
        _addButton('Add question', () => setState(() => _questions.add(_QuestionRow()))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final levelName = StudyContentService.levels[widget.level] ?? widget.level;
    final thing = _isSound ? 'Sound' : 'Subtopic';

    return AdminPage(
      title: '${_editing ? 'Edit' : 'Add'} $thing · $levelName',
      actions: [
        IconButton(
          tooltip: 'Save',
          icon: const Icon(Icons.check),
          onPressed: _saving ? null : _save,
        ),
      ],
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Details'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _title,
                          maxLength: _isSound ? 3 : 40,
                          textCapitalization:
                              _isSound ? TextCapitalization.characters : TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: _isSound ? 'Sound letters (e.g. Z)' : 'Subtopic name (e.g. Shapes)',
                            border: const OutlineInputBorder(),
                          ),
                          validator: _validateTitle,
                          onChanged: _isSound ? (_) => setState(() {}) : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          controller: _emoji,
                          maxLength: 8,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22),
                          decoration: const InputDecoration(
                            labelText: 'Icon',
                            hintText: '⭐',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isSound) ...[
                    TextFormField(
                      controller: _description,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: 'Description for kids',
                        hintText: 'e.g. The Buzzing Bee Sound - Teeth together',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<int>(
                      initialValue: _group,
                      decoration: const InputDecoration(labelText: 'Section', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('🌟 Level 1')),
                        DropdownMenuItem(value: 2, child: Text('🚀 Level 2')),
                      ],
                      onChanged: (v) => setState(() => _group = v ?? _group),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _hint,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: 'Description for AI (optional)',
                      hintText: _isSound ? 'e.g. ZOO, PUZZLE, BUZZ' : 'e.g. basic shapes children know',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Published'),
                    subtitle: Text(_published ? 'Kids can see this' : 'Draft (hidden from kids)'),
                    value: _published,
                    onChanged: (v) => setState(() => _published = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isQuestions) ...[
                    _sectionTitle(
                      'Example questions (optional)',
                      subtitle: 'AI uses these as examples. Also used when AI is offline.',
                    ),
                    _questionList(),
                  ] else ...[
                    _sectionTitle(
                      _isSound ? 'Words to Practice (optional)' : '${_itemName}s (optional)',
                      subtitle: 'AI uses these as examples. Also used when AI is offline.',
                    ),
                    _wordList(_words, label: _itemName),
                  ],
                ],
              ),
            ),
            if (_isSound) ...[
              const SizedBox(height: 16),
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      'Mini Challenge sentences (optional)',
                      subtitle: 'Short sentences with the sound, e.g. THE ZEBRA IS AT THE ZOO',
                    ),
                    _wordList(_sentences, label: 'Sentence'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}