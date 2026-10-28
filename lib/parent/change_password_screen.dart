import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'widgets/parent_form.dart';
import 'widgets/parent_ui.dart';

/// Change the parent's password.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final formKey = GlobalKey<FormState>();

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Which fields show their text.
  final Set<TextEditingController> _shown = {};
  bool _saving = false;

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Widget passwordField({required String label, required TextEditingController controller}) {
    final shown = _shown.contains(controller);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: !shown,
        onChanged: (_) => setState(() {}),
        decoration: parentInputDecoration(
          label,
          suffix: IconButton(
            icon: Icon(shown ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: ParentColors.muted),
            onPressed: () => setState(() => shown ? _shown.remove(controller) : _shown.add(controller)),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return '$label is required';
          if (value.length < 6) return 'Minimum 6 characters';
          return null;
        },
      ),
    );
  }

  Future<void> changePassword() async {
    if (_saving || !formKey.currentState!.validate()) return;
    if (newPasswordController.text != confirmPasswordController.text) {
      _tell('Password does not match');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      _tell('Please sign in again.');
      return;
    }
    // Google and Facebook accounts have no TalkiePal password to change.
    if (!user.providerData.any((p) => p.providerId == EmailAuthProvider.PROVIDER_ID)) {
      _tell('You signed in with Google or Facebook. Change your password there.');
      return;
    }

    setState(() => _saving = true);
    try {
      // Firebase asks for the current password again before a password change.
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: currentPasswordController.text),
      );
      await user.updatePassword(newPasswordController.text);
      _tell('Password changed successfully');
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _tell(_errorText(e));
    } catch (e) {
      _tell('Could not change password: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _errorText(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Current password is incorrect.';
      case 'weak-password':
        return 'New password is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'requires-recent-login':
        return 'Please log out and log in again, then try once more.';
      default:
        return e.message ?? 'Could not change password.';
    }
  }

  void _tell(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final password = newPasswordController.text;
    final checks = [
      ('At least 6 characters', password.length >= 6),
      ('Contains a number', password.contains(RegExp(r'[0-9]'))),
      ('Passwords match', password.isNotEmpty && password == confirmPasswordController.text),
    ];

    return Form(
      key: formKey,
      child: ParentPage(
        header: const ParentHeader(title: 'Change password', subtitle: 'Keep your account safe', back: true),
        bottom: ParentSaveButton(label: 'Update password', busy: _saving, onPressed: changePassword),
        children: [
          ParentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ParentSectionTitle('Current password', icon: Icons.lock_outline_rounded),
                passwordField(label: 'Current password', controller: currentPasswordController),
              ],
            ),
          ),
          ParentCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ParentSectionTitle('New password', icon: Icons.key_rounded),
                passwordField(label: 'New password', controller: newPasswordController),
                passwordField(label: 'Confirm new password', controller: confirmPasswordController),
                const SizedBox(height: 4),
                for (final (text, ok) in checks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: ok ? const Color(0xFF43A047) : ParentColors.muted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          text,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: ok ? ParentColors.ink : ParentColors.soft,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
