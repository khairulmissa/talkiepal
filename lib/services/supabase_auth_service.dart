import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:talkiepal/config/api_config.dart';

class SupabaseAuthService {
  static Future<void> enableSupabaseAccess() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please log in first.');
    }

    // 1. Get the current Firebase ID token
    final token = await user.getIdToken();

    // 2. Send it to your FastAPI backend
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/enable-supabase'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Supabase authentication failed: ${response.body}',
      );
    }

    // 3. Refresh Firebase token to receive the new custom claim
    await user.getIdToken(true);
  }
}