import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talkiepal/services/parent_store.dart';
import 'package:talkiepal/services/progress_store.dart';

import 'add_child_profile_screen.dart';
import 'child_profile_details_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'widgets/parent_ui.dart';

/// Parent Profile: account, children, preferences, help and log out.
class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  bool isNotificationOn = true;
  ParentInfo? parent;
  String? parentPhotoUrl;
  List<ChildProfile> children = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([ParentStore.instance.me(), ProgressStore.instance.children()]);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      String? signedPhotoUrl;
      if (uid != null) {
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          final path = doc.data()?['parentPhotoPath']?.toString();
          if (path != null && path.isNotEmpty) {
            signedPhotoUrl = await Supabase.instance.client.storage
                .from('parent-photos').createSignedUrl(path, 3600);
          }
        } catch (e) {
          debugPrint('[Profile] photo load failed: $e');
        }
      }
      if (!mounted) return;
      setState(() {
        parentPhotoUrl = signedPhotoUrl;
        parent = results[0] as ParentInfo;
        children = results[1] as List<ChildProfile>;
      });
    } catch (e) {
      debugPrint('[Profile] could not load: $e');
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ParentStore.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Log out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    _load();
  }

  void _showChildren() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              Text(
                'My children (${children.length} of 5)',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ParentColors.ink),
              ),
              const SizedBox(height: 12),
              if (children.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('No children added yet.', style: TextStyle(color: ParentColors.soft)),
                ),
              for (final child in children)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _SupabaseChildAvatar(child: child, radius: 20),
                  title: Text(
                    child.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: ParentColors.ink),
                  ),
                  subtitle: Text(
                    [
                      if (child.age != null) '${child.age} years',
                      child.targetSound == null ? 'No target sound' : 'Target /${child.targetSound}/',
                    ].join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: ParentColors.purple),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _open(ChildProfileDetailsScreen(childId: child.id));
                  },
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ParentColors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: children.length >= 5
                      ? null
                      : () {
                          Navigator.pop(sheetContext);
                          _open(const AddChildProfileScreen());
                        },
                  icon: const Icon(Icons.add_rounded),
                  label: Text(children.length >= 5 ? 'Maximum 5 children' : 'Add a child'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              const Text(
                'Language',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ParentColors.ink),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('English', style: TextStyle(fontWeight: FontWeight.w700)),
                trailing: const Icon(Icons.check_circle_rounded, color: ParentColors.purple),
                onTap: () => Navigator.pop(sheetContext),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: false,
                title: Text('Bahasa Melayu'),
                trailing: Text('Coming soon', style: TextStyle(fontSize: 12, color: ParentColors.soft)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = parent?.name ?? '';
    final email = parent?.email ?? '';

    return ParentPage(
      tab: ParentTab.profile,
      header: ParentHeader(
        title: 'Profile',
        below: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: ParentColors.yellow,
              backgroundImage: parentPhotoUrl == null ? null : NetworkImage(parentPhotoUrl!),
              child: parentPhotoUrl != null ? null : Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: ParentColors.purpleDark),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                    ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Parent · ${children.length} ${children.length == 1 ? 'child' : 'children'}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            ParentHeaderButton(Icons.edit_rounded, onTap: () => _open(const EditProfileScreen())),
          ],
        ),
      ),
      children: [
        _Group('Account', [
          _Row(Icons.person_outline_rounded, 'Edit profile', onTap: () => _open(const EditProfileScreen())),
          _Row(Icons.lock_outline_rounded, 'Change password', onTap: () => _open(const ChangePasswordScreen())),
        ]),
        _Group('Children', [
          _Row(
            Icons.child_care_rounded,
            'Manage children',
            color: const Color(0xFFF57C00),
            value: '${children.length} of 5',
            onTap: _showChildren,
          ),
        ]),
        _Group('Preferences', [
          _Row(
            Icons.notifications_none_rounded,
            'Notifications',
            color: const Color(0xFF1E88E5),
            trailing: Switch(
              value: isNotificationOn,
              activeThumbColor: Colors.white,
              activeTrackColor: ParentColors.purple,
              onChanged: (value) => setState(() {
                isNotificationOn = value;
              }),
            ),
          ),
          _Row(
            Icons.language_rounded,
            'Language',
            color: const Color(0xFF00897B),
            value: 'English',
            onTap: _showLanguage,
          ),
        ]),
        _Group('Support', [
          _Row(
            Icons.help_outline_rounded,
            'Help & FAQ',
            color: ParentColors.soft,
            onTap: () => _open(const HelpScreen()),
          ),
          _Row(
            Icons.privacy_tip_outlined,
            'Privacy policy',
            color: ParentColors.soft,
            onTap: () => _open(const PrivacyScreen()),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: GestureDetector(
            onTap: _showLogoutConfirmation,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Log out',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}


/// Shows the current child photo from private Supabase Storage.
/// Falls back to the existing avatar for children not yet migrated.
class _SupabaseChildAvatar extends StatelessWidget {
  final ChildProfile child;
  final double radius;

  const _SupabaseChildAvatar({required this.child, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return ParentChildAvatar(child, radius: radius);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('children')
          .doc(child.id)
          .snapshots(),
      builder: (context, snapshot) {
        final path = (snapshot.data?.data()?['childPhotoPath'] ?? '')
            .toString()
            .trim();
        if (path.isEmpty) {
          return ParentChildAvatar(child, radius: radius);
        }

        return FutureBuilder<String>(
          key: ValueKey(path),
          future: Supabase.instance.client.storage
              .from('child-photos')
              .createSignedUrl(path, 3600),
          builder: (context, photoSnapshot) {
            if (!photoSnapshot.hasData) {
              if (photoSnapshot.hasError) {
                debugPrint('[Child avatar] signed URL failed: ${photoSnapshot.error}');
              }
              return ParentChildAvatar(child, radius: radius);
            }
            return CircleAvatar(
              radius: radius,
              backgroundColor: ParentColors.yellow,
              backgroundImage: NetworkImage(photoSnapshot.data!),
              onBackgroundImageError: (error, stackTrace) {
                debugPrint('[Child avatar] image load failed: $error');
              },
            );
          },
        );
      },
    );
  }
}

/// A titled group of rows in one card.
class _Group extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const _Group(this.title, this.rows);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: ParentColors.soft,
              letterSpacing: 1,
            ),
          ),
        ),
        ParentCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: ParentColors.line),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Row(this.icon, this.title, {this.color = ParentColors.purple, this.value, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            ParentIconBox(icon, color, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ParentColors.ink),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: ParentColors.soft),
              ),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: ParentColors.muted),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: ParentColors.line, borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

