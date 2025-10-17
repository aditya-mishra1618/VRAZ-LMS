import 'package:flutter/material.dart';
import 'package:vraz_application/home_screen.dart';

import 'hr_section_screen.dart';
import 'manageAttendanceScreen.dart';
import 'student_performance_screen.dart';
import 'syllabus_tracking_screen.dart';
// A placeholder screen for logout
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
            screen: TimetableScreen(), // No 'const' here
          ),
          const Divider(),
          _buildDrawerItem(
            context: context,
            icon: Icons.logout,
            text: 'Logout',
            screen: const HomeScreen(),
            isLogout: true,
          ),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required Widget screen,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(text),
      onTap: () {
        Navigator.pop(context);
        if (isLogout) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => screen),
            (Route<dynamic> route) => false,
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        }
      },
    );
  }
}
