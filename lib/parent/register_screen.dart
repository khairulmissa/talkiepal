import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';  // ADD THIS
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final rewritePasswordController = TextEditingController();
  bool isLoading = false;  // ADD THIS

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    rewritePasswordController.dispose();
    super.dispose();
  }

  Widget inputBox(
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: SizedBox(
        height: 58,
        child: TextFormField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey, size: 24),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.zero,
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
      ),
    );
  }

  Widget star(double size) {
    return Icon(
      Icons.star,
      color: const Color(0xFFFFEFA8),
      size: size,
    );
  }

  Future<void> register() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        // Create user with Firebase
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        // Update display name (username)
        await userCredential.user?.updateDisplayName(usernameController.text.trim());
        await userCredential.user?.reload();

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Register successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'email-already-in-use') {
          message = 'Email already registered';
        } else if (e.code == 'weak-password') {
          message = 'Password is too weak (minimum 6 characters)';
        } else if (e.code == 'invalid-email') {
          message = 'Invalid email format';
        } else {
          message = 'Registration failed: ${e.message}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFF8F5F2),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -35,
                right: -30,
                child: star(180),
              ),
              Positioned(
                left: -45,
                top: 240,
                child: star(180),
              ),
              Positioned(
                right: -45,
                bottom: 15,
                child: star(200),
              ),
              Form(
                key: formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 75),
                    Text(
                      'REGISTER ACCOUNT',
                      style: GoogleFonts.hennyPenny(
                        color: const Color(0xFFD6D600),
                        fontSize: 38,
                      ),
                    ),
                    const SizedBox(height: 45),
                    inputBox(
                      'Email',
                      Icons.email_outlined,
                      emailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@')) {
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Username is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    inputBox(
                      'Password',
                      Icons.lock_outline,
                      passwordController,
                      obscure: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
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
                        if (value == null || value.isEmpty) {
                          return 'Please re-write password';
                        }
                        if (value != passwordController.text) {
                          return 'Password does not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.only(right: 30),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD6D600),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(35),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 13,
                            ),
                          ),
                          onPressed: isLoading ? null : register,
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
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
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
                        color: Color(0xFFD6D600),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'lib/assets/images/google.png',
                          width: 45,
                          height: 45,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.error, size: 45);
                          },
                        ),
                        const SizedBox(width: 40),
                        const Icon(
                          Icons.facebook,
                          color: Colors.blue,
                          size: 50,
                        ),
                        const SizedBox(width: 40),
                        Image.asset(
                          'lib/assets/images/outlook.png',
                          width: 45,
                          height: 45,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.error, size: 45);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}