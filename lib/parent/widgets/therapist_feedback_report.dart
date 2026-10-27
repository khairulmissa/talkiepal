import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talkiepal/parent/widgets/parent_ui.dart';
import 'package:talkiepal/services/parent_report.dart';
import 'package:talkiepal/services/progress_store.dart';

/// Parent-facing therapist feedback. The parent reads only their own child.
class TherapistProgressReport extends StatelessWidget {
  final String childId;
  const TherapistProgressReport({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    final feedback = FirebaseFirestore.instance
        .collection('users').doc(uid).collection('children').doc(childId)
        .collection('therapistFeedback');
    return ParentCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.chat_bubble_outline_rounded, color: ParentColors.purple),
          SizedBox(width: 8),
          Text('Progress Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ParentColors.ink)),
        ]),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: feedback.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Text('Unable to load therapist comments.');
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs.toList()
              ..sort((a, b) => _feedbackDate(b.data()).compareTo(_feedbackDate(a.data())));
            if (docs.isEmpty) return const Text('No therapist comments yet.', style: TextStyle(color: ParentColors.soft));
            final visible = docs.take(3).toList();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var i = 0; i < visible.length; i++) ...[
                _feedbackEntry(visible[i].data()),
                if (i < visible.length - 1) const Divider(),
              ],
              if (docs.length > 3)
                TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => SafeArea(child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: ListView(shrinkWrap: true, children: [
                        const Text('All Therapist Comments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        for (final doc in docs) ...[_feedbackEntry(doc.data()), const Divider()],
                      ]),
                    )),
                  ),
                  child: const Text('View all comments'),
                ),
            ]);
          },
        ),
      ]),
    );
  }

  Widget _feedbackEntry(Map<String, dynamic> data) {
    final date = _feedbackDate(data);
    final name = (data['therapistName'] ?? 'Therapist').toString();
    final observation = (data['observation'] ?? data['comment'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: ParentColors.ink)),
        if (date.year > 1970)
          Text('${date.day}/${date.month}/${date.year}', style: const TextStyle(fontSize: 11, color: ParentColors.soft)),
        if (observation.isNotEmpty)
          Padding(padding: const EdgeInsets.only(top: 6), child: Text(observation)),
      ]),
    );
  }
}

DateTime _feedbackDate(Map<String, dynamic> data) {
  final value = data['createdAt'];
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.fromMillisecondsSinceEpoch(0);
}

const _purple = PdfColor.fromInt(0xFF8154AA);
const _dark = PdfColor.fromInt(0xFF30243D);
const _muted = PdfColor.fromInt(0xFF71687B);
const _pale = PdfColor.fromInt(0xFFF4EDF8);
const _line = PdfColor.fromInt(0xFFE8DDED);
const _green = PdfColor.fromInt(0xFF2F8A66);
const _amber = PdfColor.fromInt(0xFFC07C2B);

String _datePdf(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
String _field(Map<String, dynamic> data, String name, [String fallback = 'Not recorded']) {
  final text = (data[name] ?? '').toString().trim();
  return text.isEmpty ? fallback : text;
}

Uint8List? _childPhotoBytes(Map<String, dynamic> childData) {
  final raw = childData['base64Photo'];
  if (raw is! String || raw.trim().isEmpty) return null;
  try {
    final encoded = raw.contains(',') ? raw.split(',').last : raw;
    return base64Decode(encoded.replaceAll(RegExp(r'\s'), ''));
  } catch (_) {
    return null;
  }
}

pw.Widget _section(String title) => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 17, bottom: 9),
  child: pw.Text(title, style: pw.TextStyle(fontSize: 14, color: _purple, fontWeight: pw.FontWeight.bold)),
);

pw.Widget _metric(String label, String value) => pw.Expanded(
  child: pw.Container(
    padding: const pw.EdgeInsets.all(12),
    margin: const pw.EdgeInsets.only(right: 7),
    decoration: pw.BoxDecoration(color: _pale, borderRadius: pw.BorderRadius.circular(9)),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(value, style: pw.TextStyle(fontSize: 18, color: _purple, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 3),
      pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _muted)),
    ]),
  ),
);

