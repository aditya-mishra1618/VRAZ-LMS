import 'package:flutter/material.dart';

// This file is in the parent 'lib' directory, so its path is correct
import '../home_screen.dart';
import 'Courses.dart';
import 'Doubts.dart';
import 'assignment.dart';
import 'attendance.dart';
import 'feedback.dart';
import 'result.dart';
// Corrected import paths to look inside the current 'student' directory
import 'student_dashboard.dart';
import 'student_id.dart';
import 'timetable.dart';

// The settings_screen import has been removed.

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _navigate(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _logout(BuildContext context) {
    // Navigate back to the role selection screen and remove all previous screens
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const UserAccountsDrawerHeader(
            accountName: Text(
              'Aryan Sharma',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text('aryan.sharma@example.com'),
            currentAccountPicture: CircleAvatar(
              backgroundImage: AssetImage('assets/profile.png'),
            ),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
            ),
          ),
          _buildDrawerItem(
              icon: Icons.dashboard_outlined,
              text: 'Dashboard',
              // Assuming class names like StudentDashboard, AttendanceScreen etc.
              onTap: () => _navigate(context, const StudentDashboard())),
          _buildDrawerItem(
              icon: Icons.calendar_today_outlined,
              text: 'Attendance',
              onTap: () => _navigate(context, const AttendanceScreen())),
          _buildDrawerItem(
              icon: Icons.school_outlined,
              text: 'Courses',
              onTap: () => _navigate(context, const CoursesScreen())),
          _buildDrawerItem(
              icon: Icons.assignment_outlined,
              text: 'Assignment',
              onTap: () => _navigate(context, const AssignmentsScreen())),
          _buildDrawerItem(
              icon: Icons.schedule_outlined,
              text: 'Timetable',
              onTap: () => _navigate(context, const TimetableScreen())),
          _buildDrawerItem(
              icon: Icons.help_outline,
              text: 'Doubts',
              onTap: () => _navigate(context, const DoubtsScreen())),
          _buildDrawerItem(
              icon: Icons.quiz_outlined, text: 'Test Portal', onTap: () {}),
          _buildDrawerItem(
              icon: Icons.person_pin_outlined,
              text: 'Student ID',
              onTap: () => _navigate(context, const StudentIdScreen())),
          _buildDrawerItem(
              icon: Icons.emoji_events_outlined,
              text: 'Result',
              onTap: () => _navigate(context, const ResultsScreen())),
          _buildDrawerItem(
              icon: Icons.feedback_outlined,
              text: 'Feedback',
              onTap: () => _navigate(context, const FeedbackScreen())),
          const Divider(),
          // The Settings button has been removed.
          _buildDrawerItem(
              icon: Icons.logout,
              text: 'Logout',
              onTap: () => _logout(context)),
        ],
      ),
    );
  }

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
}
