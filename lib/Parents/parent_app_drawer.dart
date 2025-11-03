import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vraz_application/home_screen.dart';
import 'package:vraz_application/parent_session_manager.dart';
import 'package:vraz_application/universal_notification_service.dart';

import '../Student/service/firebase_notification_service.dart';
import 'attendance_report_screen.dart';
import 'grievance_chat_screen.dart';
import 'grievance_screen.dart';
import 'notifications_screen.dart';
import 'parent_teacher_meeting_screen.dart';
import 'parents_dashboard.dart';
import 'payments_screen.dart';
import 'results_screen.dart';
import 'timetable_screen.dart';

class ParentAppDrawer extends StatelessWidget {
  const ParentAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const UserAccountsDrawerHeader(
            accountName: Text(
              'Manoj Sharma',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text('manoj.sharma@example.com'),
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
            screen: const ParentDashboardScreen(),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.report_problem_outlined,
            text: 'Grievance',
            screen: const GrievanceScreen(),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.support_agent_outlined,
            text: 'Support Chat',
            screen: const GrievanceChatScreen(
              grievanceTitle: 'Support Chat',
              navigationSource: '',
            ),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.group_outlined,
            text: 'Parents-Teacher Meeting',
            screen: const ParentTeacherMeetingScreen(),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.calendar_today_outlined,
            text: 'Attendance Record',
            screen: const AttendanceReportScreen(),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.payment_outlined,
            text: 'Payment',
            screen: const PaymentsScreen(),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.emoji_events_outlined,
            text: 'Result',
            screen: const ResultsScreen(),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.notifications_outlined,
            text: 'Notification',
            screen: const NotificationsScreen(),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.schedule_outlined,
            text: 'Timetable',
            screen: const TimetableScreen(),
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
    print('🔍 [PARENT-LOGOUT] Starting logout process...');

    // ✅ SAVE NAVIGATOR & MESSENGER BEFORE ANY OPERATIONS
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final parentSessionManager = Provider.of<ParentSessionManager>(context, listen: false);

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
              print('🔍 [PARENT-LOGOUT] User cancelled');
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              print('🔍 [PARENT-LOGOUT] User confirmed');
              Navigator.of(dialogContext).pop(true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    print('🔍 [PARENT-LOGOUT] Confirmation result: $confirmed');
    if (confirmed != true) return;

    // Close drawer using saved navigator
    print('🔍 [PARENT-LOGOUT] Closing drawer...');
    navigator.pop();

    // Show loading snackbar
    print('🔍 [PARENT-LOGOUT] Showing loading snackbar...');
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
      print('🚪 Starting Parent logout...');

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

      // Clear parent session
      await parentSessionManager.clearSession();
      print('✅ Parent session cleared');

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('✅ SharedPreferences cleared');

      print('✅ Parent logout completed');

      // Navigate using saved navigator
      print('🔍 [PARENT-LOGOUT] Navigating to HomeScreen...');
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (newContext) {
            print('🔍 [PARENT-LOGOUT] Building HomeScreen...');
            return const HomeScreen();
          },
        ),
            (route) => false,
      );

      print('✅ [PARENT-LOGOUT] Navigation completed');

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
      print('❌ Parent logout error: $e');
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

    print('🔍 [PARENT-LOGOUT] Logout function completed');
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