pw.Widget _scoreBar(String label, int score, {String? detail}) {
  final safeScore = score.clamp(0, 100);
  final color = safeScore >= 85 ? _green : (safeScore < 70 ? _amber : _purple);
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 11),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Expanded(child: pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: _dark), maxLines: 1)),
        pw.Text('$safeScore/100', style: pw.TextStyle(fontSize: 10, color: color, fontWeight: pw.FontWeight.bold)),
      ]),
      pw.SizedBox(height: 4),
      pw.Stack(children: [
        pw.Container(width: 470, height: 9, decoration: pw.BoxDecoration(color: _line, borderRadius: pw.BorderRadius.circular(5))),
        pw.Container(width: 470 * safeScore / 100, height: 9, decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(5))),
      ]),
      if (detail != null) pw.Padding(padding: const pw.EdgeInsets.only(top: 3), child: pw.Text(detail, style: const pw.TextStyle(fontSize: 8, color: _muted))),
    ]),
  );
}

/// An actual chronological line graph drawn with PDF vector primitives.
/// No extra chart package is required.
pw.Widget _trendChart(List<SessionRecord> ordered) {
  if (ordered.length < 2) {
    return pw.Text('At least two sessions are needed for a trend chart.', style: const pw.TextStyle(fontSize: 10, color: _muted));
  }
  final points = ordered.length > 12 ? ordered.sublist(ordered.length - 12) : ordered;
  const graphHeight = 110.0;
  return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    pw.Text('Most recent ${points.length} sessions, oldest to newest', style: const pw.TextStyle(fontSize: 9, color: _muted)),
    pw.SizedBox(height: 7),
    pw.Container(
      height: graphHeight + 20,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
        for (var i = 0; i < points.length; i++)
          pw.Expanded(child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Text('${points[i].score}', style: const pw.TextStyle(fontSize: 8, color: _dark)),
            pw.SizedBox(height: 3),
            pw.Container(
              width: 17,
              height: math.max(3, graphHeight * points[i].score.clamp(0, 100) / 100),
              decoration: pw.BoxDecoration(
                color: points[i].score >= 85 ? _green : (points[i].score < 70 ? _amber : _purple),
                borderRadius: pw.BorderRadius.circular(3),
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text('${i + 1}', style: const pw.TextStyle(fontSize: 8, color: _muted)),
          ])),
      ]),
    ),
    pw.Text('Horizontal axis: session order  |  Vertical bars: score out of 100', style: const pw.TextStyle(fontSize: 8, color: _muted)),
  ]);
}

