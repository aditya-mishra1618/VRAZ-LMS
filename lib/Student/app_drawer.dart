import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vraz_application/Student/service/firebase_notification_service.dart';
import 'package:vraz_application/home_screen.dart';
import 'package:vraz_application/student_session_manager.dart';
import 'package:vraz_application/universal_notification_service.dart';

import '../student_profile_provider.dart';
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
      child: Consumer<StudentProfileProvider>(
        builder: (context, profileProvider, child) {
          final profile = profileProvider.studentProfile;
          final studentName = profile?.studentUser.fullName ?? 'Student';
          final studentEmail = profile?.studentUser.email ?? 'email@example.com';
          final photoUrl = profile?.studentUser.photoUrl ?? '';

          return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              UserAccountsDrawerHeader(
                accountName: Text(
                  studentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                accountEmail: Text(studentEmail),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : const AssetImage('assets/profile.png') as ImageProvider,
                  backgroundColor: Colors.white,
                  onBackgroundImageError: photoUrl.isNotEmpty
                      ? (exception, stackTrace) {
                    print('⚠️ Error loading drawer profile image: $exception');
                  }
                      : null,
                ),
                decoration: const BoxDecoration(
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
              _buildDrawerItem(
                icon: Icons.logout,
                text: 'Logout',
                onTap: () => _handleLogout(context, sessionManager, profileProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleLogout(
      BuildContext context,
      SessionManager sessionManager,
      StudentProfileProvider profileProvider,
      ) async {
    print('🔍 [LOGOUT] Starting logout process...');

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

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

    print('🔍 [LOGOUT] Closing drawer...');
    navigator.pop();

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

    try {
      print('🚪 Starting Student logout...');

      // Clear profile provider FIRST
      profileProvider.clearProfile();
      print('✅ Profile provider cleared');

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

      print('🔍 [LOGOUT] Navigating to HomeScreen...');
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