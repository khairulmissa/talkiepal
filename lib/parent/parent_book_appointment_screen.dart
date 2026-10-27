import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ParentBookAppointmentScreen extends StatefulWidget {
  final String therapistId;
  final String therapistName;
  final String childId;
  final String childName;

  const ParentBookAppointmentScreen({
    super.key,
    required this.therapistId,
    required this.therapistName,
    required this.childId,
    required this.childName,
  });

  @override
  State<ParentBookAppointmentScreen> createState() =>
      _ParentBookAppointmentScreenState();
}

class _ParentBookAppointmentScreenState extends State<ParentBookAppointmentScreen> {
  static const purple = Color(0xFF8154AA);
  static const cream = Color(0xFFFFFBF4);
  static const yellow = Color(0xFFFFEFA8);
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  DateTime _day = DateUtils.dateOnly(DateTime.now());
  bool _booking = false;

  String get _dateKey =>
      '${_day.year.toString().padLeft(4, '0')}-${_day.month.toString().padLeft(2, '0')}-${_day.day.toString().padLeft(2, '0')}';

  String _label(int hour) => hour == 24
      ? '12:00 AM next day'
      : '${hour % 12 == 0 ? 12 : hour % 12}:00 ${hour >= 12 ? 'PM' : 'AM'}';

  String _slotId(int hour) =>
      '${widget.therapistId}_${_dateKey.replaceAll('-', '')}_${hour.toString().padLeft(2, '0')}00';

  DocumentReference<Map<String, dynamic>> get _availability => _db
      .collection('therapists')
      .doc(widget.therapistId)
      .collection('availability')
      .doc(_dateKey);

  DocumentReference<Map<String, dynamic>> _slot(int hour) => _db
      .collection('therapists')
      .doc(widget.therapistId)
      .collection('availability_slots')
      .doc(_slotId(hour));

