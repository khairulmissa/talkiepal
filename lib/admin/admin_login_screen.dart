import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_dashboard.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();

  bool loading = false;
  bool obscure = true;

  static const Color cream = Color(0xFFFFF9E9);
  static const Color orange = Color(0xFFEF7D35);
  static const Color dark = Color(0xFF252525);
  static const Color inputColor = Color(0xFFFBF7EE);
  static const Color borderColor = Color(0xFFE9E5D7);

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _login() async {
    if (loading || !formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Unable to sign in.');
      }

      final token = await user.getIdTokenResult(true);

      if (token.claims?['admin'] != true) {
        await FirebaseAuth.instance.signOut();
        throw Exception('This account is not an administrator.');
      }

      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = document.data();

      if (data == null ||
          data['role'] != 'admin' ||
          data['isActive'] != true ||
          data['accountStatus'] != 'active') {
        await FirebaseAuth.instance.signOut();
        throw Exception('Admin account is inactive.');
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminDashboard(),
        ),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      _message(e.message ?? 'Authentication failed.');
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (email.text.trim().isEmpty) {
      _message('Please enter your email first.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.text.trim(),
      );

      _message(
        'If this account exists, check your email for reset instructions.',
      );
    } catch (e) {
      _message(e.toString());
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFB5B1A8),
        fontSize: 16,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Icon(
          icon,
          color: const Color(0xFF8B8981),
          size: 23,
        ),
      ),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 52,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: inputColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 20,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: orange,
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [    
        Image.asset(
          'lib/assets/images/talkiepal_logo_icon.png',
          width: 190,
          height: 160,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Logo error: $error');
            return const Icon(
              Icons.broken_image_outlined,
              size: 60,
              color: orange,
            );
          },
        ),


        const SizedBox(height: 12),

        const Text(
          'Welcome back!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: dark,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Login to manage TalkiePal system ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF66645E),
          ),
        ),

        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE8C9),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 17,
                color: orange,
              ),
              SizedBox(width: 6),
              Text(
                'ADMIN PORTAL',
                style: TextStyle(
                  color: Color(0xFFB76529),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(38),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: _inputDecoration(
                  hint: 'Email',
                  icon: Icons.mail_outline_rounded,
                ),
                validator: (value) {
                  if (value == null ||
                      !value.trim().contains('@')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: password,
                obscureText: obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) {
                  if (!loading) _login();
                },
                decoration: _inputDecoration(
                  hint: 'Password',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() => obscure = !obscure);
                    },
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFFA8A59B),
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your password';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: loading ? null : _forgotPassword,
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: orange,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                height: 58,
                child: ElevatedButton(
                  onPressed: loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: const Color(0xFFB85A25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 23,
                          width: 23,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  const Expanded(
                    child: Divider(color: borderColor),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    child: Text(
                      'Administrator access',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Divider(color: borderColor),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xFF88877F),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Authorized administrators only',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF88877F),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Back to ',
                      style: TextStyle(
                        color: Color(0xFF77746F),
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'Main Login',
                          style: TextStyle(
                            color: orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  children: [
                    // Header section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20, 30, 20, 30,
                      ),
                      child: Center(
                        child: _buildHeader(),
                      ),
                    ),

                    // Login panel
                    _buildLoginForm(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
