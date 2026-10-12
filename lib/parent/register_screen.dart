import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'login_screen.dart';
import 'choose_role_screen.dart';
import 'user_profile_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const String googleWebClientId =
      '474037018699-a247c8o37ul98a1l87mis96d3fq9icku.apps.googleusercontent.com';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
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
      final result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );
      if (result.status == LoginStatus.cancelled) return;
      if (result.status != LoginStatus.success || result.accessToken == null) {
        throw StateError(result.message ?? 'Facebook sign-in was not completed.');
      }
      final credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );
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

  Widget inputBox(
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: TextFormField(
        controller: controller,
        enabled: !isLoading,
        keyboardType: keyboardType,
        obscureText: obscure,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey, size: 24),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(35),
            borderSide: const BorderSide(color: Colors.black54),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(35),
            borderSide: const BorderSide(color: Colors.black),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(35),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(35),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget star(double size) => Icon(
        Icons.star,
        color: const Color(0xFFFFEFA8),
        size: size,
      );

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xFFD6D600);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(top: -35, right: -30, child: star(180)),
            Positioned(left: -45, top: 240, child: star(180)),
            Positioned(right: -45, bottom: 15, child: star(200)),
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 28),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 75),
                    Text(
                      'REGISTER ACCOUNT',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hennyPenny(
                        color: yellow,
                        fontSize: 38,
                      ),
                    ),
                    const SizedBox(height: 45),
                    inputBox(
                      'Email',
                      Icons.email_outlined,
                      emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Email is required';
                        if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    inputBox(
                      'Username',
                      Icons.person_outline,
                      usernameController,
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Username is required'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    inputBox(
                      'Password',
                      Icons.lock_outline,
                      passwordController,
                      obscure: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Password is required';
                        if (value.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    inputBox(
                      'Re-write Password',
                      Icons.lock_outline,
                      rewritePasswordController,
                      obscure: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please re-write password';
                        if (value != passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.only(right: 30),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: yellow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(35),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Register',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Icon(Icons.arrow_forward, color: Colors.white, size: 22),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              ),
                      child: const Text(
                        'Already have an account',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Or sign up with',
                      style: TextStyle(
                        color: yellow,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: isLoading ? null : registerWithGoogle,
                          borderRadius: BorderRadius.circular(30),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Image.asset(
                              'lib/assets/images/google.png',
                              width: 45,
                              height: 45,
                              errorBuilder: (_, _, _) => const Icon(Icons.error, size: 45),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                        InkWell(
                          onTap: isLoading ? null : registerWithFacebook,
                          borderRadius: BorderRadius.circular(30),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.facebook, color: Colors.blue, size: 50),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
