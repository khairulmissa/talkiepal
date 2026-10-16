import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:talkiepal/config/api_config.dart';

/// Sends a JSON request to the AI backend and returns the decoded reply.
/// Throws if the backend cannot be reached or returns an error.
Future<dynamic> postToBackend(String url, Map<String, dynamic> body) async {
  // Quick check first, so the app does not wait long when the
  // backend cannot be reached (wrong IP, laptop off, other WiFi).
  await http.get(Uri.parse(ApiConfig.healthUrl)).timeout(const Duration(seconds: 3));

  final response = await http
      .post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      )
      .timeout(const Duration(seconds: 150));

  if (response.statusCode != 200) {
    throw Exception('Backend error ${response.statusCode}');
  }

  return jsonDecode(utf8.decode(response.bodyBytes));
}
