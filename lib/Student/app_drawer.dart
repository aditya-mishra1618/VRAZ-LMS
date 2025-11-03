import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vraz_application/Student/service/firebase_notification_service.dart';
import 'package:vraz_application/home_screen.dart';
import 'package:vraz_application/student_session_manager.dart';
import 'package:vraz_application/universal_notification_service.dart';

import 'assignment.dart';
import 'attendance.dart';
import 'courses.dart';
import 'doubt_lecture_screen.dart';
import 'doubts.dart';
import 'feedback.dart';
import 'notification.dart';
import 'result.dart';
import 'student_id.dart';
import 'timetable.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionManager = Provider.of<SessionManager>(context, listen: false);

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
            onTap: () => Navigator.pop(context),
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
            onTap: () => Navigator.pop(context),
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
            onTap: () => _navigateToScreen(context, const NotificationsScreen()),
          ),
          _buildDrawerItem(
            icon: Icons.feedback_outlined,
            text: 'Feedback',
            onTap: () => _navigateToScreen(context, const FeedbackScreen()),
          ),
          const Divider(),
          // ✅ FIXED LOGOUT
          _buildDrawerItem(
            icon: Icons.logout,
            text: 'Logout',
            onTap: () => _handleLogout(context, sessionManager),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, SessionManager sessionManager) async {
    print('🔍 [LOGOUT] Starting logout process...');

    // ✅ SAVE THE NAVIGATOR BEFORE ANY OPERATIONS
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 1. Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              print('🔍 [LOGOUT] User cancelled logout');
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              print('🔍 [LOGOUT] User confirmed logout');
              Navigator.of(dialogContext).pop(true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    print('🔍 [LOGOUT] Confirmation result: $confirmed');
    if (confirmed != true) {
      print('🔍 [LOGOUT] Logout cancelled by user');
      return;
    }

    // 2. Close drawer using saved navigator
    print('🔍 [LOGOUT] Closing drawer...');
    navigator.pop();

    // 3. Show loading snackbar using saved messenger
    print('🔍 [LOGOUT] Showing loading snackbar...');
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

    // 4. Perform logout operations
    try {
      print('🚪 Starting Student logout...');

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

      // Clear session manager
      await sessionManager.logout();
      print('✅ Session manager cleared');

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('✅ SharedPreferences cleared');

      // Clear secure storage
      const secureStorage = FlutterSecureStorage();
      await secureStorage.deleteAll();
      print('✅ Secure storage cleared');

      print('✅ Student logout completed');

      // 5. Navigate using saved navigator (GUARANTEED TO WORK)
      print('🔍 [LOGOUT] Navigating to HomeScreen using saved navigator...');
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (newContext) {
            print('🔍 [LOGOUT] Building HomeScreen...');
            return const HomeScreen();
          },
        ),
            (route) {
          print('🔍 [LOGOUT] Removing route: ${route.settings.name}');
          return false;
        },
      );

      print('✅ [LOGOUT] Navigation completed successfully');

      // 6. Show success message
      Future.delayed(const Duration(milliseconds: 500), () {
        print('🔍 [LOGOUT] Showing success message...');
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Logged out successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      });
    } catch (e, stack) {
      print('❌ Logout error: $e');
      print('Stack trace: $stack');

      // Force navigation even on error
      print('🔍 [LOGOUT] Error occurred, forcing navigation...');
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

    print('🔍 [LOGOUT] Logout function completed');
  }

  ListTile _buildDrawerItem({
    required IconData icon,
    required String text,
    required GestureTapCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(text),
      onTap: onTap,
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}