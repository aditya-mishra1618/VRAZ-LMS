import 'package:flutter/material.dart';

import 'Grievance_screen.dart';
import 'attendance_report_screen.dart';
import 'notifications_screen.dart';
import 'parent_app_drawer.dart';
import 'parent_teacher_meeting_screen.dart';
import 'payments_screen.dart';
import 'results_screen.dart';
// --- FIX: Removed old chat screen import ---
// import 'support_chat_screen.dart';
// --- FIX: Added new support ticket screen import ---
import 'support_ticket_screen.dart'; // Make sure this file name is correct
import 'timetable_screen.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black54),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'Parent Dashboard',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: ParentAppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildParentInfoCard(),
            const SizedBox(height: 24),
            _buildGridView(),
          ],
        ),
      ),
    );
  }

  Widget _buildParentInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.blue.shade100, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/profile.png'), // Placeholder
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parent',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Manoj Sharma', // Example Name
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    final gridItems = [
      {
        'icon': Icons.chat_bubble_outline,
        'label': 'Grievance',
        'colors': [Colors.lightBlue.shade100, Colors.lightBlue.shade200],
        'screen': const GrievanceScreen(),
      },
      {
        'icon': Icons.support_agent_outlined,
        'label': 'Support Chat', // Label remains 'Support Chat'
        'colors': [Colors.cyan.shade100, Colors.cyan.shade200],
        // --- FIX: Navigates to the SupportTicketScreen ---
        'screen': const SupportTicketScreen(),
      },
      {
        'icon': Icons.group_add_outlined,
        'label': 'Parent-Teacher Meeting',
        'colors': [Colors.purple.shade100, Colors.purple.shade200],
        'screen': const ParentTeacherMeetingScreen(),
      },
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Attendance Record',
        'colors': [Colors.orange.shade100, Colors.orange.shade200],
        'screen': const AttendanceReportScreen(),
      },
      {
        'icon': Icons.credit_card_outlined,
        'label': 'Payments Screen',
        'colors': [Colors.green.shade100, Colors.green.shade200],
        'screen': const PaymentsScreen(),
      },
      {
        'icon': Icons.emoji_events_outlined,
        'label': 'Results',
        'colors': [Colors.blue.shade100, Colors.blue.shade200],
        'screen': const ResultsScreen(),
      },
      {
        'icon': Icons.notifications_outlined,
        'label': 'Notifications',
        'colors': [Colors.red.shade100, Colors.red.shade200],
        'badge': '3',
        'screen': const NotificationsScreen(),
      },
      {
        'icon': Icons.schedule_outlined,
        'label': 'Timetable',
        'colors': [Colors.deepPurple.shade100, Colors.deepPurple.shade200],
        'screen': const TimetableScreen(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: gridItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final item = gridItems[index];
        return _buildGridItem(
          item['icon'] as IconData,
          item['label'] as String,
          item['colors'] as List<Color>,
          item['screen'] as Widget?,
          badge: item['badge'] as String?,
        );
      },
    );
  }

  Widget _buildGridItem(
      IconData icon, String label, List<Color> colors, Widget? screen,
      {String? badge}) {
    return InkWell(
      onTap: screen == null
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => screen),
              );
            },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 40, color: Colors.black.withOpacity(0.7)),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
