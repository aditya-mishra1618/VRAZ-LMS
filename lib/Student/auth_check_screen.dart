import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vraz_application/Admin/admin_dashboard_screen.dart';
import 'package:vraz_application/Parents/parents_dashboard.dart';
import 'package:vraz_application/Student/Student_dashboard.dart';
import 'package:vraz_application/Teacher/Teacher_Dashboard_Screen.dart';
import 'package:vraz_application/home_screen.dart';
import 'package:vraz_application/session_manager.dart';

class AuthCheckScreen extends StatelessWidget {
  const AuthCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a Consumer to listen for changes in the SessionManager
    return Consumer<SessionManager>(
      builder: (context, sessionManager, child) {
        // While the session is being loaded from storage, show a loading indicator
        if (!sessionManager.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Once initialized, check if the user is logged in
        if (sessionManager.isLoggedIn) {
          // If logged in, check their role and navigate to the correct dashboard
          final userRole = sessionManager.currentUser?.role.toLowerCase();
          switch (userRole) {
            case 'student':
              return const StudentDashboard();
            case 'parent':
              return const ParentDashboardScreen();
            case 'teacher':
              return const TeacherDashboardScreen();
            case 'admin':
              return const AdminDashboardScreen();
            default:
              // Fallback to role selection if the role is unknown
              return const HomeScreen();
          }
        } else {
          // If not logged in, show the role selection screen
          return const HomeScreen();
        }
      },
    );
  }
}
