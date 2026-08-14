import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';  // ADD THIS
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'choose_role_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;  // ADD THIS

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        // Firebase login
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        if (!mounted) return;
        
        // Navigate to ChooseRoleScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ChooseRoleScreen(),
          ),
        );
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'user-not-found') {
          message = 'No user found with this email';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password';
        } else if (e.code == 'invalid-email') {
          message = 'Invalid email format';
        } else {
          message = 'Login failed: ${e.message}';
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
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 250,
                      width: double.infinity,
                      color: const Color(0xFFF5EFE8),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Image.asset(
                            'lib/assets/images/logo.png',
                            width: 308,
                            height: 115,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.error,
                                size: 115,
                                color: Colors.grey,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      bottom: 0,
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(100),
                            topRight: Radius.circular(100),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Text(
                  'hello!',
                  style: GoogleFonts.hennyPenny(
                    color: const Color(0xFFD6D600),
                    fontSize: 32,
                  ),
                ),

                const SizedBox(height: 35),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Colors.grey,
                      ),
                      hintText: 'Email',
                      hintStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.black45),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.black),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
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
                ),

                const SizedBox(height: 18),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Colors.grey,
                      ),
                      hintText: 'Password',
                      hintStyle: const TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.black45),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.black),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
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
                ),

                const SizedBox(height: 5),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot your password?',
                      style: TextStyle(
                        color: Color(0xFFD6D600),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                Padding(
                  padding: const EdgeInsets.only(right: 25),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD6D600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      onPressed: isLoading ? null : login,
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
                                  'Login',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 55),

                const Text(
                  'Or sign in with',
                  style: TextStyle(
                    color: Color(0xFFD6D600),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'lib/assets/images/google.png',
                      width: 38,
                      height: 38,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error, size: 38);
                      },
                    ),
                    const SizedBox(width: 35),
                    const Icon(
                      Icons.facebook,
                      color: Colors.blue,
                      size: 42,
                    ),
                    const SizedBox(width: 35),
                    Image.asset(
                      'lib/assets/images/outlook.png',
                      width: 38,
                      height: 38,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error, size: 38);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 55),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Not Register Yet? ',
                      style: TextStyle(
                        color: Color(0xFFD6D600),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}