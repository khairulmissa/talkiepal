import 'dart:math' as math;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Uses the same child profile, practiceSessions and therapistFeedback documents
// as the parent-facing report. The signed image URL must be provided by the
// therapist-authorized backend, not by an unrestricted Supabase public URL.
const _purple = PdfColor.fromInt(0xFF8154AA);
const _dark = PdfColor.fromInt(0xFF30243D);
const _muted = PdfColor.fromInt(0xFF71687B);
const _pale = PdfColor.fromInt(0xFFF4EDF8);
const _line = PdfColor.fromInt(0xFFE8DDED);

String _value(dynamic v, [String fallback = 'Not recorded']) {
  final t = v?.toString().trim() ?? '';
  return t.isEmpty ? fallback : t;
}
DateTime? _date(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
String _formatDate(dynamic v) {
  final d = _date(v);
  return d == null ? 'Not recorded' : '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
}
num? _score(dynamic v) {
  if (v is num) return v;
  return num.tryParse(v?.toString() ?? '');
}
pw.Widget _section(String title) => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 17, bottom: 9),
  child: pw.Text(title, style: pw.TextStyle(fontSize: 14, color: _purple, fontWeight: pw.FontWeight.bold)),
);
pw.Widget _metric(String label, String value) => pw.Expanded(
  child: pw.Container(
    margin: const pw.EdgeInsets.only(right: 7),
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(color: _pale, borderRadius: pw.BorderRadius.circular(9)),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(value, style: pw.TextStyle(fontSize: 16, color: _purple, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 3),
      pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _muted)),
    ]),
  ),
);
pw.Widget _scoreBar(String title, num score) {
  final safe = score.toDouble().clamp(0.0, 100.0);
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 10),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Expanded(child: pw.Text(title, style: const pw.TextStyle(fontSize: 10, color: _dark))),
        pw.Text('${safe.toStringAsFixed(0)}/100', style: pw.TextStyle(fontSize: 10, color: _purple)),
      ]),
      pw.SizedBox(height: 4),
      pw.Stack(children: [
        pw.Container(height: 8, width: 450, color: _line),
        pw.Container(height: 8, width: 450 * safe / 100, color: _purple),
      ]),
    ]),
  );
}

