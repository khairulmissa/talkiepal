import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../parent/parent_video_call_screen.dart';
import 'therapist_ui.dart';

/// Therapist schedule: appointments first, then date-specific availability.
/// Existing appointments are not changed when availability is saved.
class TherapistScheduleScreen extends StatefulWidget {
  const TherapistScheduleScreen({super.key});

  @override
  State<TherapistScheduleScreen> createState() => _TherapistScheduleScreenState();
}

class _TherapistScheduleScreenState extends State<TherapistScheduleScreen> {
  static const purple = TherapistColors.purple;
  static const ink = TherapistColors.text;
  static const muted = TherapistColors.muted;
  DateTime _selected = DateUtils.dateOnly(DateTime.now());
  String _mode = 'default';
  int _startHour = 10;
  int _endHour = 22;
  String? _loadedKey;
  bool _saving = false;
  bool _joining = false;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  String _key(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _label(int h) => h == 24 ? '12 AM next day' : '${h % 12 == 0 ? 12 : h % 12}:00 ${h >= 12 ? 'PM' : 'AM'}';
  String _dateLabel(DateTime d) => '${['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d.weekday - 1]}, ${d.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.month - 1]} ${d.year}';
  DocumentReference<Map<String, dynamic>> get _availability => FirebaseFirestore.instance
      .collection('therapists').doc(_uid).collection('availability').doc(_key(_selected));

  void _notice(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _load(Map<String, dynamic>? data, String key) {
    if (_loadedKey == key) return;
    _loadedKey = key;
    _mode = data?['mode'] == 'custom' || data?['mode'] == 'off' ? data!['mode'] as String : 'default';
    final a = data?['startHour'];
    final b = data?['endHour'];
    _startHour = a is int && a >= 0 && a <= 23 ? a : 10;
    _endHour = b is int && b >= 1 && b <= 24 ? b : 22;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_mode == 'custom' && _endHour <= _startHour) {
      _notice('End time must be later than start time.');
      return;
    }
    setState(() => _saving = true);
    try {
      final db = FirebaseFirestore.instance;
      final dayKey = _key(_selected);
      final booked = await db.collection('appointments')
          .where('therapistId', isEqualTo: _uid).get();
      for (final doc in booked.docs) {
        final d = doc.data();
        if (d['dateKey'] != dayKey || d['status'] == 'cancelled') continue;
        final start = d['startAt'];
        if (start is! Timestamp) continue;
        final hour = start.toDate().toLocal().hour;
        if (_mode == 'off' || (_mode == 'custom' &&
            (hour < _startHour || hour + 1 > _endHour))) {
          _notice('This change conflicts with an existing booking. Reschedule that session first.');
          return;
        }
      }
      if (_mode == 'default') {
        await _availability.delete();
      } else {
        await _availability.set({
          'dateKey': dayKey,
          'mode': _mode,
          'startHour': _mode == 'custom' ? _startHour : 0,
          'endHour': _mode == 'custom' ? _endHour : 24,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      _notice('Availability saved successfully.');
    } catch (e) {
      _notice('Unable to save availability: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _chat(Map<String, dynamic> appointment) async {
    final parentId = (appointment['parentId'] ?? '').toString();
    final childId = (appointment['childId'] ?? '').toString();
    if (parentId.isEmpty || childId.isEmpty) {
      _notice('This booking is missing its parent or child ID.');
      return;
    }
    final chatId = '${parentId}_${childId}_$_uid';
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    try {
      // Existing chat rules allow the parent to create the conversation.
      if (!(await chatRef.get()).exists) {
        _notice('No chat started yet. Ask the parent to send the first message.');
        return;
      }
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => _AppointmentChatScreen(chatId: chatId,
            childName: (appointment['childName'] ?? 'Child').toString()),
      ));
    } catch (e) {
      _notice('Unable to open chat: $e');
    }
  }

  Future<void> _video(String appointmentId, Map<String, dynamic> appointment) async {
    if (_joining) return;
    final start = appointment['startAt'];
    final end = appointment['endAt'];
    final now = DateTime.now();
    if (start is! Timestamp || end is! Timestamp ||
        now.isBefore(start.toDate()) || !now.isBefore(end.toDate())) {
      _notice('Video call is available only during the booked session.');
      return;
    }
    setState(() => _joining = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Please sign in.');
      final idToken = await user.getIdToken();
      if (idToken == null) throw StateError('Cannot get Firebase login token.');
      // Android Emulator -> local FastAPI server. Use HTTPS for production.
      final url = Uri.parse('http://10.0.2.2:8000/agora/token/${Uri.encodeComponent(appointmentId)}');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $idToken'})
          .timeout(const Duration(seconds: 15));
      final body = jsonDecode(response.body);
      if (response.statusCode != 200) {
        throw StateError(body is Map ? (body['detail'] ?? 'Token request failed').toString() : 'Token request failed');
      }
      if (body is! Map<String, dynamic> || body['appId'] is! String ||
          body['token'] is! String || body['channelName'] is! String || body['uid'] is! int) {
        throw const FormatException('Invalid Agora token response');
      }
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => ParentVideoCallScreen(
        appId: body['appId'] as String,
        token: body['token'] as String,
        channelName: body['channelName'] as String,
        uid: body['uid'] as int,
        therapistName: (appointment['childName'] ?? 'Therapy session').toString(),
      )));
    } catch (e) {
      _notice('Cannot join video call: $e');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Widget _heading(String title, IconData icon, {String? subtitle}) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: const Color(0xFFF0E5F8), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: purple, size: 19)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ink)),
        if (subtitle != null) Text(subtitle, style: const TextStyle(color: muted, fontSize: 11)),
      ])),
    ]),
  );

  Widget _appointments(String dateKey) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance.collection('appointments')
        .where('therapistId', isEqualTo: _uid).snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return TherapistCard(child: Text('Unable to load bookings: ${snapshot.error}'));
      if (!snapshot.hasData) return const TherapistCard(child: Center(child: CircularProgressIndicator()));
      final bookings = snapshot.data!.docs.where((d) {
        final data = d.data();
        return data['dateKey'] == dateKey && data['status'] != 'cancelled';
      }).toList()..sort((a, b) {
        final x = a.data()['startAt'];
        final y = b.data()['startAt'];
        return x is Timestamp && y is Timestamp ? x.compareTo(y) : 0;
      });
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _heading('Booked sessions', Icons.people_alt_outlined,
            subtitle: '${bookings.length} appointment${bookings.length == 1 ? '' : 's'} on ${_dateLabel(_selected)}'),
        if (bookings.isEmpty)
          const TherapistCard(child: Padding(padding: EdgeInsets.symmetric(vertical: 13),
            child: Center(child: Text('No appointments booked for this date yet.',
              style: TextStyle(color: muted, fontSize: 12)))))
        else
          for (final doc in bookings) ...[
            TherapistCard(child: Row(children: [
              const CircleAvatar(radius: 23, backgroundColor: Color(0xFFFFEFA8),
                child: Icon(Icons.child_care_rounded, color: purple)),
              const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text((doc.data()['parentName'] ?? 'Parent').toString(),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                Text('Child: ${doc.data()['childName'] ?? 'Unknown'}',
                  style: const TextStyle(color: muted, fontSize: 11)),
                const SizedBox(height: 4),
                Text(_sessionTime(doc.data()), style: const TextStyle(color: purple,
                  fontSize: 11, fontWeight: FontWeight.w700)),
              ])),
              _roundAction(Icons.chat_bubble_outline_rounded, 'Parent chat',
                () => _chat(doc.data())),
              const SizedBox(width: 5),
              _roundAction(Icons.videocam_outlined, 'Video call',
                _joining ? null : () => _video(doc.id, doc.data())),
            ])),
            const SizedBox(height: 9),
          ],
      ]);
    },
  );

  String _sessionTime(Map<String, dynamic> data) {
    final a = data['startAt'];
    final b = data['endAt'];
    if (a is Timestamp && b is Timestamp) {
      return '${TimeOfDay.fromDateTime(a.toDate().toLocal()).format(context)} – ${TimeOfDay.fromDateTime(b.toDate().toLocal()).format(context)}';
    }
    return '${data['startTime'] ?? '--'} – ${data['endTime'] ?? '--'}';
  }

  Widget _roundAction(IconData icon, String tooltip, VoidCallback? onPressed) =>
    Material(color: const Color(0xFFF1E8F8), shape: const CircleBorder(),
      child: IconButton(tooltip: tooltip, onPressed: onPressed,
        icon: Icon(icon, color: purple, size: 19), constraints: const BoxConstraints(minWidth: 39, minHeight: 39),
        padding: EdgeInsets.zero));

  Widget _availabilityPanel(String dateKey) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    key: ValueKey(dateKey), stream: _availability.snapshots(),
    builder: (context, availabilitySnapshot) {
      if (availabilitySnapshot.hasError) return TherapistCard(child: Text('Cannot load availability: ${availabilitySnapshot.error}'));
      if (!availabilitySnapshot.hasData) return const TherapistCard(child: Center(child: CircularProgressIndicator()));
      _load(availabilitySnapshot.data!.data(), dateKey);
      final first = _mode == 'off' ? 0 : _mode == 'custom' ? _startHour : 0;
      final last = _mode == 'off' ? 0 : _mode == 'custom' ? _endHour : 24;
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('appointments')
            .where('therapistId', isEqualTo: _uid).snapshots(),
        builder: (context, appointmentSnapshot) {
          final bookings = (appointmentSnapshot.data?.docs ?? []).where((d) =>
            d.data()['dateKey'] == dateKey && d.data()['status'] != 'cancelled').toList();
          final occupied = <int>{};
          for (final doc in bookings) {
            final start = doc.data()['startAt'];
            if (start is Timestamp) occupied.add(start.toDate().toLocal().hour);
          }
          final hours = [for (var h = first; h < last; h++) h];
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _heading('Availability for this date', Icons.access_time_rounded,
              subtitle: _mode == 'off' ? 'Day off / Unavailable' :
                _mode == 'default' ? 'Whole day · Default schedule' :
                '${_label(_startHour)} – ${_label(_endHour)}'),
            TherapistCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _miniStat('${hours.length}', 'Total slots'),
                _miniStat('${occupied.length}', 'Booked'),
                _miniStat('${hours.where((h) => !occupied.contains(h)).length}', 'Free'),
              ]),
              const Divider(height: 27),
              if (appointmentSnapshot.hasError)
                Text('Unable to check occupied times: ${appointmentSnapshot.error}',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12))
              else if (!appointmentSnapshot.hasData)
                const Center(child: CircularProgressIndicator())
              else if (hours.isEmpty)
                const Text('Dr Sarah is unavailable on this date.', style: TextStyle(color: muted))
              else
                LayoutBuilder(builder: (context, constraints) {
                  final width = (constraints.maxWidth - 16) / 3;
                  return Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final hour in hours)
                      Container(width: width, padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
                        decoration: BoxDecoration(
                          color: occupied.contains(hour) ? const Color(0xFFF0EDF2) : const Color(0xFFF8F2FC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: occupied.contains(hour) ? const Color(0xFFE4DFE7) : const Color(0xFFD7BEEA))),
                        child: Column(children: [
                          Text(_label(hour), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(occupied.contains(hour) ? 'Booked' : 'Available',
                            style: TextStyle(fontSize: 10,
                              color: occupied.contains(hour) ? muted : const Color(0xFF228363))),
                        ])),
                  ]);
                }),
            ])),
            const SizedBox(height: 17),
            _heading('Manage working hours', Icons.edit_calendar_outlined),
            TherapistCard(color: const Color(0xFFFFF0B5), child: Column(children: [
              _option('default', 'Whole day (default)', '00:00 – 24:00 · 24 one-hour slots'),
              _option('custom', 'Custom working hours', 'Choose the start and end time'),
              if (_mode == 'custom') Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Row(children: [
                  Expanded(child: DropdownButtonFormField<int>(
                    value: _startHour, isExpanded: true,
                    decoration: const InputDecoration(labelText: 'From', filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder()),
                    items: [for (var h = 0; h < 24; h++) DropdownMenuItem(value: h, child: Text(_label(h), style: const TextStyle(fontSize: 12)))],
                    onChanged: (v) { if (v != null) setState(() => _startHour = v); },
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: DropdownButtonFormField<int>(
                    value: _endHour, isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Until', filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder()),
                    items: [for (var h = 1; h <= 24; h++) DropdownMenuItem(value: h,
                      child: Text(_label(h), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)))],
                    onChanged: (v) { if (v != null) setState(() => _endHour = v); },
                  )),
                ])),
              _option('off', 'Day off / Not available', 'Parents cannot book new sessions'),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: Text(_saving ? 'Saving...' : 'Save availability'),
                style: FilledButton.styleFrom(backgroundColor: purple, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
              )),
            ])),
          ]);
        },
      );
    },
  );

  Widget _miniStat(String number, String title) => Column(children: [
    Text(number, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: ink)),
    Text(title, style: const TextStyle(fontSize: 10, color: muted)),
  ]);

  Widget _option(String mode, String title, String subtitle) => InkWell(
    onTap: () => setState(() => _mode = mode),
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
      Radio<String>(value: mode, groupValue: _mode, activeColor: purple,
        onChanged: (v) { if (v != null) setState(() => _mode = v); }),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        Text(subtitle, style: const TextStyle(color: muted, fontSize: 10)),
      ])),
    ])),
  );

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please sign in.')));
    }
    final dateKey = _key(_selected);
    return Scaffold(
      backgroundColor: TherapistColors.background,
      appBar: AppBar(title: const Text('Manage Availability',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        backgroundColor: TherapistColors.background, foregroundColor: ink),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 28), children: [
        Container(padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF966ABB), Color(0xFF65408B)]),
            borderRadius: BorderRadius.circular(23)),
          child: const Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('THERAPIST SCHEDULE', style: TextStyle(color: Color(0xFFEFE2F8), fontSize: 10, letterSpacing: 1)),
              SizedBox(height: 7),
              Text('Your appointments 💜', style: TextStyle(color: Colors.white,
                fontSize: 20, fontWeight: FontWeight.w800)),
              SizedBox(height: 5),
              Text('Manage bookings and working hours in one place.',
                style: TextStyle(color: Color(0xFFF0E5F6), fontSize: 11)),
            ])),
            Icon(Icons.calendar_month_rounded, color: Colors.white, size: 40),
          ])),
        const SizedBox(height: 19),
        _appointments(dateKey),
        const SizedBox(height: 17),
        _heading('Choose a date', Icons.calendar_today_outlined,
          subtitle: 'Tap a date to see its bookings and availability'),
        TherapistCard(padding: const EdgeInsets.all(7), child: CalendarDatePicker(
          key: ValueKey('${_selected.year}-${_selected.month}'),
          initialDate: _selected,
          firstDate: DateUtils.dateOnly(DateTime.now()),
          lastDate: DateTime(DateTime.now().year + 2),
          onDateChanged: (day) => setState(() { _selected = day; _loadedKey = null; }),
        )),
        const SizedBox(height: 18),
        _availabilityPanel(dateKey),
        const SizedBox(height: 12),
        const Text('A date without saved hours uses whole-day availability. Booked sessions remain reserved.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: muted)),
      ]),
    );
  }
}

