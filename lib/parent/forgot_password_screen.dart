import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'widgets/entry_ui.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailController.text.trim());

      if (!mounted) return;

      showEntryMessage(
        context,
        'If this email is registered, a password reset link will be sent. Please check your inbox or spam folder.',
        error: false,
        duration: const Duration(seconds: 5),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      final message = switch (e.code) {
        'invalid-email' => 'Please enter a valid email address.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'network-request-failed' => 'Network error. Check your internet connection.',
        'user-not-found' => 'No account found with this email.',
        _ => e.message ?? 'Unable to send password reset email.',
      };
      showEntryMessage(context, message);
    } catch (e) {
      if (!mounted) return;
      showEntryMessage(context, 'Something went wrong: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: EntryPage(
        title: 'Forgot password?',
        subtitle: 'Enter your email and we will send you a link to make a new password.',
        back: true,
        children: [
          EntryField(
            controller: emailController,
            hint: 'Email',
            icon: Icons.mail_outline_rounded,
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'Email is required';
              if (!email.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 8),
          EntryButton(label: 'Send reset link', onPressed: resetPassword, busy: isLoading),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: EntryColors.field, borderRadius: BorderRadius.circular(14)),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: EntryColors.soft),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Signed up with Google or Facebook? You do not have a TalkiePal password. '
                    'Just log in with the same button again.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: EntryColors.soft, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(height: 16),
          EntryLink(
            text: 'Remembered it? ',
            link: 'Back to log in',
            onTap: isLoading ? null : () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
