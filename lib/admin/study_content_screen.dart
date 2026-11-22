import 'package:flutter/material.dart';
import 'package:talkiepal/services/study_content_service.dart';
import 'study_subtopic_editor.dart';
import 'widgets/admin_ui.dart';

class StudyContentScreen extends StatefulWidget {
  const StudyContentScreen({super.key});

  @override
  State<StudyContentScreen> createState() => _StudyContentScreenState();
}

class _StudyContentScreenState extends State<StudyContentScreen> {
  String level = StudyContentService.levels.keys.first;

  List<StudySubtopic> _current = [];

  bool get _isQuestions => level == 'intermediate';
  bool get _isSound => level == 'special_sound';

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _edit({StudySubtopic? current}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StudySubtopicEditor(
          level: level,
          current: current,
          nextOrder: _current.length,
        ),
      ),
    );
    if (saved == true) {
      _toast(current == null ? 'Added' : 'Updated');
    }
  }

  Future<void> _delete(StudySubtopic s) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('"${s.title}" will be removed for all kids.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await StudyContentService.delete(s.id);
      _toast('Deleted');
    } catch (e) {
      _toast('Failed to delete: $e');
    }
  }

  Future<void> _togglePublished(StudySubtopic s, bool value) async {
    try {
      await StudyContentService.setPublished(s.id, value);
    } catch (e) {
      _toast('Failed to update: $e');
    }
  }

  Future<void> _importDefaults() async {
    try {
      final added = await StudyContentService.importDefaults(level);
      _toast(added == 0 ? 'Already imported' : 'Imported $added');
    } catch (e) {
      _toast('Failed to import: $e');
    }
  }

  String _summary(StudySubtopic s) {
    if (_isQuestions) return '${s.questions.length} example questions';
    if (_isSound) {
      return 'Level ${s.group} · ${s.words.length} words · ${s.sentences.length} sentences';
    }
    return '${s.words.length} suggested ${level == 'beginner' ? 'words' : 'phrases'}';
  }

  @override
  Widget build(BuildContext context) {
    final levelName = StudyContentService.levels[level]!;

    return AdminPage(
      title: 'Study Content',
      actions: [
        IconButton(
          tooltip: 'Add',
          icon: const Icon(Icons.add),
          onPressed: () => _edit(),
        ),
      ],
      child: StreamBuilder<List<StudySubtopic>>(
        key: ValueKey(level),
        stream: StudyContentService.watchAll(level),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = _current = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AdminCard(
                child: DropdownButtonFormField<String>(
                  initialValue: level,
                  decoration: const InputDecoration(labelText: 'Level'),
                  items: [
                    for (final e in StudyContentService.levels.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: (v) => setState(() => level = v ?? level),
                ),
              ),
              const SizedBox(height: 12),
              AdminCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Import the original $levelName ${_isSound ? 'sounds' : 'subtopics'} '
                          'so you can manage them here.'),
                    ),
                    TextButton(onPressed: _importDefaults, child: const Text('Import')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                AdminCard(
                  child: Text('Nothing in $levelName yet. Kids see the original topics. '
                      'Tap Import, or + to add one.'),
                ),
              for (final s in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AdminCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AdminColors.yellow,
                          child: Text(s.emoji, style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isSound ? 'Sound ${s.title}' : s.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(_summary(s)),
                              Text(
                                s.published ? 'Published' : 'Draft',
                                style: TextStyle(color: s.published ? Colors.green : Colors.orange),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: s.published,
                          onChanged: (v) => _togglePublished(s, v),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (action) => action == 'edit' ? _edit(current: s) : _delete(s),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}