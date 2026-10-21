import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'login_screen.dart';
import 'choose_role_screen.dart';
import 'user_profile_service.dart';
import 'widgets/entry_ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const String googleWebClientId = '474037018699-a247c8o37ul98a1l87mis96d3fq9icku.apps.googleusercontent.com';

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final rewritePasswordController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    rewritePasswordController.dispose();
    super.dispose();
  }

  void showMessage(String message, {bool error = true}) {
    if (!mounted) return;
    showEntryMessage(context, message, error: error);
  }

  void goToRoleScreen() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ChooseRoleScreen()),
      (route) => false,
    );
  }

  String firebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in.';
      case 'weak-password':
        return 'Please use a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'account-exists-with-different-credential':
        return 'This email uses another sign-in method. Sign in with that method first.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  Future<void> register() async {
    if (isLoading || !(formKey.currentState?.validate() ?? false)) return;
    setState(() => isLoading = true);
    try {
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      await result.user?.updateDisplayName(usernameController.text.trim());
      if (result.user != null) {
        await UserProfileService.syncUser(result.user!, username: usernameController.text);
      }
      // Firebase signs in the new user automatically after registration.
      goToRoleScreen();
    } on FirebaseAuthException catch (e) {
      showMessage(firebaseError(e));
    } catch (e) {
      showMessage('Registration failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> registerWithGoogle() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(serverClientId: googleWebClientId);
      final googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        throw StateError('Google did not return an ID token. Check OAuth configuration.');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final signedIn = await FirebaseAuth.instance.signInWithCredential(credential);
      if (signedIn.user != null) {
        await UserProfileService.syncUser(signedIn.user!);
      }
      goToRoleScreen();
    } on FirebaseAuthException catch (e) {
      showMessage(firebaseError(e));
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled) {
        showMessage('Google sign-in failed: $e');
      }
    } catch (e) {
      showMessage('Google sign-in failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> registerWithFacebook() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final result = await FacebookAuth.instance.login(permissions: ['public_profile', 'email']);
      if (result.status == LoginStatus.cancelled) return;
      if (result.status != LoginStatus.success || result.accessToken == null) {
        throw StateError(result.message ?? 'Facebook sign-in was not completed.');
      }
      final credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
      final signedIn = await FirebaseAuth.instance.signInWithCredential(credential);
      if (signedIn.user != null) {
        await UserProfileService.syncUser(signedIn.user!);
      }
      goToRoleScreen();
    } on FirebaseAuthException catch (e) {
      showMessage(firebaseError(e));
    } catch (e) {
      showMessage('Facebook sign-in failed: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: EntryPage(
        title: 'Create account',
        subtitle: 'Join TalkiePal to practice speech with your child',
        back: true,
        children: [
          EntryField(
            controller: emailController,
            hint: 'Email',
            icon: Icons.mail_outline_rounded,
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'Email is required';
              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          EntryField(
            controller: usernameController,
            hint: 'Username',
            icon: Icons.person_outline_rounded,
            enabled: !isLoading,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) => (value?.trim().isEmpty ?? true) ? 'Username is required' : null,
          ),
          EntryField(
            controller: passwordController,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            password: true,
            enabled: !isLoading,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          EntryField(
            controller: rewritePasswordController,
            hint: 'Confirm password',
            icon: Icons.lock_outline_rounded,
            password: true,
            enabled: !isLoading,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please re-write password';
              if (value != passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 8),
          EntryButton(label: 'Create account', onPressed: register, busy: isLoading),
          const SizedBox(height: 24),
          EntrySocialButtons(
            text: 'or sign up with',
            onGoogle: isLoading ? null : registerWithGoogle,
            onFacebook: isLoading ? null : registerWithFacebook,
          ),
          const Spacer(),
          const SizedBox(height: 16),
          EntryLink(
            text: 'Already have an account? ',
            link: 'Log in',
            onTap: isLoading
                ? null
                : () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          ),
        ],
      ),
    );
  }
}