Future<void> generateTherapistProgressPdf({
  required String parentId,
  required String childId,
  required String fallbackChildName,
  required String parentName,
}) async {
  if (FirebaseAuth.instance.currentUser == null) {
    throw StateError('Sign in as a therapist first.');
  }
  final firestore = FirebaseFirestore.instance;
  final childRef = firestore.collection('users').doc(parentId).collection('children').doc(childId);
  // Firestore rules must allow this therapist to read the assigned child's data.
  final childDoc = await childRef.get();
  if (!childDoc.exists) throw StateError('Child profile not found or access denied.');
  final child = childDoc.data()!;
  final practice = await childRef.collection('practiceSessions').get();
  final feedback = await childRef.collection('therapistFeedback').get();
  final sessions = practice.docs.map((d) => d.data()).toList()
    ..sort((a,b) => (_date(a['finishedAt']) ?? DateTime(1970)).compareTo(_date(b['finishedAt']) ?? DateTime(1970)));
  final comments = feedback.docs.map((d) => d.data()).toList()
    ..sort((a,b) => (_date(b['createdAt']) ?? DateTime(1970)).compareTo(_date(a['createdAt']) ?? DateTime(1970)));
  final scores = sessions.map((s) => _score(s['score'])).whereType<num>().toList();
  final avg = scores.isEmpty ? null : scores.fold<double>(0, (a,b) => a+b.toDouble()) / scores.length;
  final high = scores.isEmpty ? null : scores.reduce(math.max);
  final low = scores.isEmpty ? null : scores.reduce(math.min);
  final name = _value(child['name'], fallbackChildName);
  final goals = child['therapyGoals'] ?? child['goals'];
  final goalText = goals is List ? goals.map((e) => e.toString()).join(', ') : _value(goals);
  final now = DateTime.now();

  // Fetch only through the therapist-authorized API; if unavailable, omit photo.
  pw.MemoryImage? photo;
  try {
    final token = await FirebaseAuth.instance.currentUser!.getIdToken();
    final apiBase = const String.fromEnvironment('TALKIEPAL_API_URL', defaultValue: 'http://192.168.0.139:8000');
    final urlResponse = await http.get(
      Uri.parse('$apiBase/therapist/parents/${Uri.encodeComponent(parentId)}/children/${Uri.encodeComponent(childId)}/photo'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 12));
    if (urlResponse.statusCode == 200) {
      final payload = jsonDecode(urlResponse.body) as Map<String, dynamic>;
      final signedUrl = payload['url']?.toString();
      if (signedUrl != null && signedUrl.isNotEmpty) {
        final imageResponse = await http.get(Uri.parse(signedUrl))
            .timeout(const Duration(seconds: 12));
        if (imageResponse.statusCode == 200) {
          photo = pw.MemoryImage(imageResponse.bodyBytes);
        }
      }
    }
  } catch (e) {
    debugPrint('Therapist PDF photo unavailable: $e');
  }

  final pdf = pw.Document();
  pdf.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(38, 40, 38, 42),
    header: (_) => pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 7),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _line))),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('TalkiePal', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: _purple)),
        pw.Text('PROGRESS REPORT', style: const pw.TextStyle(fontSize: 8, color: _muted)),
      ]),
    ),
    footer: (ctx) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text('Practice analytics - not a clinical diagnosis', style: const pw.TextStyle(fontSize: 8, color: _muted)),
      pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: _muted)),
    ]),
    build: (_) => [
      pw.SizedBox(height: 15),
      pw.Text('Progress Report', style: pw.TextStyle(fontSize: 21, fontWeight: pw.FontWeight.bold, color: _dark)),
      pw.Text('Generated on ${_formatDate(now)}', style: const pw.TextStyle(fontSize: 10, color: _muted)),
      _section('01  Child Profile'),
      pw.Container(
        padding: const pw.EdgeInsets.all(13),
        decoration: pw.BoxDecoration(color: _pale, borderRadius: pw.BorderRadius.circular(9)),
        child: pw.Row(children: [
          if (photo != null) ...[
            pw.Image(photo, width: 70, height: 70, fit: pw.BoxFit.cover),
            pw.SizedBox(width: 12),
          ],
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(name, style: pw.TextStyle(fontSize: 15, color: _purple, fontWeight: pw.FontWeight.bold)),
            pw.Text('Age: ${_value(child['age'])}'),
            pw.Text('Parent: $parentName'),
            pw.Text('Speech concern: ${_value(child['speechConcern'] ?? child['problemType'])}'),
            pw.Text('Target sound: ${_value(child['targetSound'])}'),
            pw.Text('Therapy goals: $goalText'),
          ])),
        ]),
      ),
      _section('02  Overall Performance Dashboard'),
      pw.Row(children: [
        _metric('Completed sessions', '${sessions.length}'),
        _metric('Average score', avg == null ? 'N/A' : '${avg.toStringAsFixed(1)}/100'),
        _metric('Highest score', high == null ? 'N/A' : '$high/100'),
      ]),
      pw.SizedBox(height: 8),
      pw.Row(children: [
        _metric('Lowest score', low == null ? 'N/A' : '$low/100'),
        _metric('Games', '${sessions.where((s) => s['kind'] == 'game').length}'),
        _metric('Other practice', '${sessions.where((s) => s['kind'] != 'game').length}'),
      ]),
      _section('03  Overall Evaluation Summary'),
      pw.Text(avg == null
          ? 'No completed practice scores are available yet.'
          : '$name has ${sessions.length} recorded sessions and an average activity score of ${avg.toStringAsFixed(1)}/100. These scores describe app activities, not clinical diagnosis.'),
      _section('04  Target Sound Progress'),
      pw.Text('Target sound: ${_value(child['targetSound'])}'),
      _section('05  Practice Score Trend'),
      if (scores.length < 2) pw.Text('At least two scored sessions are needed for a trend.')
      else for (final s in sessions.reversed.take(12).toList().reversed)
        if (_score(s['score']) != null) _scoreBar(_value(s['topic'], 'Practice'), _score(s['score'])!),
      _section('06  Activity Performance Comparison'),
      if (scores.isEmpty) pw.Text('No activity scores recorded.')
      else for (final s in sessions.reversed.take(8))
        if (_score(s['score']) != null) _scoreBar('${_value(s['topic'], 'Practice')} - ${_value(s['level'], '')}', _score(s['score'])!),
      _section('07  Strengths & Areas for Review'),
      pw.Text(scores.isEmpty ? 'Not enough data to evaluate.' : 'Highest recorded score: $high/100. Lowest recorded score: $low/100.'),
      _section('08  Suggested Next Session Focus'),
      pw.Text('Review lower-scoring activities and monitor performance across future sessions. A qualified therapist should assess speech and language clinically.'),
      _section('09  Recent Practice Records'),
      if (sessions.isEmpty) pw.Text('No completed sessions yet.'),
      for (final s in sessions.reversed.take(20))
        pw.Padding(padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Text('${_formatDate(s['finishedAt'])} | ${_value(s['topic'], 'Practice')} | ${_value(s['level'], '')} | ${_value(s['score'], '-')}/100',
            style: const pw.TextStyle(fontSize: 9))),
      _section('10  Therapist Feedback'),
      if (comments.isEmpty) pw.Text('No therapist comments recorded yet.'),
      for (final c in comments)
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 9),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(color: _pale, borderRadius: pw.BorderRadius.circular(7)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('${_value(c['therapistName'], 'Therapist')} | ${_formatDate(c['createdAt'])}',
              style: pw.TextStyle(fontSize: 10, color: _purple, fontWeight: pw.FontWeight.bold)),
            pw.Text(_value(c['observation'] ?? c['comment'], ''), style: const pw.TextStyle(fontSize: 10)),
          ]),
        ),
      pw.SizedBox(height: 12),
      pw.Text('Interpretation note: Scores may be affected by noise, device, task difficulty and speech recognition. This report is not a clinical diagnosis.',
        style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
    ],
  ));
  await Printing.layoutPdf(
    onLayout: (_) async => pdf.save(),
    name: 'TalkiePal_${name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}_Progress_Report.pdf',
  );
}
