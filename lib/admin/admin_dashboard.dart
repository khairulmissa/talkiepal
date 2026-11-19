import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../parent/login_screen.dart';
import 'widgets/admin_ui.dart';
import 'manage_therapists_screen.dart';
import 'manage_users_screen.dart';
import 'study_content_screen.dart';
import 'system_reports_screen.dart';
import 'admin_notifications_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const Color cream = Color(0xFFFFFBF4);
  static const Color yellow = Color(0xFFFFEFA8);
  static const Color purple = Color(0xFF8054A1);
  static const Color darkPurple = Color(0xFF50336D);
  static const Color orange = Color(0xFFEF7D35);

  // Physical Android phone with adb reverse.
  // Android Emulator: http://10.0.2.2:8001
  static const String backendUrl = 'http://192.168.0.139:8001';

  bool loading = true;
  String? error;

  String adminName = '';

  int parents = 0;
  int therapists = 0;
  int children = 0;
  int activeAccounts = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Please sign in as Admin.');
      }

      final token = await user.getIdToken();

      if (token == null || token.isEmpty) {
        throw Exception('Unable to get Firebase authentication token.');
      }

      // Load statistics from Python FastAPI backend.
      final response = await http.get(
        Uri.parse('$backendUrl/admin/dashboard-stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        throw Exception(
          'Server error ${response.statusCode}: ${response.body}',
        );
      }

      final data = jsonDecode(response.body)
          as Map<String, dynamic>;

      // Get the actual registered Admin username.
      // Prefer Firestore username, then backend adminName.
      String resolvedAdminName =
          data['adminName']?.toString().trim() ?? '';

      try {
        final adminDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final firestoreUsername =
            adminDoc.data()?['username']?.toString().trim();

        if (firestoreUsername != null &&
            firestoreUsername.isNotEmpty) {
          resolvedAdminName = firestoreUsername;
        }
      } catch (e) {
        debugPrint('Unable to read Admin username: $e');
      }

      if (resolvedAdminName.isEmpty ||
          resolvedAdminName == 'Administrator') {
        final displayName = user.displayName?.trim() ?? '';

        if (displayName.isNotEmpty) {
          resolvedAdminName = displayName;
        } else {
          resolvedAdminName = 'Administrator';
        }
      }

      if (!mounted) return;

      setState(() {
        parents = (data['parents'] as num?)?.toInt() ?? 0;
        therapists = (data['therapists'] as num?)?.toInt() ?? 0;
        children = (data['children'] as num?)?.toInt() ?? 0;
        activeAccounts =
            (data['activeAccounts'] as num?)?.toInt() ?? 0;

        adminName = resolvedAdminName;
        loading = false;
      });
    } catch (e) {
      debugPrint('Dashboard error: $e');

      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  void _open(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _logout() async {
    final confirmed = await confirmAdminAction(
      context,
      'Logout',
      'Do you want to log out of the Admin Dashboard?',
    );

    if (!confirmed) return;

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (_) => false,
    );
  }

  // Compact statistic card.
  Widget _statCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      height: 136,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFF0EBE5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
                ),
              ),
              Text(
                loading ? '...' : '$value',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: darkPurple,
                ),
              ),
            ],
          ),

          const Spacer(),

          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF77717C),
            ),
          ),
        ],
      ),
    );
  }

  // Management module.
  Widget _module({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color background,
    required Widget screen,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: () => _open(screen),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: const Color(0xFFF0EBE5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: darkPurple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF817B83),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9B8BA7),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcomeCard() {
    final name = adminName.isEmpty
        ? (loading ? '...' : 'Administrator')
        : adminName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFEFA8),
            Color(0xFFFFF5D3),
          ],
        ),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WELCOME BACK',
            style: TextStyle(
              color: Color(0xFF85642E),
              fontSize: 10,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 9),

          Text(
            'Hello, $name! 👋',
            style: const TextStyle(
              color: darkPurple,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            "Here's what's happening in TalkiePal today.",
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF62534A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD5CC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Color(0xFFB94732),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Unable to load dashboard statistics',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9F3526),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            error ?? 'Unknown error',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8D493E),
            ),
          ),

          const SizedBox(height: 8),

          TextButton.icon(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,

      appBar: AppBar(
        backgroundColor: yellow,
        elevation: 0,
        toolbarHeight: 65,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TalkiePal',
              style: TextStyle(
                color: darkPurple,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Admin Dashboard',
              style: TextStyle(
                color: Color(0xFF7C6389),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh statistics',
            onPressed: loading ? null : _loadDashboard,
            icon: const Icon(
              Icons.refresh_rounded,
              color: darkPurple,
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(
              Icons.logout_rounded,
              color: darkPurple,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        color: purple,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20, 20, 20, 35,
          ),
          children: [
            // Welcome message with Admin username
            _welcomeCard(),

            const SizedBox(height: 25),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'System Overview',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: darkPurple,
                  ),
                ),

                if (loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: purple,
                    ),
                  )
                else if (error == null)
                  const Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 7,
                        color: Colors.green,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Live data',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 13),

            if (error != null) ...[
              _errorCard(),
              const SizedBox(height: 13),
            ],

            // Compact 2-column statistics
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 11,
              crossAxisSpacing: 11,
              childAspectRatio: 1.30,
              children: [
                _statCard(
                  title: 'Parent Accounts',
                  value: parents,
                  icon: Icons.groups_rounded,
                  color: purple,
                  background: const Color(0xFFF1E8F7),
                ),

                _statCard(
                  title: 'Therapist Accounts',
                  value: therapists,
                  icon: Icons.medical_services_rounded,
                  color: const Color(0xFF168F89),
                  background: const Color(0xFFDDF5F1),
                ),

                _statCard(
                  title: 'Children',
                  value: children,
                  icon: Icons.child_care_rounded,
                  color: orange,
                  background: const Color(0xFFFFF0D7),
                ),

                _statCard(
                  title: 'Active Accounts',
                  value: activeAccounts,
                  icon: Icons.verified_user_rounded,
                  color: const Color(0xFF37965C),
                  background: const Color(0xFFE3F5E8),
                ),
              ],
            ),

            const SizedBox(height: 27),

            const Text(
              'Management Modules',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: darkPurple,
              ),
            ),

            const SizedBox(height: 14),

            _module(
              title: 'Manage Therapists',
              subtitle: 'Register, verify and manage therapists',
              icon: Icons.medical_services_rounded,
              color: purple,
              background: const Color(0xFFF1E8F7),
              screen: const ManageTherapistsScreen(),
            ),

            _module(
              title: 'Manage Users',
              subtitle: 'Manage parent and therapist accounts',
              icon: Icons.groups_rounded,
              color: const Color(0xFF168F89),
              background: const Color(0xFFDDF5F1),
              screen: const ManageUsersScreen(),
            ),

            _module(
              title: 'Study Content Database',
              subtitle: 'Flashcards and learning activities',
              icon: Icons.menu_book_rounded,
              color: orange,
              background: const Color(0xFFFFF0D7),
              screen: const StudyContentScreen(),
            ),

            _module(
              title: 'Generate System Reports',
              subtitle: 'System statistics and PDF reports',
              icon: Icons.bar_chart_rounded,
              color: const Color(0xFF37965C),
              background: const Color(0xFFE3F5E8),
              screen: const SystemReportsScreen(),
            ),

            _module(
              title: 'Push Notification Management',
              subtitle: 'Send announcements to app users',
              icon: Icons.notifications_active_rounded,
              color: const Color(0xFFD76D91),
              background: const Color(0xFFFFE8F0),
              screen: const AdminNotificationsScreen(),
            ),
          ],
        ),
      ),
    );
  }
}
