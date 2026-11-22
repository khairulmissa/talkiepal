import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VideoCallService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<String> startCall({
    required String appointmentId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      throw Exception('Please sign in first.');
    }

    final appointment = await _db
        .collection('appointments')
        .doc(appointmentId)
        .get();

    if (!appointment.exists) {
      throw Exception('Appointment not found.');
    }

    final data = appointment.data()!;

    final parentId = data['parentId'] as String?;
    final therapistId = data['therapistId'] as String?;
    final childId = data['childId'] as String?;
    final status = data['status'] as String?;

    if (parentId == null ||
        therapistId == null ||
        childId == null ||
        !['booked', 'confirmed'].contains(status)) {
      throw Exception('Invalid appointment.');
    }

    if (uid != parentId && uid != therapistId) {
      throw Exception('You are not part of this appointment.');
    }

    final startAt = data['startAt'];
    final endAt = data['endAt'];

    if (startAt is! Timestamp) {
      throw Exception('Appointment time is missing.');
    }

    final start = startAt.toDate();
    final end = endAt is Timestamp
        ? endAt.toDate()
        : start.add(const Duration(hours: 1));

    final now = DateTime.now();

    if (now.isBefore(start) || !now.isBefore(end)) {
      throw Exception('You can only call during the scheduled session.');
    }

    final isParent = uid == parentId;
    final receiverId = isParent ? therapistId : parentId;

    final callRef = _db.collection('video_calls').doc();

    await callRef.set({
      'appointmentId': appointmentId,
      'parentId': parentId,
      'therapistId': therapistId,
      'childId': childId,
      'callerId': uid,
      'callerRole': isParent ? 'parent' : 'therapist',
      'receiverId': receiverId,
      'status': 'ringing',
      'channelName': 'session_$appointmentId',
      'createdAt': FieldValue.serverTimestamp(),
      'answeredAt': null,
      'endedAt': null,
    });

    return callRef.id;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> incomingCalls() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      throw Exception('Please sign in first.');
    }

    return _db
        .collection('video_calls')
        .where('receiverId', isEqualTo: uid)
        .where('status', isEqualTo: 'ringing')
        .snapshots();
  }

  static Future<void> acceptCall(String callId) async {
    await _db.collection('video_calls').doc(callId).update({
      'status': 'accepted',
      'answeredAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> declineCall(String callId) async {
    await _db.collection('video_calls').doc(callId).update({
      'status': 'declined',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> endCall(String callId) async {
    await _db.collection('video_calls').doc(callId).update({
      'status': 'ended',
      'endedAt': FieldValue.serverTimestamp(),
    });
  }
}