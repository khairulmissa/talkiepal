import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:talkiepal/config/api_config.dart';

import 'widgets/parent_ui.dart';

/// Free Talk (AI): parents ask TalkiePal AI about speech practice.
class ParentAiChatScreen extends StatefulWidget {
  const ParentAiChatScreen({super.key});

  @override
  State<ParentAiChatScreen> createState() => _ParentAiChatScreenState();
}

class _ParentAiChatScreenState extends State<ParentAiChatScreen> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final List<Map<String, String>> messages = [];
  bool isLoading = false;

  static const List<String> _suggestions = [
    'Activities for the /S/ sound',
    'Word games for bedtime',
    'My child does not want to talk',
    'How long should we practise?',
  ];

  Future<void> sendMessage([String? text]) async {
    final message = (text ?? controller.text).trim();

    if (message.isEmpty || isLoading) return;

    setState(() {
      messages.add({'role': 'user', 'text': message});
      isLoading = true;
    });
    controller.clear();
    _scrollDown();

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.chatUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': message}),
          )
          .timeout(const Duration(seconds: 120));

      if (!mounted) return;

      setState(() {
        messages.add({
          'role': 'ai',
          'text': response.statusCode == 200
              ? jsonDecode(response.body)['reply'].toString()
              : 'Sorry, the AI is unavailable. Please try again.',
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        messages.add({'role': 'ai', 'text': 'Connection failed. Check your AI backend.'});
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        _scrollDown();
      }
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ParentPage(
      header: ParentHeader(
        back: true,
        titleWidget: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Text('🤖', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Free Talk (AI)',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  Text(
                    isLoading ? 'Typing...' : 'Speech practice helper',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          const _Bubble(
            text: 'Hello! I am TalkiePal AI. Ask me for speech practice activities and ideas for your child. 😊',
            isUser: false,
          ),
          if (messages.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Text(
                'Try asking',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: ParentColors.soft),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _suggestions)
                    GestureDetector(
                      onTap: () => sendMessage(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: ParentColors.purple.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ParentColors.purpleDark,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          for (final m in messages) _Bubble(text: m['text'] ?? '', isUser: m['role'] == 'user'),
          if (isLoading) const _Bubble(text: '...', isUser: false),
        ],
      ),
      bottom: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [BoxShadow(color: Color(0x222E2538), blurRadius: 16, offset: Offset(0, 6))],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLength: 1000,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    hintText: 'Ask TalkiePal AI...',
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => sendMessage(),
                ),
              ),
              GestureDetector(
                onTap: isLoading ? null : sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isLoading ? ParentColors.muted : ParentColors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _Bubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? ParentColors.purple : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser ? null : Border.all(color: ParentColors.line),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 14, height: 1.35, color: isUser ? Colors.white : ParentColors.ink),
        ),
      ),
    );
  }
}
