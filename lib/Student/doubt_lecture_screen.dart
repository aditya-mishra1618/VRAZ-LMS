import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting

import 'app_drawer.dart'; // Import your app drawer

// Model for a doubt lecture entry
class DoubtLectureEntry {
  final String subject;
  final String faculty;
  final String day; // e.g., 'Monday'
  final String time; // e.g., '04:00 PM - 05:00 PM'
  final int weekday; // DateTime weekday constant (e.g., DateTime.monday)

  DoubtLectureEntry({
    required this.subject,
    required this.faculty,
    required this.day,
    required this.time,
    required this.weekday,
  });
}

class DoubtLectureScreen extends StatefulWidget {
  const DoubtLectureScreen({super.key});

  @override
  State<DoubtLectureScreen> createState() => _DoubtLectureScreenState();
}

// Add SingleTickerProviderStateMixin for TabController
class _DoubtLectureScreenState extends State<DoubtLectureScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  late DateTime _selectedDate; // Tracks the selected date for the daily view

  // Processed schedule, grouped by weekday
  late Map<int, List<DoubtLectureEntry>> _scheduleByDay;

  // Original Dummy Schedule Data (with weekday added)
  final List<DoubtLectureEntry> _doubtSchedule = [
    DoubtLectureEntry(
      subject: 'Physics',
      faculty: 'ZAP Sir',
      day: 'Monday',
      time: '04:00 PM - 05:00 PM',
      weekday: DateTime.monday,
    ),
    DoubtLectureEntry(
      subject: 'Chemistry',
      faculty: 'ACM Sir',
      day: 'Tuesday',
      time: '04:00 PM - 05:00 PM',
      weekday: DateTime.tuesday,
    ),
    DoubtLectureEntry(
      subject: 'Maths',
      faculty: 'RCM Sir',
      day: 'Wednesday',
      time: '05:00 PM - 06:00 PM',
      weekday: DateTime.wednesday,
    ),
    DoubtLectureEntry(
      subject: 'Biology',
      faculty: 'UKCH Sir',
      day: 'Thursday',
      time: '04:00 PM - 05:00 PM',
      weekday: DateTime.thursday,
    ),
    DoubtLectureEntry(
      subject: 'Physics',
      faculty: 'ZAP Sir',
      day: 'Friday',
      time: '03:00 PM - 04:00 PM',
      weekday: DateTime.friday,
    ),
    // Example: Add another one on Monday
    DoubtLectureEntry(
      subject: 'Maths',
      faculty: 'RCM Sir',
      day: 'Monday',
      time: '05:00 PM - 06:00 PM',
      weekday: DateTime.monday,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDate = _getInitialDate();
    _processSchedule(); // Process the schedule data
  }

  // Helper to get initial date (ensures it's a weekday)
  DateTime _getInitialDate() {
    DateTime now = DateTime.now();
    // For doubt lectures, maybe default to Monday if it's the weekend
    if (now.weekday == DateTime.saturday) {
      return now.add(const Duration(days: 2));
    } else if (now.weekday == DateTime.sunday) {
      return now.add(const Duration(days: 1));
    }
    return now;
  }

  // Process the list into a map grouped by weekday
  void _processSchedule() {
    _scheduleByDay = {};
    for (var lecture in _doubtSchedule) {
      if (!_scheduleByDay.containsKey(lecture.weekday)) {
        _scheduleByDay[lecture.weekday] = [];
      }
      _scheduleByDay[lecture.weekday]!.add(lecture);
    }
    // Sort lectures within each day by time (assuming time format is sortable)
    _scheduleByDay.forEach((key, value) {
      value.sort((a, b) => a.time.compareTo(b.time));
    });
  }

  // Navigate dates in the Daily view
  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      // Skip weekends if desired
      if (_selectedDate.weekday == DateTime.saturday) {
        _selectedDate = _selectedDate.add(Duration(days: days > 0 ? 2 : -1));
      } else if (_selectedDate.weekday == DateTime.sunday) {
        _selectedDate = _selectedDate.add(Duration(days: days > 0 ? 1 : -2));
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: const AppDrawer(),
      appBar: AppBar(
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
        // --- Add TabBar ---
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
      // --- Add TabBarView ---
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyDoubtView(),
          _buildWeeklyDoubtView(),
        ],
      ),
    );
  }

  // --- Build Daily View ---
  Widget _buildDailyDoubtView() {
    final formattedDate = DateFormat('d MMMM, EEEE').format(_selectedDate);
    final dailySchedule = _scheduleByDay[_selectedDate.weekday] ?? [];

    return Column(
      children: [
        _buildDateNavigator(formattedDate),
        Expanded(
          child: dailySchedule.isEmpty
              ? Center(
                  child: Text(
                  "No doubt lectures scheduled for ${DateFormat('EEEE').format(_selectedDate)}.",
                  style: const TextStyle(color: Colors.grey),
                ))
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: dailySchedule.length,
                  itemBuilder: (context, index) {
                    return _buildLectureCard(
                        dailySchedule[index]); // Use the same card widget
                  },
                ),
        ),
      ],
    );
  }

  // --- Build Weekly View ---
  Widget _buildWeeklyDoubtView() {
    final weekdays = [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      // Add Saturday/Sunday if needed
    ];
    final weekdayNames = ["Mon", "Tue", "Wed", "Thu", "Fri"];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(weekdays.length, (index) {
          final day = weekdays[index];
          final daySchedule = _scheduleByDay[day] ?? [];
          return Expanded(
            child: Column(
              children: [
                Text(
                  weekdayNames[index],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                const Divider(height: 8),
                if (daySchedule.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text("—", style: TextStyle(color: Colors.grey)),
                  )
                else
                  // Use a slightly smaller card for the weekly view
                  ...daySchedule.map((entry) => _buildWeeklyLectureCard(entry)),
              ],
            ),
          );
        }),
      ),
    );
  }

  // Navigator for Daily View
  Widget _buildDateNavigator(String displayDate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () => _changeDate(-1),
          ),
          Text(
            displayDate,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  // Card used in Daily view (similar to original)
  Widget _buildLectureCard(DoubtLectureEntry lecture) {
    IconData icon;
    Color iconColor;

    switch (lecture.subject) {
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
                    lecture.subject,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Faculty: ${lecture.faculty}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lecture.time, // Only show time in daily view maybe?
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Smaller card used in Weekly view columns
  Widget _buildWeeklyLectureCard(DoubtLectureEntry entry) {
    IconData icon;
    switch (entry.subject) {
      case 'Physics':
        icon = Icons.rocket_launch_outlined;
        break;
      case 'Chemistry':
        icon = Icons.science_outlined;
        break;
      case 'Maths':
        icon = Icons.calculate_outlined;
        break;
      case 'Biology':
        icon = Icons.biotech_outlined;
        break;
      default:
        icon = Icons.help_outline;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: Colors.grey[700]), // Small icon
            const SizedBox(height: 4),
            Text(
              entry.subject,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 11), // Smaller font
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              entry.faculty,
              style: TextStyle(
                  color: Colors.grey[600], fontSize: 9), // Smaller font
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              entry.time,
              style: TextStyle(
                  color: Colors.grey[700], fontSize: 9), // Smaller font
            ),
          ],
        ),
      ),
    );
  }
}
