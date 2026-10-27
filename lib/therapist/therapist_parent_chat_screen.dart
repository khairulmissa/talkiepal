import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'therapist_ui.dart';
import 'therapist_dashboard.dart';
import 'therapist_patients_screen.dart';
import 'therapist_profile_screen.dart';

class TherapistParentChatScreen extends StatelessWidget {
  const TherapistParentChatScreen({super.key});

  static const Color purple = Color(0xFF8154AA);
  static const Color yellow = Color(0xFFFFEFA8);

  String _name(dynamic raw, String fallback) {
    final value = (raw ?? '').toString().trim();
    return value.isEmpty ? fallback : value;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Please sign in.')));
    }
    return Scaffold(
      backgroundColor: TherapistColors.background,
      appBar: AppBar(
        title: const Text('Parent Chat', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: TherapistColors.background,
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF9D71C0), Color(0xFF69418F)]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Parent conversations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 5),
            Text('Stay connected with your patients\' families.', style: TextStyle(color: Colors.white)),
          ]),
        ),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('chats')
              .where('therapistId', isEqualTo: uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Unable to load chats: ${snapshot.error}', textAlign: TextAlign.center),
              ));
            }
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final chats = snapshot.data!.docs.toList()..sort((a, b) {
              final at = (a.data()['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              final bt = (b.data()['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              return bt.compareTo(at);
            });
            if (chats.isEmpty) {
              return const Center(child: Text('No parent conversations yet.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                final data = chat.data();
                final parentName = _name(data['parentName'], 'Parent');
                final childName = _name(data['childName'], '');
                final parentId = _name(data['parentId'], '');
                final childId = _name(data['childId'], '');
                final lastMessage = _name(data['lastMessage'], 'Open conversation');
                final updated = data['updatedAt'];
                final time = updated is Timestamp
                    ? TimeOfDay.fromDateTime(updated.toDate().toLocal()).format(context)
                    : '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: yellow,
                        child: Text(parentName[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: purple)),
                      ),
                      title: Row(children: [
                        Expanded(child: Text(parentName,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                        if (time.isNotEmpty) Text(time,
                          style: const TextStyle(fontSize: 10, color: Colors.black45)),
                      ]),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (childName.isNotEmpty) Text('Parent of $childName',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: purple)),
                        const SizedBox(height: 3),
                        Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ]),
                      trailing: const Icon(Icons.chevron_right, color: purple),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => _TherapistConversation(
                          chatId: chat.id, parentId: parentId,
                          childId: childId, parentName: parentName, childName: childName,
                        ),
                      )),
                    ),
                  ),
                );
              },
            );
          },
        )),
      ]),
      bottomNavigationBar: TherapistBottomNav(
        selectedIndex: 1,
        onSelect: (index) {
          if (index == 1) return;
          Widget destination;
          switch (index) {
            case 0:
              destination = const TherapistDashboard();
              break;
            case 2:
              destination = const TherapistPatientsScreen();
              break;
            case 3:
              destination = const TherapistProfileScreen();
              break;
            default:
              return;
          }
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => destination),
          );
        },
      ),
    );
  }
}

class _TherapistConversation extends StatefulWidget {
  final String chatId;
  final String parentId;
  final String childId;
  final String parentName;
  final String childName;
  const _TherapistConversation({
    required this.chatId, required this.parentId, required this.childId,
    required this.parentName, required this.childName,
  });

  @override
  State<_TherapistConversation> createState() => _TherapistConversationState();
}

class _TherapistConversationState extends State<_TherapistConversation> {
  static const purple = Color(0xFF8154AA);
  final TextEditingController controller = TextEditingController();
  bool sending = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final text = controller.text.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (text.isEmpty || text.length > 2000 || uid == null || sending) return;
    setState(() => sending = true);
    try {
      final chat = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
      final message = chat.collection('messages').doc();
      final batch = FirebaseFirestore.instance.batch();
      batch.set(message, {
        'senderId': uid, 'text': text, 'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(chat, {
        'lastMessage': text, 'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      if (mounted) controller.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to send: $e')));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF4),
      appBar: AppBar(
        toolbarHeight: 92,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: purple,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.parentName, style: const TextStyle(fontSize: 19, color: Colors.white, fontWeight: FontWeight.bold)),
          if (widget.childName.isNotEmpty)
            Text('Parent of ${widget.childName}', style: const TextStyle(fontSize: 12, color: Color(0xFFFFEFA8))),
        ]),
      ),
      body: Column(children: [
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 9),
          color: const Color(0xFFFFEFA8),
          child: const Center(child: Text('💜 Every little voice matters',
            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF68458A), fontSize: 12)))),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId)
              .collection('messages').orderBy('createdAt', descending: true)
              .limit(100).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Unable to load messages: ${snapshot.error}'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Center(child: Text('Say hello to the parent! 💜', style: TextStyle(color: Color(0xFF8154AA))));
            return ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                      color: mine ? const Color(0xFFE8D8F4) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(mine ? 20 : 5),
                        bottomRight: Radius.circular(mine ? 5 : 20),
                      ),
                      boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 3))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                       Align(alignment: Alignment.centerLeft, child: Text((data['text'] ?? '').toString(),
                         style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF30233D)))),
                       if (data['createdAt'] is Timestamp) ...[
                         const SizedBox(height: 5),
                         Text(TimeOfDay.fromDateTime((data['createdAt'] as Timestamp).toDate()).format(context),
                           style: const TextStyle(fontSize: 10, color: Color(0xFF84748D))),
                       ],
                     ]),
                  ),
                );
              },
            );
          },
        )),
        SafeArea(top: false, child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Color(0x11000000), blurRadius: 14, offset: Offset(0, -3))]),
          child: Row(children: [
            Expanded(child: TextField(
              controller: controller, maxLength: 2000, minLines: 1, maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Message ${widget.parentName}...', counterText: '',
                filled: true, fillColor: const Color(0xFFFFF8E4),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
            )),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: sending ? null : send,
              style: IconButton.styleFrom(backgroundColor: purple),
              icon: sending
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
