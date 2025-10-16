import 'package:flutter/material.dart';

import 'app_drawer.dart';
import 'assignment.dart';
import 'attendance.dart';
import 'courses.dart';
import 'doubts.dart';
import 'feedback.dart';
import 'notification.dart';
import 'result.dart';
import 'student_id.dart';
import 'timetable.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(),
                const SizedBox(height: 24),
                _buildStudentInfoCard(),
                const SizedBox(height: 24),
                _buildTopCards(),
                const SizedBox(height: 24),
                _buildGridView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black54, size: 30),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        const SizedBox(width: 8),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            Text(
              'Aryan Sharma',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          icon:
              const Icon(Icons.notifications_none_rounded, color: Colors.grey),
          onPressed: () => _navigateTo(const NotificationsScreen()),
        ),
        const SizedBox(width: 8),
        const CircleAvatar(
          backgroundImage:
              AssetImage('assets/profile.png'), // Ensure you have this asset
        ),
      ],
    );
  }

  Widget _buildStudentInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Aryan Sharma',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Spacer(),
          const CircleAvatar(
            radius: 20,
            backgroundImage:
                AssetImage('assets/profile.png'), // Ensure you have this asset
          ),
        ],
      ),
    );
  }

  Widget _buildTopCards() {
    return Row(
      children: [
        Expanded(
          child: _buildTopCard(
            color: const Color(0xFFFE7453),
            title: 'Crash Courses',
            subtitle: 'Intensive learning',
            buttonText: 'Explore',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTopCard(
            color: const Color(0xFF28C27D),
            title: 'Free Lectures',
            subtitle: 'Knowledge for all',
            buttonText: 'Watch Now',
          ),
        ),
      ],
    );
  }

  Widget _buildTopCard(
      {required Color color,
      required String title,
      required String subtitle,
      required String buttonText}) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    final List<Map<String, dynamic>> gridItems = [
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Attendance',
        'onTap': () => _navigateTo(const AttendanceScreen())
      },
      {
        'icon': Icons.school_outlined,
        'label': 'Courses',
        'onTap': () => _navigateTo(const CoursesScreen())
      },
      {
        'icon': Icons.schedule_outlined,
        'label': 'Timetable',
        'onTap': () => _navigateTo(const TimetableScreen())
      },
      {
        'icon': Icons.assignment_outlined,
        'label': 'Assignments',
        'onTap': () => _navigateTo(const AssignmentsScreen())
      },
      {
        'icon': Icons.help_outline,
        'label': 'Doubts',
        'onTap': () => _navigateTo(const DoubtsScreen())
      },
      {'icon': Icons.quiz_outlined, 'label': 'Test Portal', 'onTap': () {}},
      {
        'icon': Icons.person_pin_outlined,
        'label': 'Student ID Card',
        'onTap': () => _navigateTo(const StudentIdScreen())
      },
      {
        'icon': Icons.emoji_events_outlined,
        'label': 'Results',
        'onTap': () => _navigateTo(const ResultsScreen())
      },
      {
        'icon': Icons.feedback_outlined,
        'label': 'Feedback',
        'onTap': () => _navigateTo(const FeedbackScreen())
      },
    ];

    final List<Color> cardColors = [
      Colors.orange.shade300,
      Colors.blue.shade300,
      Colors.teal.shade300,
      Colors.purple.shade300,
      Colors.red.shade300,
      Colors.green.shade300,
      Colors.indigo.shade300,
      Colors.pink.shade300,
      Colors.amber.shade300,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: gridItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return _buildGridItem(
          gridItems[index]['icon'],
          gridItems[index]['label'],
          gridItems[index]['onTap'],
          cardColors[index % cardColors.length],
        );
      },
    );
  }

  Widget _buildGridItem(
      IconData icon, String label, VoidCallback onTap, Color color) {
    return Card(
      elevation: 2,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        splashColor: Colors.white.withOpacity(0.2),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
