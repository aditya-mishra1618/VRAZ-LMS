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

// Parent
import 'package:vraz_application/Parents/parents_dashboard.dart';
import 'parent_session_manager.dart';

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
    print('🔍 [SplashScreen] Checking for existing sessions...');

    // Keep splash visible for at least 2 seconds for UX
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    try {
      // ============================================================
      // 1️⃣ CHECK STUDENT SESSION
      // ============================================================
      final sessionManager = Provider.of<SessionManager>(context, listen: false);

      // Wait for SessionManager to finish initialization
      int waitCount = 0;
      while (!sessionManager.isInitialized && waitCount < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
        if (!mounted) return;
      }

      if (sessionManager.isLoggedIn && sessionManager.currentUser != null) {
        print('✅ [SplashScreen] Student session found: ${sessionManager.currentUser!.fullName}');
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StudentDashboard()),
        );
        return;
      }

      print('ℹ️ [SplashScreen] No student session found');

      // ============================================================
      // 2️⃣ CHECK TEACHER/ADMIN SESSION
      // ============================================================
      final teacherSessionManager = Provider.of<TeacherSessionManager>(context, listen: false);

      if (!teacherSessionManager.isInitialized) {
        await teacherSessionManager.initialize();
      }

      if (teacherSessionManager.isLoggedIn && teacherSessionManager.currentTeacher != null) {
        final teacher = teacherSessionManager.currentTeacher!;
        print('✅ [SplashScreen] Teacher/Admin session found: ${teacher.fullName}');

        // Decide destination based on role
        final roleLower = (teacher.role ?? '').toString().toLowerCase();

        Widget destination;
        if (roleLower.contains('admin')) {
          destination = const AdminDashboardScreen();
          print('📍 [SplashScreen] Navigating to Admin Dashboard');
        } else {
          destination = const TeacherDashboardScreen();
          print('📍 [SplashScreen] Navigating to Teacher Dashboard');
        }

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => destination),
        );
        return;
      }

      print('ℹ️ [SplashScreen] No teacher/admin session found');

      // ============================================================
      // 3️⃣ CHECK PARENT SESSION
      // ============================================================
      final parentSessionManager = Provider.of<ParentSessionManager>(context, listen: false);

      final parentSessionExists = await parentSessionManager.loadSession();

      if (parentSessionExists &&
          parentSessionManager.isLoggedIn &&
          parentSessionManager.currentParent != null) {
        print('✅ [SplashScreen] Parent session found: ${parentSessionManager.currentParent!.fullName}');
        print('📍 [SplashScreen] Navigating to Parent Dashboard');

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
        );
        return;
      }

      print('ℹ️ [SplashScreen] No parent session found');

      // ============================================================
      // 4️⃣ NO SESSION FOUND -> GO TO HOME SCREEN
      // ============================================================
      print('ℹ️ [SplashScreen] No active session found. Navigating to HomeScreen.');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );

    } catch (e, stackTrace) {
      print('❌ [SplashScreen] Error checking sessions: $e');
      print('[SplashScreen] Stack trace: $stackTrace');

      // On error, navigate to HomeScreen
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            const Icon(
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
            const SizedBox(height: 20),
            // Loading text
            Text(
              'Checking session...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}