  void _notice(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _book(int hour) async {
    if (_booking) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _notice('Please sign in first.');
      return;
    }
    final selectedDay = _day;
    final dateKey = _dateKey;
    final start = DateTime(selectedDay.year, selectedDay.month, selectedDay.day, hour);
    final end = start.add(const Duration(hours: 1));
    if (!start.isAfter(DateTime.now())) {
      _notice('Please select a future time. Check your emulator clock.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm appointment?'),
        content: Text('${widget.therapistName}\nChild: ${widget.childName}\n$dateKey\n${_label(hour)} – ${_label(hour + 1)}\nDuration: 60 minutes'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _booking = true);

    try {
      final childRef = _db.collection('users').doc(user.uid)
          .collection('children').doc(widget.childId);
      final slotRef = _slot(hour);
      final appointmentRef = _db.collection('appointments').doc(_slotId(hour));
      final availabilityRef = _availability;

      await _db.runTransaction((tx) async {
        // All reads occur before writes. The server rules independently
        // validate the assignment, slot, schedule and appointment time.
        final childSnap = await tx.get(childRef);
        final availabilitySnap = await tx.get(availabilityRef);
        final slotSnap = await tx.get(slotRef);

        if (!childSnap.exists) {
          throw StateError('Child profile not found.');
        }
        final child = childSnap.data() ?? {};
        final assigned = child['primaryTherapistId'] ?? child['assignedTherapistId'];
        if (assigned != widget.therapistId) {
          throw StateError('This therapist is not assigned to this child.');
        }
        final schedule = availabilitySnap.data() ?? {};
        final mode = schedule['mode'] ?? 'default';
        if (mode == 'off') throw StateError('Therapist is unavailable that day.');
        if (mode == 'custom') {
          final first = schedule['startHour'];
          final last = schedule['endHour'];
          if (first is! int || last is! int || hour < first || hour + 1 > last) {
            throw StateError('Outside therapist working hours.');
          }
        }
        if (slotSnap.exists) {
          throw StateError('This time is already reserved.');
        }
        if (!start.isAfter(DateTime.now())) {
          throw StateError('The selected time has passed.');
        }

        // A new slot and a new appointment must be created together.
        // Firestore rules deny overwriting an existing appointment.
        tx.set(appointmentRef, {
          'parentId': user.uid,
          'parentName': user.displayName ?? 'Parent',
          'therapistId': widget.therapistId,
          'therapistUid': widget.therapistId,
          'childId': widget.childId,
          'childName': widget.childName,
          'therapistName': widget.therapistName,
          'dateKey': dateKey,
          'startTime': '${hour.toString().padLeft(2, '0')}:00',
          'endTime': '${(hour + 1).toString().padLeft(2, '0')}:00',
          'startAt': Timestamp.fromDate(start),
          'endAt': Timestamp.fromDate(end),
          'durationMinutes': 60,
          'status': 'booked',
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.set(slotRef, {
          'dateKey': dateKey,
          'startHour': hour,
          'status': 'booked',
        });
      });
      if (!mounted) return;
      _notice('Appointment booked successfully!');
      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      debugPrint('BOOKING FIRESTORE ERROR: ${e.code}: ${e.message}');
      _notice('Booking failed: ${e.message ?? e.code}');
    } catch (e) {
      debugPrint('BOOKING ERROR: $e');
      _notice('Booking failed: $e');
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  Widget _hourTile(int hour) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        key: ValueKey(_slotId(hour)),
        stream: _slot(hour).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('SLOT READ ERROR: ${snapshot.error}');
          }
          final error = snapshot.hasError;
          final loading = !snapshot.hasData && !error;
          // Any existing slot document reserves the hour.
          final booked = snapshot.data?.exists == true;
          final canBook = !error && !loading && !booked && !_booking;
          return Card(
            color: booked ? const Color(0xFFF1EEF3) : Colors.white,
            child: ListTile(
              leading: Icon(booked ? Icons.lock_outline : Icons.access_time, color: purple),
              title: Text('${_label(hour)} – ${_label(hour + 1)}'),
              subtitle: Text(error
                  ? 'Cannot check slot permissions'
                  : loading
                      ? 'Checking...'
                      : booked
                          ? 'Already booked'
                          : 'Available · 60 minutes'),
              trailing: FilledButton(
                onPressed: canBook ? () => _book(hour) : null,
                style: FilledButton.styleFrom(backgroundColor: purple),
                child: Text(booked ? 'Booked' : 'Book'),
              ),
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: cream,
        appBar: AppBar(
          title: const Text('Book Appointment'),
          backgroundColor: purple,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: yellow,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.therapistName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Child: ${widget.childName}'),
                    const SizedBox(height: 6),
                    const Text('Each appointment lasts exactly 60 minutes.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            CalendarDatePicker(
              key: ValueKey('${_day.year}-${_day.month}'),
              initialDate: _day,
              firstDate: DateUtils.dateOnly(DateTime.now()),
              lastDate: DateUtils.dateOnly(DateTime.now().add(const Duration(days: 90))),
              onDateChanged: (value) => setState(() => _day = value),
            ),
            const SizedBox(height: 18),
            const Text('Available 1-hour slots',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: purple)),
            const SizedBox(height: 12),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              key: ValueKey('availability_$_dateKey'),
              stream: _availability.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Cannot load therapist availability: ${snapshot.error}');
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final schedule = snapshot.data!.data() ?? {};
                final mode = schedule['mode'] ?? 'default';
                if (mode == 'off') return const Text('Therapist is unavailable on this date.');
                final from = mode == 'custom' ? (schedule['startHour'] as int? ?? 10) : 0;
                final until = mode == 'custom' ? (schedule['endHour'] as int? ?? 22) : 24;
                final hours = [
                  for (var hour = from; hour < until; hour++)
                    if (hour >= 0 && hour < 24 &&
                        DateTime(_day.year, _day.month, _day.day, hour)
                            .isAfter(DateTime.now()))
                      hour,
                ];
                if (hours.isEmpty) return const Text('No future slots on this date.');
                return Column(children: [for (final hour in hours) _hourTile(hour)]);
              },
            ),
          ],
        ),
      );
}
