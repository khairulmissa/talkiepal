import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:talkiepal/config/api_config.dart';

const Duration _healthTimeout = Duration(seconds: 3);
const Duration _requestTimeout = Duration(seconds: 150);

/// Sends a JSON request to the AI backend and returns the decoded reply.
///
/// A quick health check runs first so the app fails fast when the backend
/// is unreachable. Throws on timeout or a non-200 response.
Future<dynamic> postToBackend(String url, Map<String, dynamic> body) async {
  await http.get(Uri.parse(ApiConfig.healthUrl)).timeout(_healthTimeout);

  final response = await http
      .post(Uri.parse(url), headers: const {'Content-Type': 'application/json'}, body: jsonEncode(body))
      .timeout(_requestTimeout);

  if (response.statusCode != 200) {
    throw Exception('Backend error ${response.statusCode}');
  }

  return jsonDecode(utf8.decode(response.bodyBytes));
}