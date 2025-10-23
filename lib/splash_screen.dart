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

    // Navigate to HomeScreen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo or Icon
            Icon(
              Icons.school,
              size: 100,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 20),
            // App Name
            const Text(
              'VRAZ LMS',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 10),
            // Tagline
            const Text(
              'Learning Management System',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator
            const CircularProgressIndicator(
              color: Colors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }
}