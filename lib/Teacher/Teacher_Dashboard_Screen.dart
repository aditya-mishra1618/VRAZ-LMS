import 'package:flutter/material.dart';
import 'package:vraz_application/Teacher/manage_attendance_Screen.dart';

import 'hr_section_screen.dart';
import 'student_performance_screen.dart';
import 'syllabus_tracking_screen.dart';
// Import the central app drawer
import 'teacher_app_drawer.dart';
import 'teacher_doubts_screen.dart';
import 'teacher_notifications_screen.dart';
import 'timetable_screen.dart';
import 'upload_assignment_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final String teacherName = 'Prof. RamSwaroop';
  final String teacherSubject = 'Mathematics';

  final Map<String, bool> _notificationToggles = {
    'Doubt Lecture': true,
    'Calculus': false,
  };

  late final List<Map<String, dynamic>> _gridItems;

  @override
  void initState() {
    super.initState();
    _gridItems = [
      {
        'icon': Icons.check_box_outlined,
        'label': 'Manage Attendance',
        'colors': [Colors.lightBlue.shade100, Colors.lightBlue.shade200],
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const ManageAttendanceScreen()),
          );
        },
      },
      {
        'icon': Icons.assignment_turned_in_outlined,
        'label': 'Syllabus Tracking',
        'colors': [Colors.amber.shade100, Colors.amber.shade200],
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const SyllabusTrackingScreen()),
          );
        },
      },
      {
        'icon': Icons.upload_file_outlined,
        'label': 'Upload Assignment',
        'colors': [Colors.purple.shade100, Colors.purple.shade200],
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const UploadAssignmentScreen()),
          );
        },
      },
      {
        'icon': Icons.help_outline,
        'label': 'Doubts',
        'colors': [Colors.pink.shade100, Colors.pink.shade200],
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const TeacherDoubtsScreen()),
          );
        },
      },
      {
        'icon': Icons.bar_chart_outlined,
        'label': 'Student Performance',
        'colors': [Colors.orange.shade100, Colors.orange.shade200],
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const StudentPerformanceScreen()),
          );
        },
      },
      {
        'icon': Icons.notifications_outlined,
        'label': 'Notifications',
        'colors': [Colors.green.shade100, Colors.green.shade200],
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const TeacherNotificationsScreen()),
          );
        },
      },
      {
        'icon': Icons.business_center_outlined,
        'label': 'HR Section',
        'colors': [Colors.teal.shade100, Colors.teal.shade200],
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HRSectionScreen()),
          );
        },
      },
      {
        'icon': Icons.schedule_outlined,
        'label': 'Timetable',
        'colors': [Colors.deepPurple.shade100, Colors.deepPurple.shade200],
        'onTap': () {
          Navigator.push(
            context,
            // --- FIX: REMOVED 'const' FROM TimetableScreen() ---
            MaterialPageRoute(builder: (context) => TimetableScreen()),
          );
        },
      },
    ];
  }

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
          'Teacher Dashboard',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black54),
            onPressed: () {},
          ),
        ],
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: const TeacherAppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTeacherInfoCard(),
            const SizedBox(height: 24),
            _buildGridView(),
            const SizedBox(height: 24),
            _buildLectureReminders(),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherInfoCard() {
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
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/profile.png'),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Teacher',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                teacherName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              Text(
                teacherSubject,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _gridItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final item = _gridItems[index];
        return _buildGridItem(
          item['icon'] as IconData,
          item['label'] as String,
          item['colors'] as List<Color>,
          item['onTap'] as Function(),
        );
      },
    );
  }

  Widget _buildGridItem(
      IconData icon, String label, List<Color> colors, Function() onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.3),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLectureReminders() {
    final List<Map<String, String>> lectures = [
      {'subject': 'Doubt Lecture', 'time': '10:00 AM - 11:00 AM'},
      {'subject': 'Calculus', 'time': '1:00 PM - 2:30 PM'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.access_time, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text(
                'Lecture Reminders',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Upcoming lectures with notification toggle',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const Divider(height: 30),
          ...lectures
              .map((lecture) => _buildLectureItem(
                    lecture['subject']!,
                    lecture['time']!,
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildLectureItem(String subject, String time) {
    bool isToggled = _notificationToggles[subject] ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                time,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          Switch(
            value: isToggled,
            onChanged: (bool value) {
              setState(() {
                _notificationToggles[subject] = value;
              });
            },
            activeColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }
}
