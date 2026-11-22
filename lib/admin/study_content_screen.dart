
import 'package:flutter/material.dart';
import 'widgets/admin_ui.dart';

class StudyContentScreen extends StatefulWidget {
  const StudyContentScreen({super.key});

  @override
  State<StudyContentScreen> createState() =>
      _StudyContentScreenState();
}

class _StudyContentScreenState extends State<StudyContentScreen> {
  final List<Map<String, dynamic>> contents = [
    {
      'word': 'Rabbit',
      'level': 'Beginner',
      'sound': 'R',
      'published': true,
    },
    {
      'word': 'Sun',
      'level': 'Beginner',
      'sound': 'S',
      'published': true,
    },
    {
      'word': 'Lion',
      'level': 'Intermediate',
      'sound': 'L',
      'published': false,
    },
    {
      'word': 'Thumb',
      'level': 'Advanced',
      'sound': 'TH',
      'published': false,
    },
  ];

  Future<void> _edit({int? index}) async {
    final editing = index != null;
    final current = editing ? contents[index] : null;

    final word = TextEditingController(
      text: current?['word'] ?? '',
    );

    String level = current?['level'] ?? 'Beginner';
    String sound = current?['sound'] ?? 'R';

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, updateDialog) => AlertDialog(
          title: Text(editing ? 'Edit Word' : 'Add Word'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: word,
                decoration:
                    const InputDecoration(labelText: 'Word'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: level,
                decoration:
                    const InputDecoration(labelText: 'Level'),
                items: [
                  'Beginner',
                  'Intermediate',
                  'Advanced',
                  'Special Sounds',
                ].map((v) => DropdownMenuItem(
                  value: v,
                  child: Text(v),
                )).toList(),
                onChanged: (v) =>
                    updateDialog(() => level = v ?? level),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: sound,
                decoration:
                    const InputDecoration(labelText: 'Sound'),
                items: ['R', 'S', 'L', 'TH', 'SH']
                    .map((v) => DropdownMenuItem(
                          value: v,
                          child: Text(v),
                        ))
                    .toList(),
                onChanged: (v) =>
                    updateDialog(() => sound = v ?? sound),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (word.text.trim().isNotEmpty) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      setState(() {
        final updated = {
          'word': word.text.trim(),
          'level': level,
          'sound': sound,
          'published': current?['published'] ?? false,
        };

        if (editing) {
          contents[index] = updated;
        } else {
          contents.add(updated);
        }
      });
    }

    word.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Study Content (Demo)',
      actions: [
        IconButton(
          tooltip: 'Add Word',
          icon: const Icon(Icons.add),
          onPressed: () => _edit(),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AdminCard(
            child: Text(
              'Demo mode: Changes are stored in memory only '
              'and will reset when the screen is recreated.',
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < contents.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AdminCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          AdminColors.yellow,
                      child: Text(
                        '${contents[i]['sound']}',
                        style: const TextStyle(
                          color: AdminColors.dark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${contents[i]['word']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('${contents[i]['level']}'),
                          Text(
                            contents[i]['published']
                                ? 'Published'
                                : 'Draft',
                            style: TextStyle(
                              color: contents[i]['published']
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: contents[i]['published'],
                      onChanged: (v) {
                        setState(() {
                          contents[i]['published'] = v;
                        });
                      },
                    ),
                    PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') {
                          _edit(index: i);
                        } else {
                          setState(() => contents.removeAt(i));
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
