import 'package:flutter/material.dart';

import 'Grievance_screen.dart';
import 'attendance_report_screen.dart';
import 'notifications_screen.dart';
import 'parent_app_drawer.dart';
import 'parent_teacher_meeting_screen.dart';
import 'payments_screen.dart';
import 'results_screen.dart';
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
      drawer: const ParentAppDrawer(),
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
                'Manoj Sharma',
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
        'colors': [Colors.lightBlue.shade100, Colors.lightBlue.shade200]
      },
      {
        'icon': Icons.group_add_outlined,
        'label': 'Parent-Teacher Meeting',
        'colors': [Colors.purple.shade100, Colors.purple.shade200]
      },
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Attendance Record',
        'colors': [Colors.orange.shade100, Colors.orange.shade200]
      },
      {
        'icon': Icons.credit_card_outlined,
        'label': 'Payments Screen',
        'colors': [Colors.green.shade100, Colors.green.shade200]
      },
      {
        'icon': Icons.emoji_events_outlined,
        'label': 'Results',
        'colors': [Colors.blue.shade100, Colors.blue.shade200]
      },
      {
        'icon': Icons.notifications_outlined,
        'label': 'Notifications',
        'colors': [Colors.red.shade100, Colors.red.shade200],
        'badge': '3'
      },
      {
        'icon': Icons.schedule_outlined,
        'label': 'Timetable',
        'colors': [Colors.deepPurple.shade100, Colors.deepPurple.shade200]
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
          badge: item['badge'] as String?,
        );
      },
    );
  }

  Widget _buildGridItem(IconData icon, String label, List<Color> colors,
      {String? badge}) {
    return InkWell(
      onTap: () {
        // This navigation logic remains the same
        if (label == 'Grievance') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GrievanceScreen()),
          );
        } else if (label == 'Parent-Teacher Meeting') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ParentTeacherMeetingScreen()),
          );
        } else if (label == 'Attendance Record') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AttendanceReportScreen()),
          );
        } else if (label == 'Payments Screen') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PaymentsScreen()),
          );
        } else if (label == 'Results') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ResultsScreen()),
          );
        } else if (label == 'Notifications') {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const NotificationsScreen()),
          );
        } else if (label == 'Timetable') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TimetableScreen()),
          );
        }
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
