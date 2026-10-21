import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Stores slots at therapists/{uid}/availability_slots/{yyyyMMdd_HHmm_HHmm}.
/// A booking workflow must mark slots as booked using a trusted transaction.
class TherapistScheduleScreen extends StatefulWidget {
  const TherapistScheduleScreen({super.key});

  @override
  State<TherapistScheduleScreen> createState() => _TherapistScheduleScreenState();
}

class _TherapistScheduleScreenState extends State<TherapistScheduleScreen> {
  static const cream = Color(0xFFFFFBF4);
  static const green = Color(0xFFA6D9AC);
  DateTime _selected = DateUtils.dateOnly(DateTime.now());
  bool _working = false;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  CollectionReference<Map<String, dynamic>> get _slots => FirebaseFirestore.instance
      .collection('therapists').doc(_uid).collection('availability_slots');

  String _dateKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}'
      '${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
  String _time(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;
  String _label(String raw) {
    final parts = raw.split(':');
    if (parts.length != 2) return raw;
    final h = int.tryParse(parts[0]) ?? 0;
    return '${h % 12 == 0 ? 12 : h % 12}:${parts[1]} ${h >= 12 ? 'PM' : 'AM'}';
  }

  Future<void> _addSlot() async {
    final start = await showTimePicker(context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0), helpText: 'Start time');
    if (!mounted || start == null) return;
    final end = await showTimePicker(context: context,
        initialTime: TimeOfDay(hour: (start.hour + 1) % 24, minute: start.minute),
        helpText: 'End time');
    if (!mounted || end == null) return;
    if (_minutes(end) <= _minutes(start)) {
      _message('End time must be later than start time.');
      return;
    }
    final now = DateTime.now();
    final startAt = DateTime(_selected.year, _selected.month, _selected.day,
        start.hour, start.minute);
    if (startAt.isBefore(now)) {
      _message('Please select a future time.');
      return;
    }
    setState(() => _working = true);
    try {
      final dayKey = _dateKey(_selected);
      final existing = await _slots.where('dateKey', isEqualTo: dayKey).get();
      final startMin = _minutes(start), endMin = _minutes(end);
      for (final doc in existing.docs) {
        final data = doc.data();
        final oldStart = (data['startMinutes'] as num?)?.toInt();
        final oldEnd = (data['endMinutes'] as num?)?.toInt();
        if (oldStart != null && oldEnd != null && startMin < oldEnd && endMin > oldStart) {
          _message('This time overlaps an existing slot.');
          return;
        }
      }
      final id = '${dayKey}_${_time(start).replaceAll(':', '')}_${_time(end).replaceAll(':', '')}';
      await _slots.doc(id).set({
        'dateKey': dayKey,
        'date': Timestamp.fromDate(DateTime(_selected.year, _selected.month, _selected.day)),
        'startTime': _time(start), 'endTime': _time(end),
        'startMinutes': startMin, 'endMinutes': endMin,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _message('Time slot added.');
    } catch (e) {
      _message('Unable to add slot: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _removeSlot(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    setState(() => _working = true);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final latest = await tx.get(doc.reference);
        if (!latest.exists) return;
        if (latest.data()?['status'] != 'available') {
          throw StateError('Booked slots cannot be removed.');
        }
        tx.delete(doc.reference);
      });
      _message('Time slot removed.');
    } catch (e) {
      _message('Unable to remove slot: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _message(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }


  Widget _todaySessions() {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final nextDay = dayStart.add(const Duration(days: 1));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Today Session', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // Uses the same appointments collection and therapistUid as the dashboard.
        stream: FirebaseFirestore.instance.collection('appointments')
            .where('therapistUid', isEqualTo: _uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Unable to load today sessions. Check Firestore permissions.',
                style: TextStyle(color: Colors.redAccent));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final sessions = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            final start = data['startAt'];
            final status = (data['status'] ?? '').toString().toLowerCase();
            return start is Timestamp &&
                !start.toDate().isBefore(dayStart) && start.toDate().isBefore(nextDay) &&
                status != 'cancelled';
          }).toList()..sort((a, b) =>
              (a.data()['startAt'] as Timestamp).compareTo(b.data()['startAt'] as Timestamp));
          if (sessions.isEmpty) {
            return const Padding(padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No sessions booked for today.'));
          }
          return Column(children: [
            for (final session in sessions) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(25)),
                child: Row(children: [
                  CircleAvatar(radius: 19, backgroundColor: const Color(0xFFFFEFA8),
                    child: Text((session.data()['childName'] ?? 'P').toString().substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.black87))),
                  const SizedBox(width: 9),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text((session.data()['childName'] ?? 'Patient').toString(),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(TimeOfDay.fromDateTime((session.data()['startAt'] as Timestamp).toDate())
                        .format(context), style: const TextStyle(fontSize: 11)),
                  ])),
                  _sessionAction(Icons.chat_bubble_outline, 'Chat'),
                  const SizedBox(width: 5),
                  _sessionAction(Icons.videocam, 'Video call'),
                ]),
              ),
            ],
          ]);
        },
      ),
    ]);
  }

  Widget _sessionAction(IconData icon, String feature) => Material(
    color: const Color(0xFF85C99A), shape: const CircleBorder(),
    child: IconButton(icon: Icon(icon, size: 20), constraints: const BoxConstraints(
      minWidth: 38, minHeight: 38), padding: EdgeInsets.zero,
      tooltip: feature,
      onPressed: () => _message('$feature page is not connected yet.'),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final key = _dateKey(_selected);
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Schedule'), backgroundColor: cream),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _todaySessions(),
        const SizedBox(height: 22),
        const Row(children: [Text('Manage Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4C9164))), SizedBox(width: 6), Icon(Icons.calendar_month, size: 19)]),
        const SizedBox(height: 16),
        const Text('Select Date:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 8),
        Card(color: Colors.white, child: CalendarDatePicker(
          initialDate: _selected,
          firstDate: DateUtils.dateOnly(DateTime.now()),
          lastDate: DateTime(DateTime.now().year + 2),
          onDateChanged: (day) => setState(() => _selected = day),
        )),
        const SizedBox(height: 20),
        const Text('Set time:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _slots.where('dateKey', isEqualTo: key).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Text('Unable to load schedule: ${snapshot.error}');
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs.toList()
              ..sort((a, b) => ((a.data()['startMinutes'] as num?) ?? 0)
                  .compareTo((b.data()['startMinutes'] as num?) ?? 0));
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                if (docs.isEmpty) const Padding(
                  padding: EdgeInsets.all(12), child: Text('No time slots for this date.')),
                for (final doc in docs)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text('${_label(doc.data()['startTime']?.toString() ?? '')} – '
                        '${_label(doc.data()['endTime']?.toString() ?? '')}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: doc.data()['status'] == 'booked'
                        ? const Text('🔒 Booked')
                        : TextButton(
                            onPressed: _working ? null : () => _removeSlot(doc),
                            child: const Text('Remove', style: TextStyle(color: Colors.black87))),
                  ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: _working ? null : _addSlot,
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text('Add Slot Time', style: TextStyle(color: Colors.black)),
                ),
              ]),
            );
          },
        ),
      ]),
    );
  }
}
