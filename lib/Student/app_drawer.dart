import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vraz_application/session_manager.dart'; // Import SessionManager for logout
import 'package:vraz_application/splash_screen.dart'; // For logout navigation

import 'assignment.dart';
import 'attendance.dart';
import 'courses.dart';
// --- FIX: Import the new Doubt Lecture screen ---
import 'doubt_lecture_screen.dart';
import 'doubts.dart';
import 'feedback.dart';
import 'notification.dart';
import 'result.dart';
import 'student_id.dart';
import 'timetable.dart';

// Central navigation drawer for the student section.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Access SessionManager to handle logout
    final sessionManager = Provider.of<SessionManager>(context, listen: false);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Drawer Header with user info (replace with dynamic data if needed)
          const UserAccountsDrawerHeader(
            accountName: Text(
              'Aryan Sharma', // Placeholder name
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text('aryan.sharma@example.com'), // Placeholder email
            currentAccountPicture: CircleAvatar(
              backgroundImage: AssetImage('assets/profile.png'), // Placeholder
            ),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
            ),
          ),
          // Navigation Items
          _buildDrawerItem(
            icon: Icons.dashboard_outlined,
            text: 'Dashboard',
            onTap: () {
              Navigator.pop(context); // Close drawer
              // Assuming StudentDashboard is the root, pop until there or pushReplacement
              // For simplicity, let's just pop for now if not already there.
              if (ModalRoute.of(context)?.settings.name != '/') {
                // Example check, adjust if your dashboard route is named differently
                // Or use Navigator.pushReplacement if always navigating anew
              }
            },
          ),
          _buildDrawerItem(
            icon: Icons.school_outlined,
            text: 'Courses',
            onTap: () => _navigateToScreen(context, const CoursesScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.calendar_today_outlined,
            text: 'Attendance',
            onTap: () => _navigateToScreen(context, const AttendanceScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.schedule_outlined,
            text: 'Timetable',
            onTap: () => _navigateToScreen(context, const TimetableScreen()),
          ),
          // --- NEW: Added Doubt Lecture item ---
          _buildDrawerItem(
            icon: Icons.question_answer_outlined,
            text: 'Doubt Lectures',
            onTap: () => _navigateToScreen(context, const DoubtLectureScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.assignment_outlined,
            text: 'Assignments',
            onTap: () => _navigateToScreen(context, const AssignmentsScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.help_outline,
            text: 'Doubts',
            onTap: () => _navigateToScreen(context, const DoubtsScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.quiz_outlined,
            text: 'Test Portal',
            onTap: () {
              // TODO: Navigate to Test Portal Screen
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            icon: Icons.person_pin_outlined,
            text: 'Student ID Card',
            onTap: () => _navigateToScreen(context, const StudentIdScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.emoji_events_outlined,
            text: 'Results',
            onTap: () => _navigateToScreen(context, const ResultsScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.notifications_outlined,
            text: 'Notifications',
            onTap: () =>
                _navigateToScreen(context, const NotificationsScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.feedback_outlined,
            text: 'Feedback',
            onTap: () => _navigateToScreen(context, const FeedbackScreen()),
          ),
          const Divider(),
          // Logout Item
          _buildDrawerItem(
            icon: Icons.logout,
            text: 'Logout',
            onTap: () async {
              Navigator.pop(context); // Close drawer first
              await sessionManager.logout(); // Clear the session
              // Navigate back to the splash/login screen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SplashScreen()),
                (Route<dynamic> route) => false, // Remove all previous routes
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper method to build ListTile items for the drawer.
  ListTile _buildDrawerItem(
      {required IconData icon,
      required String text,
      required GestureTapCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(text),
      onTap: onTap,
    );
  }

  // Helper method to navigate to a new screen after closing the drawer.
  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.pop(context); // Close the drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}
