import 'package:flutter/material.dart';

import 'app_drawer.dart'; // Import your app drawer

class DoubtLectureScreen extends StatefulWidget {
  const DoubtLectureScreen({super.key});

  @override
  State<DoubtLectureScreen> createState() => _DoubtLectureScreenState();
}

class _DoubtLectureScreenState extends State<DoubtLectureScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- Dummy Schedule Data ---
  // In a real app, this would likely come from an API
  final List<Map<String, String>> _doubtSchedule = [
    {
      'subject': 'Physics',
      'faculty': 'ZAP Sir',
      'day': 'Monday',
      'time': '04:00 PM - 05:00 PM',
    },
    {
      'subject': 'Chemistry',
      'faculty': 'ACM Sir',
      'day': 'Tuesday',
      'time': '04:00 PM - 05:00 PM',
    },
    {
      'subject': 'Maths',
      'faculty': 'RCM Sir',
      'day': 'Wednesday',
      'time': '05:00 PM - 06:00 PM',
    },
    {
      'subject': 'Biology',
      'faculty': 'UKCH Sir',
      'day': 'Thursday',
      'time': '04:00 PM - 05:00 PM',
    },
    {
      'subject': 'Physics',
      'faculty': 'ZAP Sir',
      'day': 'Friday',
      'time': '03:00 PM - 04:00 PM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      // Connect the AppDrawer
      drawer: const AppDrawer(),
      appBar: AppBar(
        // Add menu button to open drawer
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black54),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Doubt Lecture Schedule',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _doubtSchedule.length,
        itemBuilder: (context, index) {
          final lecture = _doubtSchedule[index];
          return _buildLectureCard(lecture);
        },
      ),
    );
  }

  Widget _buildLectureCard(Map<String, String> lecture) {
    IconData icon;
    Color iconColor;

    // Assign icons based on subject
    switch (lecture['subject']) {
      case 'Physics':
        icon = Icons.rocket_launch_outlined;
        iconColor = Colors.blue.shade700;
        break;
      case 'Chemistry':
        icon = Icons.science_outlined;
        iconColor = Colors.orange.shade700;
        break;
      case 'Maths':
        icon = Icons.calculate_outlined;
        iconColor = Colors.purple.shade700;
        break;
      case 'Biology':
        icon = Icons.biotech_outlined;
        iconColor = Colors.green.shade700;
        break;
      default:
        icon = Icons.help_outline;
        iconColor = Colors.grey.shade700;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecture['subject']!,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Faculty: ${lecture['faculty']}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lecture['day']} · ${lecture['time']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            // Optional: Add a button or indicator if needed
            // Icon(Icons.info_outline, color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }
}
