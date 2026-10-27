
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:talkiepal/config/api_config.dart';

import 'therapist_ui.dart';

/// Separate AI assistant for therapists.
/// FastAPI endpoint: POST /ai/therapist
class TherapistAiChatScreen extends StatefulWidget {
  const TherapistAiChatScreen({super.key});

  @override
  State<TherapistAiChatScreen> createState() =>
      _TherapistAiChatScreenState();
}

class _TherapistAiChatScreenState
    extends State<TherapistAiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];

  bool _loading = false;

  static const List<String> _suggestions = [
    'Plan a 30-minute /R/ speech practice session',
    'Create 3 progressive /S/ practice modules',
    'Suggest ways to measure pronunciation progress',
    'Sensory-friendly activities for speech practice',
  ];

  Uri get _endpoint => Uri.parse(ApiConfig.therapistChatUrl);

  Future<void> _send([String? suggestion]) async {
    final message = (suggestion ?? _controller.text).trim();

    if (message.isEmpty || _loading) return;

    setState(() {
      _messages.add(_ChatMessage(message, true));
      _loading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw StateError(
          'No Firebase user signed in. Please log in as a therapist.',
        );
      }

      debugPrint('========== THERAPIST AI DEBUG ==========');
      debugPrint('Firebase UID: ${user.uid}');
      debugPrint('Endpoint: $_endpoint');
      debugPrint('Message: $message');

      // Get Firebase authentication token.
      final token = await user.getIdToken();

      if (token == null || token.isEmpty) {
        throw StateError('Unable to retrieve Firebase ID token.');
      }

      // Send request to therapist-specific FastAPI endpoint.
      final response = await http
          .post(
            _endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'message': message,
            }),
          )
          .timeout(const Duration(seconds: 120));

      debugPrint('THERAPIST AI STATUS: ${response.statusCode}');
      debugPrint('THERAPIST AI RESPONSE: ${response.body}');
      debugPrint('========================================');

      if (!mounted) return;

      String reply;

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);

          if (data is Map && data['reply'] != null) {
            reply = data['reply'].toString();
          } else {
            reply = 'The AI returned an unexpected response.';
          }
        } catch (e) {
          debugPrint('JSON parsing error: $e');
          reply = 'Unable to read the AI response.';
        }
      } else {
        // Temporary detailed message for debugging.
        reply =
            'Therapist AI error (HTTP ${response.statusCode}): '
            '${response.body}';
      }

      setState(() {
        _messages.add(_ChatMessage(reply, false));
      });
    } catch (e, stackTrace) {
      debugPrint('========== THERAPIST AI ERROR ==========');
      debugPrint('Endpoint: $_endpoint');
      debugPrint('Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      debugPrint('========================================');

      if (!mounted) return;

      setState(() {
        _messages.add(
          _ChatMessage(
            'Connection error: $e',
            false,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });

        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TherapistColors.background,

      appBar: AppBar(
        backgroundColor: TherapistColors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.psychology_alt_rounded,
                color: TherapistColors.purple,
                size: 23,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Therapist AI Assistant',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Therapy planning & practice support',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 14),
              children: [
                const _ChatBubble(
                  text:
                      'Hello, Therapist! 👋\n\n'
                      'I can help you plan speech practice sessions, '
                      'develop pronunciation modules, and explore '
                      'ways to track progress.\n\n'
                      'Please review suggestions using your '
                      'professional judgment.',
                  isUser: false,
                ),

                if (_messages.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Text(
                      'SUGGESTED QUESTIONS',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.7,
                        fontWeight: FontWeight.w800,
                        color: TherapistColors.muted,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 9,
                      children: [
                        for (final suggestion in _suggestions)
                          ActionChip(
                            label: Text(suggestion),
                            labelStyle: const TextStyle(
                              color: TherapistColors.deepPurple,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: TherapistColors.purple
                                  .withValues(alpha: 0.25),
                            ),
                            onPressed: _loading
                                ? null
                                : () => _send(suggestion),
                          ),
                      ],
                    ),
                  ),
                ],

                for (final message in _messages)
                  _ChatBubble(
                    text: message.text,
                    isUser: message.isUser,
                  ),

                if (_loading)
                  const _ChatBubble(
                    text: 'Thinking...',
                    isUser: false,
                  ),
              ],
            ),
          ),

          SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 6, 14, 12),
              padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: TherapistColors.border,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Ask about therapy planning...',
                        counterText: '',
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  IconButton.filled(
                    onPressed: _loading
                        ? null
                        : () => _send(),
                    style: IconButton.styleFrom(
                      backgroundColor: TherapistColors.purple,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(
                      Icons.send_rounded,
                    ),
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

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage(this.text, this.isUser);
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _ChatBubble({
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? TherapistColors.purple
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 18),
          ),
          border: isUser
              ? null
              : Border.all(color: TherapistColors.border),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: isUser
                ? Colors.white
                : TherapistColors.text,
          ),
        ),
      ),
    );
  }
}
