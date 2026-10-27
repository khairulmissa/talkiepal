import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Parent-only, live list of appointments for the selected child.
class ParentUpcomingAppointments extends StatefulWidget {
  final String? childId;
  final String? therapistId;
  final int limit;
  final Future<void> Function(BuildContext context, String appointmentId)? onJoinCall;

  const ParentUpcomingAppointments({
    super.key,
    this.childId,
    this.therapistId,
    this.limit = 5,
    this.onJoinCall,
  });

  @override
  State<ParentUpcomingAppointments> createState() =>
      _ParentUpcomingAppointmentsState();
}

class _ParentUpcomingAppointmentsState extends State<ParentUpcomingAppointments> {
  static const Color purple = Color(0xFF8154AA);
  Timer? _clock;
  DateTime _now = DateTime.now();
  String? _joiningId;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  String _format(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year} · '
        '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  Future<void> _joinCall(String appointmentId) async {
    if (_joiningId != null || widget.onJoinCall == null) return;
    setState(() => _joiningId = appointmentId);
    try {
      await widget.onJoinCall!(context, appointmentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to join video call: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _joiningId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Text('Please sign in to view sessions.');
    if (widget.childId == null || widget.childId!.isEmpty) {
      return const Text('Select a child to see their appointments.');
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('parentId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Cannot load appointments: ${snapshot.error}',
              style: const TextStyle(color: Colors.red, fontSize: 12));
        }
        if (!snapshot.hasData) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          ));
        }

        final docs = snapshot.data!.docs.where((doc) {
          final a = doc.data();
          if (a['childId'] != widget.childId) return false;
          if (widget.therapistId != null &&
              a['therapistId'] != widget.therapistId) return false;
          if (a['status'] != 'booked' && a['status'] != 'confirmed') {
            return false;
          }
          final start = a['startAt'];
          if (start is! Timestamp) return false;
          final end = a['endAt'];
          final endsAt = end is Timestamp
              ? end.toDate()
              : start.toDate().add(const Duration(hours: 1));
          return endsAt.isAfter(_now);
        }).toList()
          ..sort((a, b) =>
              (a.data()['startAt'] as Timestamp)
                  .compareTo(b.data()['startAt'] as Timestamp));

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No upcoming sessions booked.',
                style: TextStyle(fontSize: 12.5)),
          );
        }

        return Column(
          children: [
            for (final doc in docs.take(widget.limit))
              _appointmentTile(doc),
          ],
        );
      },
    );
  }

  Widget _appointmentTile(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final a = doc.data();
    final start = (a['startAt'] as Timestamp).toDate();
    final end = a['endAt'] is Timestamp
        ? (a['endAt'] as Timestamp).toDate()
        : start.add(const Duration(hours: 1));
    final canJoin = !_now.isBefore(start) && _now.isBefore(end);
    final joining = _joiningId == doc.id;
    final duration = end.difference(start).inMinutes;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          const Icon(Icons.event_available, color: purple, size: 23),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_format(start),
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text('${a['therapistName'] ?? 'Therapist'} · '
                    '${a['childName'] ?? 'Child'}',
                    style: const TextStyle(fontSize: 11.5,
                        color: Colors.black54)),
                Text('${a['status'] == 'confirmed' ? 'Confirmed' : 'Booked'}'
                    ' · $duration minutes',
                    style: const TextStyle(fontSize: 11, color: purple)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 100,
            child: FilledButton.icon(
              onPressed: canJoin && !joining && _joiningId == null &&
                      widget.onJoinCall != null
                  ? () => _joinCall(doc.id)
                  : null,
              icon: joining
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.videocam_rounded, size: 17),
              label: Text(joining ? 'Joining' : canJoin ? 'Join' : 'Not Yet',
                  style: const TextStyle(fontSize: 11)),
              style: FilledButton.styleFrom(
                backgroundColor: purple,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
