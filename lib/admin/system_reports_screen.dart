import 'admin_api.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'widgets/admin_ui.dart';

class SystemReportsScreen extends StatefulWidget {
  const SystemReportsScreen({super.key});

  @override
  State<SystemReportsScreen> createState() => _SystemReportsScreenState();
}

class _SystemReportsScreenState extends State<SystemReportsScreen> {
  bool loading = false;
  String reportType = 'system';
  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime endDate = DateTime.now();
  Map<String, int>? report;
  String? reportError;

  static const reportTypes = <String, String>{
    'system': 'System Overview',
    'users': 'User Management',
    'therapists': 'Therapist Activity',
    'progress': 'Children Progress',
    'practice': 'Practice & Game Performance',
    'appointments': 'Appointment Report',
  };

  String _day(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  Future<Map<String, int>> _loadData() async {
    if (endDate.isBefore(startDate)) {
      throw Exception('End Date cannot be earlier than Start Date.');
    }
    return AdminApi.getSystemReport(
      type: reportType,
      start: startDate,
      end: endDate,
    );
  }

  Future<void> _refresh() async {
    setState(() { loading = true; reportError = null; report = null; });
    try {
      final data = await _loadData();
      if (mounted) setState(() => report = data);
    } catch (e) {
      if (mounted) {
        setState(() => reportError = '$e');
        adminMessage(context, 'Report error: $e');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _generatePdf() async {
    setState(() { loading = true; reportError = null; });
    try {
      final data = await _loadData();
      final document = pw.Document();
      document.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => [
          pw.Text('TalkiePal ${reportTypes[reportType]} Report',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Text('Period: ${_day(startDate)} - ${_day(endDate)}'),
          pw.Text('Generated: ${DateTime.now().toLocal()}'),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Metric', 'Total'],
            data: data.entries.map((e) => [e.key, '${e.value}']).toList(),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Source: TalkiePal Firebase Firestore. Counts reflect available records.'),
          pw.Text('Current status metrics are snapshots, not historical values.'),
        ],
      ));
      if (mounted) setState(() => report = data);
      await Printing.layoutPdf(onLayout: (_) async => document.save());
    } catch (e) {
      if (mounted) {
        setState(() => reportError = '$e');
        adminMessage(context, 'PDF error: $e');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _pickDate({required bool start}) async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: start ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (chosen == null || !mounted) return;
    setState(() {
      if (start) {
        startDate = chosen;
        if (endDate.isBefore(chosen)) endDate = chosen;
      } else {
        endDate = chosen;
      }
      report = null;
    });
  }

  Future<void> _chooseReportType() async {
    if (loading) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFFFFFBF4),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 4, width: 42,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Choose Report Category',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: reportTypes.entries.map((entry) {
                    final selected = entry.key == reportType;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: selected
                            ? const Color(0xFFF0E4F6)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          title: Text(entry.value,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.bold : FontWeight.w500,
                              )),
                          trailing: selected
                              ? const Icon(Icons.check_circle,
                                  color: AdminColors.purple)
                              : const Icon(Icons.chevron_right,
                                  color: Colors.grey),
                          onTap: () => Navigator.pop(sheetContext, entry.key),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice != null && mounted && choice != reportType) {
      setState(() {
        reportType = choice;
        report = null;
        reportError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'System Reports',
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const AdminCard(
            child: Row(
              children: [
                Icon(Icons.analytics_outlined,
                    size: 38, color: AdminColors.purple),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TalkiePal System Analytics',
                          style: TextStyle(fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text('View statistics and generate PDF reports.',
                          style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Report Category',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 9),
                InkWell(
                  onTap: loading ? null : _chooseReportType,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF6FC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE6D9ED)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined,
                            color: AdminColors.purple),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(reportTypes[reportType] ?? 'System Overview',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                        const Icon(Icons.keyboard_arrow_down,
                            color: AdminColors.purple),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Date Range',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: loading ? null : () => _pickDate(start: true),
                        icon: const Icon(Icons.calendar_month, size: 18),
                        label: Text(_day(startDate),
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('to'),
                    ),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: loading ? null : () => _pickDate(start: false),
                        icon: const Icon(Icons.event, size: 18),
                        label: Text(_day(endDate),
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AdminActionButton(
            label: loading ? 'Loading...' : 'Refresh Report',
            icon: Icons.refresh,
            onPressed: loading ? null : _refresh,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: loading ? null : _generatePdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Generate PDF Report'),
            ),
          ),
          const SizedBox(height: 20),
          if (loading)
            const Center(child: CircularProgressIndicator()),
          if (reportError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(reportError!,
                  style: const TextStyle(color: Colors.red)),
            ),
          if (report != null) ...[
            Text('Report Preview · ${_day(startDate)} – ${_day(endDate)}',
                style: const TextStyle(fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final entry in report!.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AdminCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(entry.key,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 12),
                      Text('${entry.value}',
                          style: const TextStyle(
                              fontSize: 20,
                              color: AdminColors.purple,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
