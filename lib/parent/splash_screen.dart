import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double logoSize = 0.5;
  double opacity = 0.0;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        logoSize = 1.0;
        opacity = 1.0;
      });
    });

    Future.delayed(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF8),
      body: Center(
        child: AnimatedOpacity(
          opacity: opacity,
          duration: const Duration(seconds: 1),
          child: AnimatedScale(
            scale: logoSize,
            duration: const Duration(seconds: 1),
            curve: Curves.easeOutBack,
            child: Image.asset(
              'lib/assets/images/logo.png',
              width: 260,
              height: 260,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}