import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting

import 'teacher_app_drawer.dart'; // Import your central drawer

class ManageAttendanceScreen extends StatefulWidget {
  const ManageAttendanceScreen({super.key});

  @override
  State<ManageAttendanceScreen> createState() => _ManageAttendanceScreenState();
}

// Data model for a student's attendance status
class StudentAttendance {
  final String name;
  final String rollNumber;
  String status; // 'P', 'A', 'L'

  StudentAttendance({
    required this.name,
    required this.rollNumber,
    this.status = 'A',
  });
}

class _ManageAttendanceScreenState extends State<ManageAttendanceScreen> {
  String? _selectedClass = '11th JEE MAINS';
  DateTime _selectedDate = DateTime.now(); // State for the selected date

  final List<String> _classOptions = const [
    '11th JEE MAINS',
    '12th JEE MAINS',
    '11th JEE ADV',
    '12th JEE ADV',
  ];

  final List<StudentAttendance> _students = [
    StudentAttendance(name: 'Aditya Sharma', rollNumber: 'Roll No. 1'),
    StudentAttendance(name: 'Neha Verma', rollNumber: 'Roll No. 2'),
    StudentAttendance(name: 'Rohan Singh', rollNumber: 'Roll No. 3'),
    StudentAttendance(name: 'Aisha Khan', rollNumber: 'Roll No. 4'),
    StudentAttendance(name: 'Vivek Patil', rollNumber: 'Roll No. 5'),
    StudentAttendance(name: 'Pooja Reddy', rollNumber: 'Roll No. 6'),
    StudentAttendance(name: 'Kunal Iyer', rollNumber: 'Roll No. 7'),
  ];

  int get _totalStudents => _students.length;
  int get _presentCount => _students.where((s) => s.status == 'P').length;
  int get _absentCount => _students.where((s) => s.status == 'A').length;
  int get _lateCount => _students.where((s) => s.status == 'L').length;

  void _updateAttendanceStatus(StudentAttendance student, String newStatus) {
    setState(() {
      student.status = newStatus;
    });
  }

  void _markAllPresent() {
    setState(() {
      for (var student in _students) {
        student.status = 'P';
      }
    });
  }

  void _saveAttendance() {
    final Map<String, String> attendanceData = {
      for (var s in _students) s.rollNumber: s.status,
    };
    print(
        'Attendance Saved for ${_selectedClass} on ${DateFormat('yyyy-MM-dd').format(_selectedDate)}: $attendanceData');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      // --- 1. ADD THE DRAWER TO THE SCAFFOLD ---
      drawer: const TeacherAppDrawer(),
      appBar: AppBar(
        // --- 2. REMOVED LEADING ICONBUTTON TO ALLOW DRAWER ICON ---
        title: const Text('Manage Attendance',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding:
                const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildClassDropdown(),
                const SizedBox(height: 16),
                _buildDateNavigation(),
                const SizedBox(height: 24),
                _buildAttendanceSummary(),
                const SizedBox(height: 24),
                const Text('Student List',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildMarkAllPresentButton(),
                const SizedBox(height: 20),
                ..._students
                    .map((student) => _buildStudentCard(student))
                    .toList(),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildSaveButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedClass,
          icon: const Icon(Icons.keyboard_arrow_down),
          style: const TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
          onChanged: (String? newValue) {
            setState(() {
              _selectedClass = newValue;
              // You might want to fetch new student list here
            });
          },
          items: _classOptions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- 3. UPDATED WIDGET WITH FUNCTIONAL DATE NAVIGATION ---
  Widget _buildDateNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
            });
          },
        ),
        Expanded(
          child: Center(
            child: Text(
              DateFormat('MMMM d, yyyy').format(_selectedDate),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 20),
          onPressed: () {
            // Prevent navigating to a future date
            if (!DateUtils.isSameDay(_selectedDate, DateTime.now())) {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildAttendanceSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSummaryCard('Total', _totalStudents, Colors.grey),
        _buildSummaryCard('Present', _presentCount, Colors.green),
        _buildSummaryCard('Absent', _absentCount, Colors.red),
        _buildSummaryCard('Late', _lateCount, Colors.orange),
      ],
    );
  }

  Widget _buildSummaryCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkAllPresentButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _markAllPresent,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: Colors.blue.shade200),
        ),
        child: const Text(
          'Mark All Present',
          style:
              TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStudentCard(StudentAttendance student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage:
                    AssetImage('assets/profile_dummy.png'), // Placeholder image
                backgroundColor: Colors.grey,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    student.rollNumber,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _buildStatusButton('P', student, Colors.green),
              _buildStatusButton('A', student, Colors.red),
              _buildStatusButton('L', student, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(
      String status, StudentAttendance student, Color color) {
    final bool isSelected = student.status == status;
    return GestureDetector(
      onTap: () => _updateAttendanceStatus(student, status),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          status,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _saveAttendance,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        label: const Text(
          'Save Attendance',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
