
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ParentAiChatScreen extends StatefulWidget {
  const ParentAiChatScreen({super.key});

  @override
  State<ParentAiChatScreen> createState() =>
      _ParentAiChatScreenState();
}

class _ParentAiChatScreenState extends State<ParentAiChatScreen> {
  final TextEditingController controller = TextEditingController();

  final List<Map<String, String>> messages = [];
  bool isLoading = false;

  static const String apiUrl = 'http://127.0.0.1:8000/chat';

  Future<void> sendMessage() async {
    final message = controller.text.trim();

    if (message.isEmpty || isLoading) return;

    setState(() {
      messages.add({'role': 'user', 'text': message});
      isLoading = true;
    });

    controller.clear();

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      ).timeout(const Duration(seconds: 120));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          messages.add({
            'role': 'ai',
            'text': data['reply'].toString(),
          });
        });
      } else {
        setState(() {
          messages.add({
            'role': 'ai',
            'text': 'Sorry, the AI is unavailable. Please try again.',
          });
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        messages.add({
          'role': 'ai',
          'text': 'Connection failed. Check your AI backend.',
        });
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE8),
      appBar: AppBar(
        title: const Text('TalkiePal AI'),
        backgroundColor: const Color(0xFFFFEFA8),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Hello! I am TalkiePal AI.\n'
                        'Ask me for speech practice activities '
                        'and suggestions for your child.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 17),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final item = messages[index];
                      final isUser = item['role'] == 'user';

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.8,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? const Color(0xFFFFEFA8)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            item['text'] ?? '',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      maxLength: 1000,
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Ask TalkiePal AI...',
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  IconButton(
                    onPressed: isLoading ? null : sendMessage,
                    icon: const Icon(Icons.send),
                    color: Colors.black87,
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
