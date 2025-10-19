import 'package:flutter/material.dart';

import 'app_drawer.dart'; // IMPORTANT: Imports your app drawer.

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // --- State Management ---
  int _selectedDateIndex = 2; // Wednesday is selected by default

  // --- NEW: Dynamic Data Structure ---
  // This map holds all attendance and lecture data, keyed by the date string ('11', '12', etc.).
  final Map<String, Map<String, dynamic>> _dailyData = {
    '11': {
      'punchInTime': '09:05 AM',
      'punchInStatus': 'On-time',
      'punchOutTime': '05:00 PM',
      'punchOutStatus': 'Completed',
      'lectures': [
        {
          'icon': Icons.public,
          'subject': 'Geography',
          'time': '09:30 AM - 11:00 AM',
          'status': 'Attended',
        },
        {
          'icon': Icons.history_edu,
          'subject': 'History',
          'time': '11:15 AM - 12:45 PM',
          'status': 'Attended',
        },
      ],
    },
    '12': {
      'punchInTime': '09:18 AM',
      'punchInStatus': 'Late',
      'punchOutTime': '03:30 PM',
      'punchOutStatus': 'Left early',
      'lectures': [
        {
          'icon': Icons.functions,
          'subject': 'Trigonometry',
          'time': '09:30 AM - 11:00 AM',
          'status': 'Missed',
        },
        {
          'icon': Icons.biotech_outlined,
          'subject': 'Biology Lab',
          'time': '11:15 AM - 12:45 PM',
          'status': 'Attended',
        },
        {
          'icon': Icons.computer,
          'subject': 'Computer Science',
          'time': '02:00 PM - 03:30 PM',
          'status': 'Attended',
        },
      ],
    },
    '13': {
      'punchInTime': '09:02 AM',
      'punchInStatus': 'On-time',
      'punchOutTime': '-',
      'punchOutStatus': 'Not punched out',
      'lectures': [
        {
          'icon': Icons.thermostat,
          'subject': 'Physics',
          'time': '09:30 AM - 11:00 AM',
          'status': 'Attended',
        },
        {
          'icon': Icons.science_outlined,
          'subject': 'Chemistry',
          'time': '11:15 AM - 12:45 PM',
          'status': 'Missed',
        },
        {
          'icon': Icons.calculate_outlined,
          'subject': 'Maths',
          'time': '02:00 PM - 03:30 PM',
          'status': 'Upcoming',
        },
        {
          'icon': Icons.biotech_outlined,
          'subject': 'Biology',
          'time': '03:45 PM - 05:15 PM',
          'status': 'Upcoming',
        },
      ],
    },
    // Other dates are left empty to simulate no data.
  };

  final List<Map<String, String>> _weekDates = [
    {'day': 'Mon', 'date': '11'},
    {'day': 'Tue', 'date': '12'},
    {'day': 'Wed', 'date': '13'},
    {'day': 'Thu', 'date': '14'},
    {'day': 'Fri', 'date': '15'},
    {'day': 'Sat', 'date': '16'},
    {'day': 'Sun', 'date': '17'},
  ];

  @override
  Widget build(BuildContext context) {
    // --- NEW: Get the data for the currently selected day ---
    final selectedDate = _weekDates[_selectedDateIndex]['date']!;
    final dataForSelectedDay = _dailyData[selectedDate];
    final isFutureDate =
        int.parse(selectedDate) > 13; // Simple logic for dummy data

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Attendance & Timetable',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onPressed: () {},
          ),
        ],
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildDateSelector(),
            const SizedBox(height: 24),
            // --- NEW: Punch info cards now display dynamic data ---
            Row(
              children: [
                _buildPunchInfoCard(
                  title: 'Punch In',
                  time: dataForSelectedDay?['punchInTime'] ?? '-',
                  status: dataForSelectedDay?['punchInStatus'] ?? 'N/A',
                  statusColor: dataForSelectedDay?['punchInStatus'] == 'Late'
                      ? Colors.orange
                      : Colors.green,
                ),
                const SizedBox(width: 16),
                _buildPunchInfoCard(
                  title: 'Punch Out',
                  time: dataForSelectedDay?['punchOutTime'] ?? '-',
                  status: dataForSelectedDay?['punchOutStatus'] ?? 'N/A',
                  statusColor: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              "Today's Lectures",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // --- NEW: Conditionally render lectures or a message ---
            _buildLecturesSection(dataForSelectedDay, isFutureDate),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Builds the horizontal list of dates at the top of the screen.
  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(_weekDates.length, (index) {
        final dateInfo = _weekDates[index];
        final isSelected = index == _selectedDateIndex;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDateIndex = index;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blueAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  dateInfo['day']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateInfo['date']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Builds the cards for "Punch In" and "Punch Out" info.
  Widget _buildPunchInfoCard({
    required String title,
    required String time,
    required String status,
    required Color statusColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              time,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// --- NEW: This widget decides whether to show lectures or a message ---
  Widget _buildLecturesSection(Map<String, dynamic>? data, bool isFuture) {
    if (isFuture) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Schedule is not yet available for future dates.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    if (data == null || (data['lectures'] as List).isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No lectures were scheduled for this day.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final lectures = data['lectures'] as List<Map<String, dynamic>>;
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: lectures.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildLectureCard(lectures[index]);
      },
    );
  }

  /// Builds a single card for a lecture in the list.
  Widget _buildLectureCard(Map<String, dynamic> lecture) {
    Color statusColor;
    Color statusBgColor;
    switch (lecture['status']) {
      case 'Attended':
        statusColor = Colors.green;
        statusBgColor = Colors.green.withOpacity(0.1);
        break;
      case 'Missed':
        statusColor = Colors.red;
        statusBgColor = Colors.red.withOpacity(0.1);
        break;
      default:
        statusColor = Colors.grey.shade600;
        statusBgColor = Colors.grey.withOpacity(0.15);
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(lecture['icon'], color: Colors.blueAccent, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lecture['subject'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  lecture['time'],
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              lecture['status'],
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