/// Questions parents often ask.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const List<(String, String)> _faq = [
    (
      'How does TalkiePal score my child\'s speech?',
      'The phone listens while your child holds SPEAK and compares what it heard with the word. '
          '85% and up is great, 70–84% is almost there, and below 70% needs more practice.',
    ),
    (
      'Why does it say "I can\'t hear you"?',
      'Make sure the microphone is allowed, practice in a quiet room and ask your child to hold '
          'the button until it turns red, then speak close to the phone.',
    ),
    (
      'Where do I see my child\'s progress?',
      'Open Progress in the menu. Pick your child at the top to see their summary, levels, games '
          'and every session.',
    ),
    (
      'Is TalkiePal a replacement for a speech therapist?',
      'No. TalkiePal is for practice at home. Please talk to a speech therapist about your child\'s '
          'needs and use the scores as extra information.',
    ),
    (
      'Free Talk (AI) does not answer.',
      'Free Talk needs the TalkiePal AI server to be running and reachable from your phone. '
          'Try again later.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ParentPage(
      header: const ParentHeader(title: 'Help & FAQ', back: true),
      children: [
        for (final (question, answer) in _faq)
          ParentCard(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Material(
              type: MaterialType.transparency,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  iconColor: ParentColors.purple,
                  title: Text(
                    question,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ParentColors.ink),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  children: [
                    Text(
                      answer,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ParentColors.ink,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// How TalkiePal uses the family's data.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const List<(IconData, String, String)> _points = [
    (
      Icons.person_outline_rounded,
      'What we keep',
      'Your account, your children\'s profiles and the results of each practice and game: '
          'scores, tries, time and the words the phone heard.',
    ),
    (
      Icons.mic_none_rounded,
      'Voice',
      'Your child\'s voice is turned into text on the phone to give a score. TalkiePal does not '
          'save voice recordings.',
    ),
    (
      Icons.lock_outline_rounded,
      'Who can see it',
      'Only you, signed in to your account, can see your children\'s data. Therapists will only '
          'see a child\'s progress when you choose to share it.',
    ),
    (
      Icons.delete_outline_rounded,
      'Deleting data',
      'You can ask us to delete your account and all your children\'s data at any time.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ParentPage(
      header: const ParentHeader(title: 'Privacy policy', back: true),
      children: [
        for (final (icon, title, text) in _points)
          ParentCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ParentIconBox(icon, ParentColors.purple, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ParentColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: ParentColors.ink,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
