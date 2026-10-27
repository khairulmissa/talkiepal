import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ParentTherapistChatScreen extends StatefulWidget {
  final String parentId;
  final String therapistId;
  final String childId;
  final String therapistName;

  const ParentTherapistChatScreen({
    super.key,
    required this.parentId,
    required this.therapistId,
    required this.childId,
    required this.therapistName,
  });

  @override
  State<ParentTherapistChatScreen> createState() => _ParentTherapistChatScreenState();
}

class _ParentTherapistChatScreenState extends State<ParentTherapistChatScreen> {
  static const Color purple = Color(0xFF8154AA);
  static const Color cream = Color(0xFFFFFBF4);
  static const Color yellow = Color(0xFFFFEFA8);

  final TextEditingController _message = TextEditingController();
  bool _sending = false;
  late Future<void> _chatReady;

  String get _chatId => '${widget.parentId}_${widget.childId}_${widget.therapistId}';
  DocumentReference<Map<String, dynamic>> get _chatRef =>
      FirebaseFirestore.instance.collection('chats').doc(_chatId);

  @override
  void initState() {
    super.initState();
    _chatReady = _initializeChat();
  }

  String _displayName(Map<String, dynamic>? data, String fallback, List<String> keys) {
    for (final key in keys) {
      final value = (data?[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  Future<void> _initializeChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != widget.parentId) {
      throw StateError('Please sign in with the parent account.');
    }

    final db = FirebaseFirestore.instance;
    final parentRef = db.collection('users').doc(widget.parentId);
    final childRef = parentRef.collection('children').doc(widget.childId);
    final existing = await _chatRef.get();
    if (existing.exists) {
      final data = existing.data() ?? {};
      if (data['parentId'] != widget.parentId ||
          data['therapistId'] != widget.therapistId ||
          data['childId'] != widget.childId) {
        throw StateError('Chat participants do not match.');
      }
      // Existing conversations stay untouched; names are added to new chats.
      return;
    }

    final results = await Future.wait([parentRef.get(), childRef.get()]);
    final parentData = results[0].data();
    final childData = results[1].data();
    if (childData == null || childData['assignedTherapistId'] != widget.therapistId) {
      throw StateError('The selected child is not assigned to this therapist.');
    }
    final authName = (user.displayName ?? '').trim();
    final parentName = _displayName(
      parentData,
      authName.isNotEmpty ? authName : 'Parent',
      ['username', 'fullName', 'name'],
    );
    final childName = _displayName(childData, 'Child', ['name', 'fullName', 'childName']);

    try {
      await _chatRef.set({
        'parentId': widget.parentId,
        'therapistId': widget.therapistId,
        'childId': widget.childId,
        'parentName': parentName,
        'childName': childName,
        'lastMessage': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      // If another device created the conversation meanwhile, use that one.
      final current = await _chatRef.get(const GetOptions(source: Source.server));
      if (!current.exists) rethrow;
      final data = current.data() ?? {};
      if (data['parentId'] != widget.parentId ||
          data['therapistId'] != widget.therapistId ||
          data['childId'] != widget.childId) rethrow;
    }
  }

  void _retryChat() => setState(() => _chatReady = _initializeChat());

  Future<void> _send() async {
    final text = _message.text.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (text.isEmpty || text.length > 2000 || _sending || uid != widget.parentId) return;
    setState(() => _sending = true);
    try {
      await _chatReady;
      final messageRef = _chatRef.collection('messages').doc();
      final batch = FirebaseFirestore.instance.batch();
      batch.set(messageRef, {
        'senderId': uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(_chatRef, {
        'lastMessage': text,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      if (mounted) _message.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message not sent: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid != widget.parentId) {
      return const Scaffold(body: Center(child: Text('Parent sign-in required.')));
    }
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: Text(widget.therapistName),
        backgroundColor: purple,
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        Expanded(child: FutureBuilder<void>(
          future: _chatReady,
          builder: (context, ready) {
            if (ready.hasError) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, color: purple, size: 40),
                  const SizedBox(height: 12),
                  Text('Cannot open chat:\n${ready.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _retryChat, child: const Text('Try Again')),
                ]),
              ));
            }
            if (ready.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(color: purple));
            }
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chatRef.collection('messages')
                  .orderBy('createdAt', descending: true).limit(100).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Cannot load messages: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('Say hello to your therapist! 💜'));
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final mine = data['senderId'] == uid;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: mine ? yellow : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text((data['text'] ?? '').toString()),
                      ),
                    );
                  },
                );
              },
            );
          },
        )),
        SafeArea(top: false, child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _message, maxLength: 2000, minLines: 1, maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message...', counterText: '',
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
              ),
            )),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sending ? null : _send,
              style: IconButton.styleFrom(backgroundColor: purple),
              icon: _sending
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
            ),
          ]),
        )),
      ]),
    );
  }
}
