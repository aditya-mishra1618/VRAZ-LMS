import 'dart:async';

import 'package:flutter/material.dart';

import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start the navigation timer. This doesn't need the context and is safe here.
    Timer(const Duration(seconds: 5), () {
      // The `context` is available here because this code runs after the build method has completed.
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  // `didChangeDependencies` is called after `initState` and is the correct place
  // for code that needs access to the widget's context.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // We pre-cache the image here to ensure it's loaded smoothly.
    precacheImage(const AssetImage('assets/splash.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: 150,
          height: 150,
          child: Image.asset('assets/splash.png'),
        ),
      ),
    );
  }
}
