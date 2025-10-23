import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- IMPORTS ---
import '../teacher_session_manager.dart';
import 'models/manage_attendance_model.dart';
import 'services/manage_attendance_service.dart';
import 'teacher_app_drawer.dart';

class ManageAttendanceScreen extends StatefulWidget {
  // This constructor is already const, which is correct
  const ManageAttendanceScreen({super.key});

  @override
  State<ManageAttendanceScreen> createState() => _ManageAttendanceScreenState();
}

class _ManageAttendanceScreenState extends State<ManageAttendanceScreen> {
  // --- STATE VARIABLES ---
  String? _selectedClass = '11th JEE MAINS';
  DateTime _selectedDate = DateTime.now();
  final String _currentSessionId = '171';
  final List<String> _classOptions = const [
    '11th JEE MAINS',
    '12th JEE MAINS',
    '11th JEE ADV',
    '12th JEE ADV',
  ];

  final AttendanceService _attendanceService = AttendanceService();
  final TeacherSessionManager _sessionManager = TeacherSessionManager();

  String? _authToken;

  // Data and UI state
  List<StudentAttendanceModel> _students = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  // --- LIFECYCLE & DATA FETCHING ---
  @override
  void initState() {
    super.initState();
    _initializeAndFetchData();
  }

  Future<void> _initializeAndFetchData() async {
    try {
      final session = await _sessionManager.getSession();

      if (session == null || session['token'] == null) {
        throw Exception("Authentication token not found. Please log in again.");
      }

      _authToken = session['token'] as String;

      if (_authToken!.isEmpty) {
        throw Exception("Authentication token is empty. Please log in again.");
      }

      await _fetchAttendanceData();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAttendanceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final students = await _attendanceService.getAttendanceSheet(
          _currentSessionId, _authToken!);

      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // --- ATTENDANCE LOGIC ---
  int get _totalStudents => _students.length;
  int get _presentCount => _students.where((s) => s.status == 'P').length;
  int get _absentCount => _students.where((s) => s.status == 'A').length;
  int get _lateCount => _students.where((s) => s.status == 'L').length;

  void _updateAttendanceStatus(
      StudentAttendanceModel student, String newStatus) {
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

  Future<void> _saveAttendance() async {
    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Not authenticated. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final successMessage = await _attendanceService.markAttendance(
        sessionId: _currentSessionId,
        students: _students,
        authToken: _authToken!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // --- UI WIDGETS (const added) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: const TeacherAppDrawer(),
      appBar: AppBar(
        title: const Text('Manage Attendance',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildBodyContent(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildSaveButton(),
          ),
          if (_isSubmitting)
            Container(
              // <-- Added const
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                // <-- Added const
                child: Card(
                  // <-- Added const
                  elevation: 4,
                  child: Padding(
                    // <-- Added const
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      // <-- Added const
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16), // <-- Added const
                        Text("Submitting Attendance..."), // <-- Added const
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // <-- Added const
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Error: $_errorMessage',
                style: const TextStyle(color: Colors.red), // <-- Added const
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16), // <-- Added const
              ElevatedButton(
                onPressed: _initializeAndFetchData,
                child: const Text('Retry'), // <-- Added const
              )
            ],
          ),
        ),
      );
    }

    if (_students.isEmpty) {
      return const Center(
        // <-- Added const
        child: Text(
          // <-- Added const
          'No students found for this session.',
          style: TextStyle(fontSize: 16, color: Colors.grey), // <-- Added const
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
          bottom: 100, left: 16, right: 16, top: 8), // <-- Added const
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildClassDropdown(),
          const SizedBox(height: 16), // <-- Added const
          _buildDateNavigation(),
          const SizedBox(height: 24), // <-- Added const
          _buildAttendanceSummary(),
          const SizedBox(height: 24), // <-- Added const
          const Text('Student List', // <-- Added const
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12), // <-- Added const
          _buildMarkAllPresentButton(),
          const SizedBox(height: 20), // <-- Added const
          ..._students.map((student) => _buildStudentCard(student)).toList(),
        ],
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16), // <-- Added const
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedClass,
          icon: const Icon(Icons.keyboard_arrow_down), // <-- Added const
          style: const TextStyle(
              // <-- Added const
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16),
          onChanged: (String? newValue) {
            setState(() {
              _selectedClass = newValue;
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

  Widget _buildDateNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20), // <-- Added const
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate
                  .subtract(const Duration(days: 1)); // <-- Added const
            });
          },
        ),
        Expanded(
          child: Center(
            child: Text(
              DateFormat('MMMM d, yyyy').format(_selectedDate),
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold), // <-- Added const
            ),
          ),
        ),
        IconButton(
          icon:
              const Icon(Icons.arrow_forward_ios, size: 20), // <-- Added const
          onPressed: () {
            if (!DateUtils.isSameDay(_selectedDate, DateTime.now())) {
              setState(() {
                _selectedDate = _selectedDate
                    .add(const Duration(days: 1)); // <-- Added const
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
        margin: const EdgeInsets.symmetric(horizontal: 4), // <-- Added const
        padding: const EdgeInsets.all(12), // <-- Added const
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 14), // <-- Added const
            ),
            const SizedBox(height: 4), // <-- Added const
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
          padding: const EdgeInsets.symmetric(vertical: 15), // <-- Added const
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: Colors.blue.shade200),
        ),
        child: const Text(
          // <-- Added const
          'Mark All Present',
          style:
              TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStudentCard(StudentAttendanceModel student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // <-- Added const
      padding: const EdgeInsets.symmetric(
          vertical: 10, horizontal: 8), // <-- Added const
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2), // <-- Added const
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                // <-- Added const
                radius: 20,
                backgroundImage:
                    AssetImage('assets/profile_dummy.png'), // Placeholder image
                backgroundColor: Colors.grey,
              ),
              const SizedBox(width: 12), // <-- Added const
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: const TextStyle(
                        // <-- Added const
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  Text(
                    'ID: ${student.studentId.length > 8 ? student.studentId.substring(0, 8) : student.studentId}...',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 14), // <-- Added const
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
      String status, StudentAttendanceModel student, Color color) {
    final bool isSelected = student.status == status;
    return GestureDetector(
      onTap: () => _updateAttendanceStatus(student, status),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4), // <-- Added const
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
      padding: const EdgeInsets.all(16), // <-- Added const
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5), // <-- Added const
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isSubmitting || _isLoading ? null : _saveAttendance,
        icon: const Icon(Icons.check_circle_outline,
            color: Colors.white), // <-- Added const
        label: Text(
          _isSubmitting ? 'Saving...' : 'Save Attendance',
          style: const TextStyle(
              fontSize: 18, color: Colors.white), // <-- Added const
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
