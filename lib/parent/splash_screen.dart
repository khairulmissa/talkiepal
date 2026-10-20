import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'widgets/entry_ui.dart';

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
      if (!mounted) return;
      setState(() {
        logoSize = 1.0;
        opacity = 1.0;
      });
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EntryColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            AnimatedOpacity(
              opacity: opacity,
              duration: const Duration(seconds: 1),
              child: AnimatedScale(
                scale: logoSize,
                duration: const Duration(seconds: 1),
                curve: Curves.easeOutBack,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 44),
                  child: Image.asset(EntryLogo.full, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 28),
            AnimatedOpacity(
              opacity: opacity,
              duration: const Duration(milliseconds: 1500),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final color in [EntryColors.yellow, EntryColors.orange, EntryColors.teal])
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
            const Spacer(flex: 3),
            const Text(
              'Speech practice for little voices',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: EntryColors.soft),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
