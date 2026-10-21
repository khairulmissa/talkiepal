import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../therapist/therapist_dashboard.dart';
import 'choose_role_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'user_profile_service.dart';
import 'widgets/entry_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showError(String message) {
    if (!mounted) return;
    showEntryMessage(context, message);
  }

  Future<void> _completeLogin(User user) async {
    // syncUser must preserve existing Firestore role and approval fields.
    await UserProfileService.syncUser(user);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = snapshot.data() ?? <String, dynamic>{};
    if (!mounted) return;

    final role = data['role']?.toString().toLowerCase().trim();
    if (role == 'therapist') {
      final active = data['isActive'] == true;
      final verified = data['verificationStatus']?.toString().toLowerCase() ==
          'verified';
      if (!active || !verified) {
        showError('Your therapist account is not active or is awaiting verification.');
        // Do not route unapproved therapists into parent mode.
        await FirebaseAuth.instance.signOut();
        return;
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const TherapistDashboard()),
        (route) => false,
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ChooseRoleScreen()),
    );
  }

  Future<void> login() async {
    if (isLoading || !(formKey.currentState?.validate() ?? false)) return;
    setState(() => isLoading = true);
    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (result.user == null) throw StateError('No user returned by Firebase.');
      await _completeLogin(result.user!);
    } on FirebaseAuthException catch (e) {
      showError(_firebaseError(e));
    } catch (e) {
      showError('Login failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loginWithGoogle() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        serverClientId:
            '474037018699-a247c8o37ul98a1l87mis96d3fq9icku.apps.googleusercontent.com',
      );
      final googleUser = await googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw StateError('Google did not return an ID token. Check Firebase configuration.');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      if (result.user == null) throw StateError('No user returned by Firebase.');
      await _completeLogin(result.user!);
    } on FirebaseAuthException catch (e) {
      showError(_firebaseError(e));
    } catch (e) {
      showError('Google sign-in failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loginWithFacebook() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );
      if (result.status == LoginStatus.cancelled) return;
      if (result.status != LoginStatus.success || result.accessToken == null) {
        throw StateError(result.message ?? 'Facebook login was not completed.');
      }
      final credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );
      final signedIn = await FirebaseAuth.instance.signInWithCredential(credential);
      if (signedIn.user == null) throw StateError('No user returned by Firebase.');
      await _completeLogin(signedIn.user!);
    } on FirebaseAuthException catch (e) {
      showError(_firebaseError(e));
    } catch (e) {
      showError('Facebook sign-in failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _firebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password, or no matching account.';
      case 'account-exists-with-different-credential':
        return 'This email is linked to another sign-in method.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: EntryPage(
        title: 'Welcome back!',
        subtitle: 'Log in to continue your child\'s practice',
        children: [
          EntryField(
            controller: emailController,
            hint: 'Email',
            icon: Icons.mail_outline_rounded,
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Email is required';
              if (!value.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          EntryField(
            controller: passwordController,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            password: true,
            enabled: !isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: isLoading
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: EntryColors.orange,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          EntryButton(label: 'Log in', onPressed: login, busy: isLoading),
          const SizedBox(height: 24),
          EntrySocialButtons(
            onGoogle: isLoading ? null : loginWithGoogle,
            onFacebook: isLoading ? null : loginWithFacebook,
          ),
          const Spacer(),
          const SizedBox(height: 16),
          EntryLink(
            text: 'New to TalkiePal? ',
            link: 'Create account',
            onTap: isLoading
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
          ),
        ],
      ),
    );
  }
}
