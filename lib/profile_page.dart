import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'game_page.dart';
import 'package:talkiepal/services/current_kid.dart';
import 'package:talkiepal/widgets/dino_mascot.dart';
import 'package:talkiepal/widgets/kids_bottom_nav.dart';
import 'package:talkiepal/progress_page.dart';
import 'package:talkiepal/parent/change_password_screen.dart';
import 'package:talkiepal/parent/kids_profile_selection_screen.dart';
import 'package:talkiepal/parent/login_screen.dart';
import 'package:talkiepal/profile/kid_edit_profile_page.dart';
import 'package:talkiepal/profile/kid_info_pages.dart';
import 'package:talkiepal/profile/kid_profile_store.dart';
import 'package:talkiepal/profile/parent_gate.dart';
import 'package:talkiepal/services/parent_store.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isNotificationEnabled = true;
  String selectedLanguage = 'English';
  int? _age;
  String? _targetSound;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Fills the card and the preferences from the child's saved profile.
  Future<void> _loadProfile() async {
    try {
      final data = await KidProfileStore.load();
      if (!mounted || data.isEmpty) return;
      final language = data['language'];
      final sound = (data['targetSound'] ?? '').toString().trim();
      setState(() {
        if (data['practiceReminders'] is bool) isNotificationEnabled = data['practiceReminders'] as bool;
        if (language is String && _languages.containsKey(language)) selectedLanguage = language;
        _age = data['age'] is num ? (data['age'] as num).toInt() : null;
        _targetSound = sound.isEmpty ? null : sound;
      });
    } catch (e) {
      // Firebase is not set up (e.g. in tests) or the profile cannot be read.
      debugPrint('[Profile] Could not load child profile: $e');
    }
  }

  static const Color _cream = Color(0xFFFFF8EC);
  static const Color _plum = Color(0xFF8E5CD9);
  static const Color _plumDark = Color(0xFF5E35B1);
  static const Color _ink = Color(0xFF4A3B57);
  static const Color _soft = Color(0xFF7A6A85);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          // Soft coloured circles in the background
          Positioned(top: -50, right: -50, child: _buildBlob(170, const Color(0xFFE0F2F1))),
          Positioned(top: 520, left: -80, child: _buildBlob(160, const Color(0xFFFFE0F0))),
          Positioned(bottom: 140, right: -60, child: _buildBlob(170, const Color(0xFFE3EEFF))),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('👤', style: TextStyle(fontSize: 28)),
                            SizedBox(width: 10),
                            Text(
                              'Profile',
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _plumDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildProfileCard(),
                        _buildSectionTitle('General ⚙️'),
                        _buildCard([
                          _buildMenuItem(
                            emoji: '✏️',
                            title: 'Edit Profile',
                            subtitle: 'Change your name and photo',
                            iconBackground: const Color(0xFFE3F2FD),
                            onTap: _openEditProfile,
                          ),
                          _buildMenuItem(
                            emoji: '👫',
                            title: 'Switch Profile',
                            subtitle: 'Pick another child',
                            iconBackground: const Color(0xFFFFE0B2),
                            onTap: _switchProfile,
                          ),
                          _buildMenuItem(
                            emoji: '🔒',
                            title: 'Change Password',
                            subtitle: 'For grown-ups only',
                            iconBackground: const Color(0xFFFFF3D6),
                            onTap: _openChangePassword,
                          ),
                          _buildMenuItem(
                            emoji: '📄',
                            title: 'Terms of Use',
                            subtitle: 'Read our rules',
                            iconBackground: const Color(0xFFE8F5E9),
                            onTap: () => _open(const KidTermsPage()),
                          ),
                        ]),
                        _buildSectionTitle('Preference 🎛️'),
                        _buildCard([
                          _buildMenuItem(
                            emoji: '🔔',
                            title: 'Notification',
                            subtitle: 'Practice reminders',
                            iconBackground: const Color(0xFFFFE0E6),
                            trailing: Switch(
                              value: isNotificationEnabled,
                              activeTrackColor: _plum,
                              onChanged: _setReminders,
                            ),
                          ),
                          _buildMenuItem(
                            emoji: '🌐',
                            title: 'Language',
                            subtitle: 'Choose your language',
                            iconBackground: const Color(0xFFE0F7FA),
                            trailing: _buildLanguagePicker(),
                          ),
                          _buildMenuItem(
                            emoji: '❓',
                            title: 'FAQ',
                            subtitle: 'Get answers quickly',
                            iconBackground: const Color(0xFFF3E5F5),
                            onTap: () => _open(const KidFaqPage()),
                          ),
                        ]),
                        const SizedBox(height: 20),
                        _buildLogoutButton(),
                      ],
                    ),
                  ),
                ),
                KidsBottomNav(selected: KidsTab.profile, onTap: _onNavTap),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB39DDB), _plum],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(color: _plumDark, offset: Offset(0, 6))],
      ),
      child: Column(
        children: [
          Container(
            width: 110,
            height: 110,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD54F), width: 4),
            ),
            child: CurrentKid.photo != null
                ? ClipOval(child: Image.memory(CurrentKid.photo!, fit: BoxFit.cover))
                : const DinoMascot(color: Color(0xFFB794F6), size: 86),
          ),
          const SizedBox(height: 10),
          Text(
            CurrentKid.name ?? 'Little Star',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '✉️ ${_loginEmail() ?? 'Not signed in'}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _plumDark),
            ),
          ),
          if (_age != null || _targetSound != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                if (_age != null) _buildInfoChip('🎂 $_age years old'),
                if (_targetSound != null) _buildInfoChip('🔤 Sound: $_targetSound'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }

  /// Email of the parent account that is logged in.
  String? _loginEmail() {
    try {
      return FirebaseAuth.instance.currentUser?.email;
    } catch (_) {
      // Firebase is not set up (e.g. in tests).
      return null;
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF6B4C7A)),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Color(0xFFE6DCEB), offset: Offset(0, 5))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required String emoji,
    required String title,
    required String subtitle,
    required Color iconBackground,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: iconBackground, borderRadius: BorderRadius.circular(16)),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _ink)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _soft)),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: Color(0xFFC9B3E0), size: 28),
          ],
        ),
      ),
    );
  }

  static const Map<String, String> _languages = {
    'English': 'English',
    'Bahasa Malaysia': 'Malay',
    'Chinese': 'Chinese',
    'Arabic': 'Arabic',
  };

  Widget _buildLanguagePicker() {
    final textStyle = Theme.of(context).textTheme.bodyMedium!.merge(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: _plumDark),
        );

    return Container(
      padding: const EdgeInsets.only(left: 10, right: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedLanguage,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: _plumDark),
          borderRadius: BorderRadius.circular(14),
          style: textStyle,
          // Short name when closed, so the row has room for its text.
          selectedItemBuilder: (context) => _languages.values
              .map((short) => Align(alignment: Alignment.centerLeft, child: Text(short, style: textStyle)))
              .toList(),
          items: _languages.keys
              .map((language) => DropdownMenuItem(value: language, child: Text(language)))
              .toList(),
          onChanged: (String? newValue) {
            if (newValue == null) return;
            final previous = selectedLanguage;
            setState(() {
              selectedLanguage = newValue;
            });
            _savePreference(
              language: newValue,
              message: 'Language saved: $newValue 🌐',
              undo: () => setState(() => selectedLanguage = previous),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFFF6B6B), width: 2.5),
          boxShadow: const [BoxShadow(color: Color(0xFFFFC9C9), offset: Offset(0, 5))],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('👋', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFFE53935)),
            ),
          ],
        ),
      ),
    );
  }

  void _onNavTap(KidsTab tab) {
    switch (tab) {
      case KidsTab.home:
        goToKidsHome(context);
        break;
      case KidsTab.game:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GamePage()),
        );
        break;
      case KidsTab.progress:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProgressPage()),
        );
        break;
      case KidsTab.profile:
        // Already on this page
        break;
    }
  }

  Future<void> _open(Widget page) {
    return Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _openEditProfile() async {
    await _open(const KidEditProfilePage());
    // Show the new name and photo.
    if (mounted) setState(() {});
  }

  Future<void> _openChangePassword() async {
    if (await askGrownUp(context) && mounted) {
      await _open(const ChangePasswordScreen());
    }
  }

  void _switchProfile() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const KidsProfileSelectionScreen()),
      (route) => route.isFirst,
    );
  }

  void _setReminders(bool value) {
    setState(() => isNotificationEnabled = value);
    _savePreference(
      practiceReminders: value,
      message: value ? 'Practice reminders on 🔔' : 'Practice reminders off',
      undo: () => setState(() => isNotificationEnabled = !value),
    );
  }

  /// Saves a preference in the child's profile. [undo] puts the switch back if saving fails.
  Future<void> _savePreference({
    bool? practiceReminders,
    String? language,
    required String message,
    VoidCallback? undo,
  }) async {
    try {
      await KidProfileStore.savePreferences(practiceReminders: practiceReminders, language: language);
      _showMessage(message);
    } catch (e) {
      if (mounted) undo?.call();
      _showMessage('Could not save. Please try again.');
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: const Color(0xFF8B5E9E),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _logout() async {
    try {
      await ParentStore.instance.signOut();
    } catch (e) {
      debugPrint('[Profile] Sign out failed: $e');
    }
    CurrentKid.id = null;
    CurrentKid.name = null;
    CurrentKid.photo = null;
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              color: Color(0xFF5D3A6B),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Color(0xFF8B5E9E)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFFC9B3E0)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFFE91E63),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}