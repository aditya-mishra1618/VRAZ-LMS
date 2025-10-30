import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Student
import 'package:vraz_application/Student/Student_dashboard_screen.dart';
import 'student_session_manager.dart';

// Teacher/Admin
import 'package:vraz_application/Teacher/Teacher_Dashboard_Screen.dart';
import 'Admin/admin_dashboard_screen.dart';
import 'teacher_session_manager.dart';

// Fallback
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
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // keep splash visible for at least 2 seconds for UX
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // 1) Check Student session first
    final sessionManager = Provider.of<SessionManager>(context, listen: false);

    // Wait for SessionManager to finish initialization
    while (!sessionManager.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    if (sessionManager.isLoggedIn && sessionManager.currentUser != null) {
      print('✅ Student auto-login: ${sessionManager.currentUser!.fullName}');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StudentDashboard()),
      );
      return;
    }

    // 2) If no student session, check teacher/admin session
    final teacherSessionManager = Provider.of<TeacherSessionManager>(context, listen: false);
    await teacherSessionManager.initialize();

    if (teacherSessionManager.isLoggedIn && teacherSessionManager.currentTeacher != null) {
      final teacher = teacherSessionManager.currentTeacher!;
      print('✅ Teacher/Admin auto-login: ${teacher.fullName}');

      // Decide destination based on teacher model role if available
      final roleLower = (teacher.role ?? '').toString().toLowerCase();

      Widget destination;
      if (roleLower.contains('admin')) {
        destination = const AdminDashboardScreen();
      } else {
        destination = const TeacherDashboardScreen();
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => destination),
      );
      return;
    }

    // 3) No active session found -> go to HomeScreen (role selection / login)
    print('ℹ️ No active student/teacher session found. Navigating to HomeScreen.');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
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