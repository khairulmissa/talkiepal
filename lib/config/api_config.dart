/// Where the TalkiePal AI backend (ai_backend/main.py) is running.
///
/// Change [baseUrl] to match how you run the app:
/// - Android emulator:        'http://10.0.2.2:8000'
/// - Windows / web / iOS sim: 'http://127.0.0.1:8000'
/// - Real phone (same WiFi):  'http://YOUR_LAPTOP_IP:8000', e.g. 'http://192.168.1.10:8000'
///   and start the backend with: uvicorn main:app --host 0.0.0.0 --port 8000
class ApiConfig {
  static const String baseUrl = 'http://192.168.100.210:8000';

  static const String healthUrl = '$baseUrl/health';

  static const String generateExercisesUrl = '$baseUrl/generate-exercises';

  static const String generateQuestionsUrl = '$baseUrl/generate-questions';

  static const String generateMinimalPairsUrl = '$baseUrl/generate-minimal-pairs';
}
