import 'package:flutter/material.dart';

import 'teacher_app_drawer.dart'; // Import your central drawer

// A simple data model for a timetable entry to keep the code clean.
class TimetableEntry {
  final String time;
  final String title;
  final String? center;
  final String duration;
  final String type; // 'class', 'break', or 'doubt'

  TimetableEntry({
    required this.time,
    required this.title,
    this.center,
    required this.duration,
    required this.type,
  });
}

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dummy data for the timetable entries shown in the screenshot.
  final List<TimetableEntry> _dailySchedule = [
    TimetableEntry(
      time: '9:00 AM',
      title: 'Calculus for JEE',
      center: 'Thane Station',
      duration: '1:30 hr',
      type: 'class',
    ),
    TimetableEntry(
      time: '10:30 AM',
      title: 'Algebra & Vectors JEE',
      center: 'Manpada',
      duration: '1:30 hr',
      type: 'class',
    ),
    TimetableEntry(
      time: '12:00 PM',
      title: 'Break Time',
      duration: '30 min',
      type: 'break',
    ),
    TimetableEntry(
      time: '12:30 PM',
      title: 'Trigonometry JEE',
      center: 'Kalyan',
      duration: '1:30 hr',
      type: 'class',
    ),
    TimetableEntry(
      time: '2:00 PM',
      title: 'Doubt Session',
      center: 'Kalyan',
      duration: '1:30 hr',
      type: 'doubt',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // A light grey background
      // 1. Connect the TeacherAppDrawer to the Scaffold.
      drawer: const TeacherAppDrawer(),
      appBar: AppBar(
        // 2. The Scaffold will automatically add a menu icon to open the drawer.
        title: const Text(
          "Prof. RamSwaroop's Timetable",
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.withOpacity(0.2),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Daily"),
            Tab(text: "Weekly"),
          ],
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blueAccent,
          indicatorWeight: 3.0,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyTimetable(),
          _buildWeeklyPlaceholder(),
        ],
      ),
    );
  }

  /// Builds the content for the "Daily" tab.
  Widget _buildDailyTimetable() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Monday, October 21',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 20),
        ..._dailySchedule.map((entry) => _buildTimetableEntry(entry)),
      ],
    );
  }

  /// A helper widget to create a single row in the timetable.
  Widget _buildTimetableEntry(TimetableEntry entry) {
    Color cardColor;
    switch (entry.type) {
      case 'doubt':
        cardColor = Colors.yellow.shade100;
        break;
      case 'break':
        cardColor = Colors.grey.shade100;
        break;
      case 'class':
      default:
        cardColor = Colors.blue.shade50;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time on the left
          SizedBox(
            width: 70,
            child: Text(
              entry.time,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(width: 10),
          // Details card on the right
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87),
                  ),
                  if (entry.center != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Center: ${entry.center}',
                      style: TextStyle(
                          fontSize: 14, color: Colors.black.withOpacity(0.6)),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Duration: ${entry.duration}',
                    style: TextStyle(
                        fontSize: 13, color: Colors.black.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A placeholder for the "Weekly" tab content.
  Widget _buildWeeklyPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_view_week, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Weekly schedule is not yet available.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
