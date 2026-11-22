import 'package:flutter/material.dart';
import 'admin_api.dart';
import 'widgets/admin_ui.dart';

/// Notification management UI. Scheduled operations require the matching
/// authenticated FastAPI endpoints; this screen never simulates a successful send.
class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final titleController = TextEditingController();
  final messageController = TextEditingController();
  String audience = 'all';
  String frequency = 'now';
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = const TimeOfDay(hour: 18, minute: 0);
  int weekday = DateTime.monday;
  bool sending = false;
  List<Map<String, dynamic>> users = [];
  Set<String> selectedUids = {};
  List<Map<String, dynamic>> schedules = [];
  List<Map<String, dynamic>> history = [];
  bool loadingLists = false;
  String? listError;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> _loadLists() async {
    setState(() { loadingLists = true; listError = null; });
    try {
      final responses = await Future.wait([
        AdminApi.getNotificationUsers(),
        AdminApi.getNotificationSchedules(),
        AdminApi.getNotificationHistory(),
      ]);
      if (!mounted) return;
      setState(() {
        users = responses[0];
        schedules = responses[1];
        history = responses[2];
      });
    } catch (e) {
      if (mounted) setState(() => listError = '$e');
    } finally {
      if (mounted) setState(() => loadingLists = false);
    }
  }

  Future<void> _pickUsers() async {
    final chosen = Set<String>.from(selectedUids);
    String search = '';
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final filtered = users.where((u) {
            final name = '${u['name'] ?? ''} ${u['email'] ?? ''}'.toLowerCase();
            return name.contains(search.toLowerCase());
          }).toList();
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16,
                  MediaQuery.viewInsetsOf(sheetContext).bottom + 16),
              child: SizedBox(
                height: MediaQuery.sizeOf(sheetContext).height * 0.65,
                child: Column(children: [
                  const Text('Select Specific Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search name or email', border: OutlineInputBorder()),
                    onChanged: (v) => setSheetState(() => search = v),
                  ),
                  const SizedBox(height: 8),
                  Expanded(child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final u = filtered[i];
                      final uid = '${u['uid'] ?? ''}';
                      return CheckboxListTile(
                        value: chosen.contains(uid),
                        title: Text('${u['name'] ?? 'Unnamed user'}'),
                        subtitle: Text('${u['role'] ?? ''} • ${u['email'] ?? ''}'),
                        onChanged: uid.isEmpty ? null : (v) => setSheetState(() {
                          if (v == true) { chosen.add(uid); } else { chosen.remove(uid); }
                        }),
                      );
                    },
                  )),
                  SizedBox(width: double.infinity, child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext, chosen),
                    child: Text('Confirm (${chosen.length} selected)'),
                  )),
                ]),
              ),
            ),
          );
        },
      ),
    );
    if (result != null && mounted) setState(() => selectedUids = result);
  }

  Future<void> _submit() async {
    final title = titleController.text.trim();
    final body = messageController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      adminMessage(context, 'Enter a title and message.');
      return;
    }
    if (audience == 'specific' && selectedUids.isEmpty) {
      adminMessage(context, 'Select at least one recipient.');
      return;
    }
    final action = frequency == 'now' ? 'Send Notification' : 'Create Notification Schedule';
    if (!await confirmAdminAction(context, action,
        'Audience: $audience${audience == 'specific' ? ' (${selectedUids.length} users)' : ''}. Continue?')) return;
    setState(() => sending = true);
    try {
      if (frequency == 'now' && audience != 'specific') {
        // Existing, working endpoint for all/parent/therapist.
        final result = await AdminApi.call('sendAdminNotification', {
          'title': title, 'body': body, 'audience': audience,
        });
        if (mounted) adminMessage(context, 'Sent to ${result['sent'] ?? 0} devices.');
      } else if (frequency == 'now') {
        final result = await AdminApi.sendNotificationToUsers(
          title: title, body: body, recipientUids: selectedUids.toList());
        if (mounted) adminMessage(context, 'Sent to ${result['sent'] ?? 0} devices.');
      } else {
        await AdminApi.createNotificationSchedule({
          'title': title,
          'body': body,
          'audience': audience,
          'recipientUids': audience == 'specific' ? selectedUids.toList() : <String>[],
          'frequency': frequency,
          'date': '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
          'time': '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
          'weekday': weekday,
          'timezone': 'Asia/Kuala_Lumpur',
        });
        if (mounted) adminMessage(context, 'Schedule created.');
      }
      titleController.clear();
      messageController.clear();
      await _loadLists();
    } catch (e) {
      if (mounted) adminMessage(context, 'Request failed: $e');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _changeStatus(Map<String, dynamic> item, String action) async {
    final id = '${item['id'] ?? ''}';
    if (id.isEmpty) return;
    if (action == 'stop' && !await confirmAdminAction(context,
        'Stop Schedule', 'Stop future notifications for this schedule permanently?')) return;
    try {
      await AdminApi.updateNotificationScheduleStatus(id, action);
      if (mounted) adminMessage(context, 'Schedule ${action}d.');
      await _loadLists();
    } catch (e) {
      if (mounted) adminMessage(context, 'Unable to $action schedule: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = AdminColors.purple;
    return AdminPage(
      title: 'Push Notifications',
      child: ListView(padding: const EdgeInsets.all(16), children: [
        AdminCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Compose Notification', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AdminColors.dark)),
          const SizedBox(height: 16),
          TextField(controller: titleController, maxLength: 100,
            decoration: const InputDecoration(labelText: 'Notification Title', prefixIcon: Icon(Icons.title), border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: messageController, maxLines: 4, maxLength: 1000,
            decoration: const InputDecoration(labelText: 'Message', alignLabelWithHint: true, border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: audience, isExpanded: true,
            decoration: const InputDecoration(labelText: 'Send To', border: OutlineInputBorder(), prefixIcon: Icon(Icons.people_outline)),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Users')),
              DropdownMenuItem(value: 'parents', child: Text('Parents Only')),
              DropdownMenuItem(value: 'therapists', child: Text('Therapists Only')),
              DropdownMenuItem(value: 'kids', child: Text('Kids (via Parents)')),
              DropdownMenuItem(value: 'specific', child: Text('Specific Users')),
            ],
            onChanged: sending ? null : (v) => setState(() => audience = v ?? 'all'),
          ),
          if (audience == 'specific') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _pickUsers, icon: const Icon(Icons.person_add_alt_1),
              label: Text('Choose Users (${selectedUids.length})')),
          ],
          const SizedBox(height: 20),
          const Text('When to Send', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminColors.dark)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: frequency, isExpanded: true,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.schedule), border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'now', child: Text('Send Now')),
              DropdownMenuItem(value: 'once', child: Text('Schedule Once')),
              DropdownMenuItem(value: 'daily', child: Text('Repeat Daily')),
              DropdownMenuItem(value: 'weekly', child: Text('Repeat Weekly')),
            ],
            onChanged: sending ? null : (v) => setState(() => frequency = v ?? 'now'),
          ),
          if (frequency != 'now') ...[
            const SizedBox(height: 12),
            if (frequency == 'once') OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text('Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
              onPressed: () async {
                final d = await showDatePicker(context: context, initialDate: selectedDate,
                  firstDate: DateTime.now(), lastDate: DateTime(2100));
                if (d != null && mounted) setState(() => selectedDate = d);
              },
            ),
            if (frequency == 'weekly') DropdownButtonFormField<int>(
              value: weekday,
              decoration: const InputDecoration(labelText: 'Day of Week', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Monday')),
                DropdownMenuItem(value: 2, child: Text('Tuesday')),
                DropdownMenuItem(value: 3, child: Text('Wednesday')),
                DropdownMenuItem(value: 4, child: Text('Thursday')),
                DropdownMenuItem(value: 5, child: Text('Friday')),
                DropdownMenuItem(value: 6, child: Text('Saturday')),
                DropdownMenuItem(value: 7, child: Text('Sunday')),
              ],
              onChanged: (v) => setState(() => weekday = v ?? 1),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(icon: const Icon(Icons.access_time),
              label: Text('Time: ${selectedTime.format(context)} (Malaysia)'),
              onPressed: () async {
                final t = await showTimePicker(context: context, initialTime: selectedTime);
                if (t != null && mounted) setState(() => selectedTime = t);
              }),
          ],
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: AdminActionButton(
            label: sending ? 'Processing...' : (frequency == 'now' ? 'Send Notification' : 'Save Schedule'),
            icon: frequency == 'now' ? Icons.send : Icons.event_available,
            onPressed: sending ? null : _submit,
          )),
        ])),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Scheduled Notifications', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AdminColors.dark)),
          IconButton(onPressed: loadingLists ? null : _loadLists, icon: const Icon(Icons.refresh, color: purple)),
        ]),
        if (loadingLists) const LinearProgressIndicator(),
        if (listError != null) Padding(padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text('Unable to load admin lists: $listError', style: const TextStyle(color: Colors.red))),
        if (schedules.isEmpty && !loadingLists && listError == null) const Padding(padding: EdgeInsets.all(12), child: Text('No schedules loaded.')),
        for (final item in schedules) Padding(padding: const EdgeInsets.only(bottom: 10), child: AdminCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${item['title'] ?? 'Notification'}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('${item['frequency'] ?? ''} • ${item['time'] ?? ''} • ${item['status'] ?? ''}'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              if (item['status'] == 'active') OutlinedButton.icon(onPressed: () => _changeStatus(item, 'pause'), icon: const Icon(Icons.pause), label: const Text('Pause')),
              if (item['status'] == 'paused') OutlinedButton.icon(onPressed: () => _changeStatus(item, 'resume'), icon: const Icon(Icons.play_arrow), label: const Text('Resume')),
              if (item['status'] == 'active' || item['status'] == 'paused') OutlinedButton.icon(onPressed: () => _changeStatus(item, 'stop'), icon: const Icon(Icons.stop), label: const Text('Stop')),
            ]),
          ]),
        )),
        const SizedBox(height: 18),
        const Text('Notification History', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AdminColors.dark)),
        const SizedBox(height: 10),
        if (history.isEmpty && !loadingLists && listError == null) const Text('No history loaded.'),
        for (final item in history) Padding(padding: const EdgeInsets.only(bottom: 10), child: AdminCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${item['title'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('${item['body'] ?? ''}'),
            const SizedBox(height: 6),
            Text('Audience: ${item['audience'] ?? ''} • Sent: ${item['sent'] ?? 0}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        )),
      ]),
    );
  }
}
