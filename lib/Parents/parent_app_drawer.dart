import 'package:flutter/material.dart';
import 'package:vraz_application/home_screen.dart';

import 'attendance_report_screen.dart';
import 'grievance_screen.dart';
import 'notifications_screen.dart';
import 'parent_teacher_meeting_screen.dart';
import 'parents_dashboard.dart';
import 'payments_screen.dart';
import 'results_screen.dart';
import 'support_chat_screen.dart';
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