/// Conversation for the specific parent/child attached to a booking.
class _AppointmentChatScreen extends StatefulWidget {
  final String chatId;
  final String childName;
  const _AppointmentChatScreen({required this.chatId, required this.childName});
  @override
  State<_AppointmentChatScreen> createState() => _AppointmentChatScreenState();
}

class _AppointmentChatScreenState extends State<_AppointmentChatScreen> {
  final _controller = TextEditingController();
  bool _sending = false;
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (text.isEmpty || uid == null || _sending || text.length > 2000) return;
    setState(() => _sending = true);
    try {
      final chat = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
      final batch = FirebaseFirestore.instance.batch();
      batch.set(chat.collection('messages').doc(), {
        'senderId': uid, 'text': text, 'createdAt': FieldValue.serverTimestamp(),
      });
      batch.update(chat, {'lastMessage': text, 'updatedAt': FieldValue.serverTimestamp()});
      await batch.commit();
      _controller.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot send message: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: TherapistColors.background,
    appBar: AppBar(title: Text('Parent Chat · ${widget.childName}'),
      backgroundColor: TherapistColors.background),
    body: Column(children: [
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId)
          .collection('messages').orderBy('createdAt').snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Unable to load messages: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final messages = snap.data!.docs;
          if (messages.isEmpty) return const Center(child: Text('No messages yet.'));
          final uid = FirebaseAuth.instance.currentUser?.uid;
          return ListView.builder(padding: const EdgeInsets.all(14), itemCount: messages.length,
            itemBuilder: (context, index) {
              final data = messages[index].data();
              final mine = data['senderId'] == uid;
              return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .77),
                  decoration: BoxDecoration(color: mine ? const Color(0xFFEAD9F7) : Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                  child: Text((data['text'] ?? '').toString())));
            });
        },
      )),
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
        Expanded(child: TextField(controller: _controller, maxLines: 3, minLines: 1,
          decoration: InputDecoration(hintText: 'Message parent...', filled: true,
            fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24))))),
        const SizedBox(width: 8),
        IconButton.filled(onPressed: _sending ? null : _send,
          style: IconButton.styleFrom(backgroundColor: TherapistColors.purple),
          icon: const Icon(Icons.send_rounded)),
      ]))),
    ]),
  );
}