/// Drop-in replacement for the existing report generator.
/// All metrics are calculated from the selected child's ParentReport.
Future<void> generateChildProgressPdf({
  required String childId,
  required String childName,
  required String? targetSound,
  required ParentReport report,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) throw StateError('Please sign in first.');

  final childRef = FirebaseFirestore.instance
      .collection('users').doc(uid).collection('children').doc(childId);
  final results = await Future.wait([
    childRef.get(),
    childRef.collection('therapistFeedback').get(),
  ]);
  final childData = (results[0] as DocumentSnapshot<Map<String, dynamic>>).data() ?? <String, dynamic>{};
  final feedbackSnapshot = results[1] as QuerySnapshot<Map<String, dynamic>>;
  final feedback = feedbackSnapshot.docs.toList()
    ..sort((a, b) => _feedbackDate(b.data()).compareTo(_feedbackDate(a.data())));

  final sessions = report.sessions.toList()
    ..sort((a, b) => a.finishedAt.compareTo(b.finishedAt));
  final scores = sessions.map((s) => s.score).toList();
  final total = sessions.length;
  final average = total == 0 ? null : scores.reduce((a, b) => a + b) / total;
  final highest = total == 0 ? null : scores.reduce(math.max);
  final lowest = total == 0 ? null : scores.reduce(math.min);
  final practiceMinutes = sessions.fold<int>(0, (sum, s) => sum + s.time.inMinutes);
  final gameCount = sessions.where((s) => s.isGame).length;
  final speakingCount = total - gameCount;
  final target = report.targetSound(targetSound);
  final week = report.thisWeek;
  final now = DateTime.now();

  // Compare the average of the earliest and latest 3 sessions only when
  // there are enough records. Avoid making clinical claims from small samples.
  double? trendDifference;
  if (total >= 6) {
    final first = sessions.take(3).map((s) => s.score).reduce((a, b) => a + b) / 3;
    final last = sessions.skip(total - 3).map((s) => s.score).reduce((a, b) => a + b) / 3;
    trendDifference = last - first;
  }

  final weakest = total == 0 ? null : (sessions.toList()..sort((a, b) => a.score.compareTo(b.score))).first;
  final strongest = total == 0 ? null : (sessions.toList()..sort((a, b) => b.score.compareTo(a.score))).first;
  // Prefer the latest private Supabase photo. Fall back to legacy Firestore Base64.
  Uint8List? photoBytes;
  final childPhotoPath = (childData['childPhotoPath'] ?? '').toString().trim();
  if (childPhotoPath.isNotEmpty) {
    try {
      // Supabase storage policies restrict this download to the signed-in parent.
      photoBytes = await Supabase.instance.client.storage
          .from('child-photos')
          .download(childPhotoPath);
    } catch (e) {
      debugPrint('[Progress PDF] Unable to download child photo: $e');
    }
  }
  photoBytes ??= _childPhotoBytes(childData);
  pw.MemoryImage? childPhoto;
  if (photoBytes != null) {
    try {
      childPhoto = pw.MemoryImage(photoBytes);
    } catch (e) {
      debugPrint('[Progress PDF] Unable to decode child photo: $e');
      childPhoto = null;
    }
  }
  final goalsRaw = childData['therapyGoals'];
  final goals = goalsRaw is List ? goalsRaw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList() : <String>[];

  final summary = total == 0
      ? 'No completed practice sessions have been recorded. An overall performance evaluation is not yet available.'
      : '$childName completed $total recorded practice sessions, with an average activity score of ${average!.toStringAsFixed(1)}/100. '
        'The highest score was $highest/100 and the lowest was $lowest/100. '
        '${total < 6 ? 'More sessions are needed to assess a reliable progress trend.' : 'The difference between the latest three and earliest three session averages is ${trendDifference! >= 0 ? '+' : ''}${trendDifference.toStringAsFixed(1)} points.'}';

  final followUp = total == 0
      ? 'Begin structured practice and record several sessions before reviewing progress.'
      : 'Review the lower-scoring activity (${weakest!.topic}, ${weakest.score}/100), repeat the target sound in different words, and observe consistency with and without prompts. '
        'Compare scores after further sessions and document direct clinical observations separately.';

  final document = pw.Document();
  document.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(38, 40, 38, 42),
    header: (context) => pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 7),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.7))),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('TalkiePal', style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold, color: _purple)),
        pw.Text('PROGRESS REPORT', style: const pw.TextStyle(fontSize: 8, color: _muted)),
      ]),
    ),
    footer: (context) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text('Practice analytics - not a clinical diagnosis', style: const pw.TextStyle(fontSize: 8, color: _muted)),
      pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: _muted)),
    ]),
    build: (context) => [
      pw.SizedBox(height: 15),
      pw.Text('Progress Report', style: pw.TextStyle(fontSize: 21, fontWeight: pw.FontWeight.bold, color: _dark)),
      pw.SizedBox(height: 5),
      pw.Text('Generated on ${_datePdf(now)}', style: const pw.TextStyle(fontSize: 10, color: _muted)),
      _section('01  Child Profile'),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(13),
        decoration: pw.BoxDecoration(color: _pale, borderRadius: pw.BorderRadius.circular(9)),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          if (childPhoto != null) ...[
            pw.Container(
              width: 78,
              height: 78,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(9),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 9,
                verticalRadius: 9,
                child: pw.Image(childPhoto, fit: pw.BoxFit.cover),
              ),
            ),
            pw.SizedBox(width: 13),
          ],
          pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(childName, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _purple)),
            pw.SizedBox(height: 5),
            pw.Text('Age: ${_field(childData, 'age')}'),
            pw.Text('Target sound: ${targetSound == null || targetSound.trim().isEmpty ? 'Not specified' : targetSound}'),
            pw.Text('Speech concern: ${_field(childData, 'speechConcern')}'),
            if (goals.isNotEmpty) pw.Text('Therapy goals: ${goals.join('; ')}'),
          ])),
        ]),
      ),
      _section('02  Overall Performance Dashboard'),
      pw.Row(children: [
        _metric('Completed sessions', '$total'),
        _metric('Average score', average == null ? 'N/A' : '${average.toStringAsFixed(1)}/100'),
        _metric('Practice time', '$practiceMinutes min'),
      ]),
      pw.SizedBox(height: 8),
      pw.Row(children: [
        _metric('Highest score', highest == null ? 'N/A' : '$highest/100'),
        _metric('Lowest score', lowest == null ? 'N/A' : '$lowest/100'),
        _metric('Games / other', '$gameCount / $speakingCount'),
      ]),
      _section('03  Overall Evaluation Summary'),
      pw.Text(summary, style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 3, color: _dark)),
      pw.SizedBox(height: 8),
      pw.Text('This week: ${week.sessions} sessions, ${week.time.inMinutes} minutes, ${week.days}/7 active days.',
          style: const pw.TextStyle(fontSize: 10, color: _muted)),
      if (target != null) ...[
        _section('04  Target Sound Progress'),
        pw.Text('Target /${target.sound}/ - ${target.sessions} recorded sessions', style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 8),
        if (target.latest != null)
          _scoreBar('Latest target sound score', target.latest!)
        else
          pw.Text('No target-sound score recorded yet.'),
      ],
      _section('05  Practice Score Trend'),
      _trendChart(sessions),
      _section('06  Activity Performance Comparison'),
      if (sessions.isEmpty) pw.Text('No recorded activity scores.')
      else ...[
        pw.Text('Latest 8 activities (ordered by date)', style: const pw.TextStyle(fontSize: 9, color: _muted)),
        pw.SizedBox(height: 9),
        for (final s in sessions.reversed.take(8).toList().reversed)
          _scoreBar('${s.topic} - ${s.level}', s.score, detail: _datePdf(s.finishedAt)),
      ],
      _section('07  Strengths & Areas for Review'),
      if (strongest != null) ...[
        pw.Text('Highest recorded activity: ${strongest.topic} (${strongest.score}/100)', style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 5),
        pw.Text('Lowest recorded activity: ${weakest!.topic} (${weakest.score}/100)', style: const pw.TextStyle(fontSize: 10)),
      ] else pw.Text('Not enough practice data to identify strengths or focus areas.'),
      _section('08  Suggested Next Session Focus'),
      pw.Text(followUp, style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 3)),
      _section('09  Recent Practice Records'),
      if (sessions.isEmpty) pw.Text('No completed sessions yet.'),
      for (final s in sessions.reversed.take(20))
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Text('${_datePdf(s.finishedAt)}  |  ${s.level} - ${s.topic}  |  ${s.score}/100  |  ${s.time.inMinutes} min',
              style: const pw.TextStyle(fontSize: 9.5)),
        ),
      _section('10  Therapist Feedback'),
      if (feedback.isEmpty) pw.Text('No therapist comments recorded yet.'),
      for (final doc in feedback) ...[
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          margin: const pw.EdgeInsets.only(bottom: 9),
          decoration: pw.BoxDecoration(color: _pale, borderRadius: pw.BorderRadius.circular(7)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('${_field(doc.data(), 'therapistName', 'Therapist')}  |  ${_feedbackDate(doc.data()).year > 1970 ? _datePdf(_feedbackDate(doc.data())) : 'Date unavailable'}',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _purple)),
            pw.SizedBox(height: 4),
            pw.Text((doc.data()['observation'] ?? doc.data()['comment'] ?? '').toString(), style: const pw.TextStyle(fontSize: 10)),
          ]),
        ),
      ],
      pw.SizedBox(height: 15),
      pw.Text('Interpretation note: Activity scores reflect app performance and may be affected by device, noise, attention, task difficulty and speech recognition. A qualified therapist must evaluate speech and language clinically.',
          style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
    ],
  ));

  await Printing.layoutPdf(
    onLayout: (_) async => document.save(),
    name: 'TalkiePal_${childName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}_Therapist_Progress_Report.pdf',
  );
}
