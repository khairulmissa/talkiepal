
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AdminApi {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8001';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Physical Samsung phone
        return 'http://192.168.0.139:8001';

      default:
        return 'http://127.0.0.1:8001';
    }
  }

  // =====================================================
  // GET FIREBASE ADMIN TOKEN
  // =====================================================

  static Future<String> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please login as Admin first.');
    }

    final token = await user.getIdToken(true);

    if (token == null || token.isEmpty) {
      throw Exception(
        'Unable to get Firebase authentication token.',
      );
    }

    return token;
  }

  // =====================================================
  // ADMIN API CALLS
  // =====================================================

  static Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    final token = await _getToken();

    late final String path;
    late final String method;
    late final Map<String, dynamic> body;

    switch (functionName) {
      case 'inviteTherapist':
        path = '/admin/therapists';
        method = 'POST';
        body = {
          'name': data['name'],
          'email': data['email'],
          'password': data['password'],
        };
        break;

      case 'manageAccount':
        final action = data['action']?.toString();
        final uid = data['uid']?.toString();

        if (uid == null || uid.isEmpty) {
          throw Exception('User UID is required.');
        }

        if (action == 'approve') {
          path =
              '/admin/therapists/${Uri.encodeComponent(uid)}/approve';
          method = 'PATCH';
          body = {};
        } else if (action == 'suspend' ||
            action == 'reactivate') {
          path = '/admin/accounts/action';
          method = 'POST';
          body = {
            'uid': uid,
            'action': action,
          };
        } else {
          throw Exception(
            'Action "$action" is not implemented in Python backend yet.',
          );
        }
        break;

      case 'sendAdminNotification':
        path = '/admin/notifications';
        method = 'POST';
        body = {
          'title': data['title'],
          'body': data['body'],
          'audience': data['audience'],
        };
        break;

      default:
        throw Exception(
          'Unknown Admin function: $functionName',
        );
    }

    final uri = Uri.parse('$baseUrl$path');

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      late final http.Response response;

      if (method == 'PATCH') {
        response = await http
            .patch(
              uri,
              headers: headers,
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 30));
      } else {
        response = await http
            .post(
              uri,
              headers: headers,
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 30));
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception('Unexpected server response.');
      }

      final result = Map<String, dynamic>.from(decoded);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        final detail = result['detail'];

        throw Exception(
          detail is String
              ? detail
              : 'Admin request failed (${response.statusCode}).',
        );
      }

      return result;
    } catch (e) {
      throw Exception('Admin API error: $e');
    }
  }

  // =====================================================
  // GET THERAPIST CERTIFICATE FROM ADMIN BACKEND
  // =====================================================

  static Future<String> getTherapistCertificateUrl(
    String therapistUid,
  ) async {
    final token = await _getToken();

    final uri = Uri.parse(
      '$baseUrl/admin/therapists/'
      '${Uri.encodeComponent(therapistUid)}/certificate',
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception('Unexpected server response.');
      }

      if (response.statusCode != 200) {
        throw Exception(
          decoded['detail'] ??
              'Unable to load certificate.',
        );
      }

      final url = decoded['url']?.toString();

      if (url == null || url.isEmpty) {
        throw Exception('Certificate URL missing.');
      }

      return url;
    } catch (e) {
      throw Exception('Certificate API error: $e');
    }
  }

    // =====================================================
  // GET PARENT PROFILE PHOTO FROM PRIVATE SUPABASE
  // =====================================================

  static Future<String?> getParentPhotoUrl(
    String parentUid,
  ) async {
    final token = await _getToken();

    final uri = Uri.parse(
      '$baseUrl/admin/parents/'
      '${Uri.encodeComponent(parentUid)}/photo',
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 404) {
        return null;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception('Unexpected server response.');
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Parent photo request failed (${response.statusCode}): '
          '${decoded['detail'] ?? 'Unknown error'}',
        );
      }

      final url = decoded['url']?.toString();

      if (url == null || url.isEmpty) {
        throw Exception('Parent photo URL missing.');
      }

      return url;
    } catch (e) {
      debugPrint('Parent photo API error: $e');
      rethrow;
    }
  }
  static Future<Map<String, int>> getSystemReport({
    required String type,
    required DateTime start,
    required DateTime end,
  }) async {
    final token = await _getToken();
    String iso(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse('$baseUrl/admin/reports').replace(queryParameters: {
      'type': type,
      'start': iso(start),
      'end': iso(end),
    });
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 60));
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw Exception('Invalid report response');
    if (response.statusCode != 200) {
      throw Exception('Report request failed (${response.statusCode}): ${decoded['detail'] ?? 'Unknown error'}');
    }
    final metrics = decoded['metrics'];
    if (metrics is! Map) throw Exception('Report metrics missing');
    return metrics.map<String, int>((key, value) =>
        MapEntry(key.toString(), (value as num).toInt()));
  }
  static Future<Map<String, dynamic>> _notificationRequest(
  String method, String path, [Map<String, dynamic>? data]
) async {
  final token = await _getToken();
  final uri = Uri.parse('$baseUrl$path');
  final headers = {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
  final http.Response response;
  if (method == 'GET') {
    response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
  } else if (method == 'PATCH') {
    response = await http.patch(uri, headers: headers, body: jsonEncode(data ?? {})).timeout(const Duration(seconds: 30));
  } else {
    response = await http.post(uri, headers: headers, body: jsonEncode(data ?? {})).timeout(const Duration(seconds: 30));
  }
  final decoded = jsonDecode(response.body);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(decoded is Map ? (decoded['detail'] ?? 'HTTP ${response.statusCode}').toString() : 'HTTP ${response.statusCode}');
  }
  if (decoded is! Map) throw Exception('Invalid backend response');
  return Map<String, dynamic>.from(decoded);
}

static Future<List<Map<String, dynamic>>> getNotificationUsers() async {
  final data = await _notificationRequest('GET', '/admin/notifications/users');
  return (data['users'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

static Future<List<Map<String, dynamic>>> getNotificationSchedules() async {
  final data = await _notificationRequest('GET', '/admin/notifications/schedules');
  return (data['schedules'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

static Future<List<Map<String, dynamic>>> getNotificationHistory() async {
  final data = await _notificationRequest('GET', '/admin/notifications/history');
  return (data['history'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
}

static Future<Map<String, dynamic>> sendNotificationToUsers({
  required String title, required String body, required List<String> recipientUids,
}) => _notificationRequest('POST', '/admin/notifications/specific', {
  'title': title, 'body': body, 'recipientUids': recipientUids,
});

static Future<Map<String, dynamic>> createNotificationSchedule(Map<String, dynamic> data) =>
    _notificationRequest('POST', '/admin/notifications/schedules', data);

static Future<Map<String, dynamic>> updateNotificationScheduleStatus(String id, String action) =>
    _notificationRequest('PATCH', '/admin/notifications/schedules/${Uri.encodeComponent(id)}/$action', {});

}
