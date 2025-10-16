import 'package:flutter/material.dart';

import 'app_drawer.dart'; // Import the shared drawer

// Temporary data model for a single schedule item.
class TimetableEntry {
  final String startTime;
  final String endTime;
  final String subject;
  final String professor;
  final bool isBreak;

  TimetableEntry({
    required this.startTime,
    this.endTime = '',
    this.subject = '',
    this.professor = '',
    this.isBreak = false,
  });
}

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late DateTime _currentDate;

  // --- Dummy Data ---
  // In a real app, this would come from a backend.
  final Map<int, List<TimetableEntry>> _schedule = {
    5: [
      // Friday
      TimetableEntry(
          startTime: '09:00 AM',
          endTime: '10:00 AM',
          subject: 'Physics',
          professor: 'Prof. Sharma'),
      TimetableEntry(
          startTime: '10:00 AM',
          endTime: '11:00 AM',
          subject: 'Doubt Lecture',
          professor: 'Chemistry'),
      TimetableEntry(
          startTime: '11:00 AM',
          endTime: '12:00 PM',
          subject: 'Biology',
          professor: 'Prof. Singh'),
      TimetableEntry(startTime: '12:00 PM', isBreak: true),
      TimetableEntry(
          startTime: '01:00 PM',
          endTime: '02:00 PM',
          subject: 'Physics',
          professor: 'Prof. Sharma'),
      TimetableEntry(
          startTime: '02:00 PM',
          endTime: '03:00 PM',
          subject: 'Chemistry',
          professor: 'Prof. Gupta'),
    ],
    4: [
      // Thursday
      TimetableEntry(
          startTime: '09:00 AM',
          endTime: '10:00 AM',
          subject: 'Maths',
          professor: 'Prof. Ramswaroop Sir'),
      TimetableEntry(
          startTime: '10:00 AM',
          endTime: '11:00 AM',
          subject: 'Chemistry',
          professor: 'Prof. Ankit Sir'),
      TimetableEntry(
          startTime: '11:00 AM',
          endTime: '12:00 PM',
          subject: 'Physics',
          professor: 'Prof. Zeeshan Sir'),
      TimetableEntry(startTime: '12:00 PM', isBreak: true),
    ],
  };
  // --- End Dummy Data ---

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    // If it's a weekend, default to Friday to show some data
    if (_currentDate.weekday > 5) {
      _currentDate =
          _currentDate.subtract(Duration(days: _currentDate.weekday - 5));
    }
  }

  void _changeDate(int days) {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: days));
      // Skip weekends
      if (_currentDate.weekday == 6) {
        // Saturday
        _currentDate = _currentDate.add(const Duration(days: 2));
      } else if (_currentDate.weekday == 7) {
        // Sunday
        _currentDate = _currentDate.add(const Duration(days: 1));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine the day name (e.g., "Friday")
    const weekDays = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday"
    ];
    final dayName = weekDays[_currentDate.weekday - 1];

    // Get the schedule for the current day, or an empty list if none
    final dailySchedule = _schedule[_currentDate.weekday] ?? [];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black54),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('Timetable',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateNavigator(dayName),
          Expanded(
            child: dailySchedule.isEmpty
                ? const Center(child: Text("No classes scheduled for today."))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: dailySchedule.length,
                    itemBuilder: (context, index) {
                      return _buildTimelineEntry(dailySchedule[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigator(String dayName) {
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
            "${_currentDate.day}rd ${_getMonthName(_currentDate.month)}, $dayName",
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

  Widget _buildTimelineEntry(TimetableEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              entry.startTime,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: entry.isBreak ? _buildBreak() : _buildClassCard(entry),
          ),
        ],
      ),
    );
  }

  Widget _buildBreak() {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      child: const Column(
        children: [
          Text("Lunch Break",
              style:
                  TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Divider(indent: 20, endIndent: 20),
        ],
      ),
    );
  }

  Widget _buildClassCard(TimetableEntry entry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: Colors.blueAccent, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.subject,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            entry.professor,
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.grey[600], size: 16),
              const SizedBox(width: 4),
              Text(
                '${entry.startTime} - ${entry.endTime}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[month - 1];
  }
}
