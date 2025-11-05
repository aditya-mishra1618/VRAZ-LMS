import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vraz_application/Teacher/manage_attendance_Screen.dart';
import 'package:vraz_application/home_screen.dart';
import 'package:vraz_application/teacher_session_manager.dart';
import 'package:vraz_application/universal_notification_service.dart';

import '../Student/service/firebase_notification_service.dart';
import 'hr_section_screen.dart';
import 'student_performance_screen.dart';
import 'syllabus_tracking_screen.dart';
import 'teacher_dashboard_screen.dart';
import 'teacher_doubts_screen.dart';
import 'teacher_notifications_screen.dart';
import 'timetable_screen.dart';
import 'upload_assignment_screen.dart';

class TeacherAppDrawer extends StatelessWidget {
  const TeacherAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const UserAccountsDrawerHeader(
            accountName: Text(
              'Prof. RamSwaroop',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text('Mathematics'),
            currentAccountPicture: CircleAvatar(
              backgroundImage: AssetImage('assets/profile.png'),
            ),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
            ),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.dashboard_outlined,
            text: 'Dashboard',
            screen: const TeacherDashboardScreen(),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.check_box_outlined,
            text: 'Manage Attendance',
            screen: const ManageAttendanceScreen(),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.assignment_turned_in_outlined,
            text: 'Syllabus Tracking',
            screen: const SyllabusTrackingScreen(),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.upload_file_outlined,
            text: 'Upload Assignment',
            screen: const UploadAssignmentScreen(),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.help_outline,
            text: 'Doubts',
            screen: const TeacherDoubtsScreen(),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.bar_chart_outlined,
            text: 'Student Performance',
            screen: const StudentPerformanceScreen(),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.notifications_outlined,
            text: 'Notifications',
            screen: const TeacherNotificationsScreen(),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.business_center_outlined,
            text: 'HR Section',
            screen: const HRSectionScreen(),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.schedule_outlined,
            text: 'Timetable',
            screen: TimetableScreen(),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.grey[700]),
            title: const Text('Logout'),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  // ✅ BULLETPROOF LOGOUT FUNCTION
  Future<void> _handleLogout(BuildContext context) async {
    print('🔍 [TEACHER-LOGOUT] Starting logout process...');

    // ✅ SAVE NAVIGATOR & MESSENGER BEFORE ANY OPERATIONS
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final teacherSessionManager = Provider.of<TeacherSessionManager>(context, listen: false);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              print('🔍 [TEACHER-LOGOUT] User cancelled');
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              print('🔍 [TEACHER-LOGOUT] User confirmed');
              Navigator.of(dialogContext).pop(true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    print('🔍 [TEACHER-LOGOUT] Confirmation result: $confirmed');
    if (confirmed != true) return;

    // Close drawer using saved navigator
    print('🔍 [TEACHER-LOGOUT] Closing drawer...');
    navigator.pop();

    // Show loading snackbar
    print('🔍 [TEACHER-LOGOUT] Showing loading snackbar...');
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Logging out...'),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blueAccent,
      ),
    );

    try {
      print('🚪 Starting Teacher logout...');

      // Delete FCM token
      try {
        await FirebaseNotificationService().deleteToken();
        print('✅ FCM token deleted');
      } catch (e) {
        print('⚠️ Error deleting FCM token: $e');
      }

      // Clear notifications
      try {
        await UniversalNotificationService.instance.clearAll();
        print('✅ Cleared local notifications');
      } catch (e) {
        print('⚠️ Failed to clear notifications: $e');
      }

      // Clear teacher session
      await teacherSessionManager.clearSession();
      print('✅ Teacher session cleared');

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('✅ SharedPreferences cleared');

      print('✅ Teacher logout completed');

      // Navigate using saved navigator
      print('🔍 [TEACHER-LOGOUT] Navigating to HomeScreen...');
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (newContext) {
            print('🔍 [TEACHER-LOGOUT] Building HomeScreen...');
            return const HomeScreen();
          },
        ),
            (route) => false,
      );

      print('✅ [TEACHER-LOGOUT] Navigation completed');

      // Show success message
      Future.delayed(const Duration(milliseconds: 500), () {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Logged out successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      });
    } catch (e, stack) {
      print('❌ Teacher logout error: $e');
      print('Stack trace: $stack');

      // Force navigation even on error
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Logged out with errors: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    print('🔍 [TEACHER-LOGOUT] Logout function completed');
  }

  ListTile _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required Widget screen,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(text),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
    );
  }
}