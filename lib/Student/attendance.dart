import 'package:flutter/material.dart';

import 'app_drawer.dart'; // IMPORTANT: Imports your new drawer file.

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      // CHANGE 1: The AppDrawer is added to the Scaffold.
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Attendance Record',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        // CHANGE 2: The 'leading' property with the back arrow has been REMOVED.
        // Flutter automatically adds a menu icon when a drawer is present.
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildAttendanceCard(
                    date: '2025-10-01',
                    status: 'Present',
                    punchIn: '09:00 AM',
                    punchOut: '05:00 PM',
                    isHighlighted: false,
                  ),
                  const SizedBox(height: 12),
                  _buildAttendanceCard(
                    date: '2025-09-30',
                    status: 'Present',
                    punchIn: '09:05 AM',
                    punchOut: '05:02 PM',
                    isHighlighted: true,
                  ),
                  const SizedBox(height: 12),
                  _buildAttendanceCard(
                    date: '2025-09-29',
                    status: 'Absent',
                    punchIn: '-',
                    punchOut: '-',
                    isHighlighted: false,
                  ),
                  const SizedBox(height: 12),
                  _buildAttendanceCard(
                    date: '2025-09-28',
                    status: 'Present',
                    punchIn: '09:00 AM',
                    punchOut: '05:00 PM',
                    isHighlighted: true,
                  ),
                ],
              ),
            ),
            _buildOverallAttendance(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard({
    required String date,
    required String status,
    required String punchIn,
    required String punchOut,
    required bool isHighlighted,
  }) {
    final Color statusColor =
        status == 'Present' ? Colors.green.shade100 : Colors.red.shade100;
    final Color statusTextColor =
        status == 'Present' ? Colors.green.shade800 : Colors.red.shade800;
    final Color cardColor = isHighlighted ? Colors.blue.shade50 : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!isHighlighted)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Punch In', style: TextStyle(color: Colors.grey)),
              Text(punchIn,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Punch Out', style: TextStyle(color: Colors.grey)),
              Text(punchOut,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallAttendance() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Overall Attendance',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('95%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueAccent)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.95,
              minHeight: 10,
              backgroundColor: Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }
}
