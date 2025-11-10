import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Import necessary files (adjust paths)
import '../teacher_session_manager.dart'; // To get auth token
import 'models/manage_attendance_model.dart'; // Student attendance model
import 'models/timetable_model.dart'; // Timetable Entry model (TeacherTimetableEntry)
import 'services/manage_attendance_service.dart'; // Attendance API calls
import 'services/timetable_api_service.dart'; // Timetable API calls
import 'teacher_app_drawer.dart';

class ManageAttendanceScreen extends StatefulWidget {
  const ManageAttendanceScreen({super.key});

  @override
  State<ManageAttendanceScreen> createState() => _ManageAttendanceScreenState();
}

class _ManageAttendanceScreenState extends State<ManageAttendanceScreen> {
  // Services
  final AttendanceService _attendanceService = AttendanceService();
  late TeacherTimetableService
      _timetableService; // Initialize in initState/fetch

  // State
  String? _authToken;
  // Initialize _selectedDate later based on fetched data
  late DateTime _selectedDate;
  List<TeacherTimetableEntry> _allFetchedSessions = []; // Store weekly sessions
  List<TeacherTimetableEntry> _sessionsForSelectedDay =
      []; // Filtered for dropdown
  int? _selectedSessionId; // Store the ID (int) of the selected session
  TeacherTimetableEntry? _selectedSessionEntry; // Store the full selected entry

  List<StudentAttendanceModel> _students = []; // Attendance sheet data
  bool _isLoadingSessions = true;
  bool _isLoadingAttendance = false; // Separate loading for attendance sheet
  bool _isSubmitting = false;
  String? _errorMessage;
  DateTime? _currentFetchedWeekStart; // To track which week's data we have

  @override
  void initState() {
    super.initState();
    // Don't set _selectedDate here initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndFetchData();
    });
  }

  // Get token and fetch initial schedule + attendance
  Future<void> _initializeAndFetchData() async {
    // Set initial date to today
    _selectedDate = DateTime.now();

    final sessionManager = TeacherSessionManager();
    final session = await sessionManager.getSession();

    if (session == null ||
        session['token'] == null ||
        (session['token'] as String).isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage =
              "Authentication token not found. Please log in again.";
          _isLoadingSessions = false;
        });
      }
      return;
    }
    _authToken = session['token'] as String;
    _timetableService = TeacherTimetableService(
        token: _authToken!); // Initialize service with token

    print('Manage Attendance: Auth Token found.');
    // Fetch schedule for the week containing the initial _selectedDate
    await _fetchScheduleForWeek(_selectedDate, fetchFirstAttendance: true);
  }

  // Fetch schedule for the week containing the given date
  Future<void> _fetchScheduleForWeek(DateTime dateInWeek,
      {bool fetchFirstAttendance = false}) async {
    if (_authToken == null) return;

    final weekDates = _getWeekStartAndEnd(dateInWeek);
    // Avoid refetching if we already have data for this week
    if (weekDates.$1 == _currentFetchedWeekStart && !fetchFirstAttendance) {
      print('Already have schedule for this week. Filtering.');
      _filterSessionsForDate(_selectedDate); // Just filter
      // Fetch attendance only if a lecture session is now selected and students aren't loaded
      if (_selectedSessionEntry?.type == 'LECTURE' &&
          _selectedSessionId != null &&
          _students.isEmpty &&
          !_isLoadingAttendance) {
        await _fetchAttendanceData(_selectedSessionId!);
      } else if (_selectedSessionEntry?.type != 'LECTURE') {
        // Clear students if a non-lecture is selected
        if (mounted)
          setState(() {
            _students = [];
            _isLoadingAttendance = false;
          });
      }
      return;
    }

    setState(() {
      _isLoadingSessions = true;
      _errorMessage = null;
      _sessionsForSelectedDay = []; // Clear dropdown
      _students = []; // Clear student list
      _selectedSessionId = null; // Clear selection
      _selectedSessionEntry = null;
    });

    try {
      final startDateStr = DateFormat('yyyy-MM-dd').format(weekDates.$1);
      final endDateStr = DateFormat('yyyy-MM-dd').format(weekDates.$2);

      _allFetchedSessions = await _timetableService.fetchTimetable(
        startDate: startDateStr,
        endDate: endDateStr,
      );
      _currentFetchedWeekStart = weekDates.$1; // Update tracked week

      // --- **BUG FIX** ---
      // The faulty logic that reset _selectedDate to the start of the
      // week has been removed. We now just filter for _selectedDate,
      // which is correctly set to DateTime.now() on initial load.
      // --- **END BUG FIX** ---

      _filterSessionsForDate(
          _selectedDate); // Filter for the determined initial day

      // Automatically fetch attendance for the first LECTURE session of the day
      if (fetchFirstAttendance &&
          _selectedSessionEntry?.type == 'LECTURE' &&
          _selectedSessionId != null) {
        // --- FIX: This line was causing an error, it's correct now ---
        await _fetchAttendanceData(_selectedSessionId!);
      } else {
        // If no session selected or it's not a lecture, stop loading attendance
        if (mounted) {
          setState(() => _isLoadingAttendance = false);
        }
      }

      if (mounted) {
        setState(() {
          _isLoadingSessions = false;
        });
      }
    } catch (e) {
      print('Error fetching schedule: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoadingSessions = false;
          _isLoadingAttendance =
              false; // Ensure attendance loading stops on schedule error
        });
      }
    }
  }

  // Filter sessions for the selected date
  void _filterSessionsForDate(DateTime date) {
    // Normalize the selected date to midnight for accurate comparison
    final selectedDayStart = DateTime(date.year, date.month, date.day);

    setState(() {
      _sessionsForSelectedDay = _allFetchedSessions.where((session) {
        try {
          // Normalize session start time to midnight (local time) for comparison
          final sessionDate = DateTime(session.startTime.year,
              session.startTime.month, session.startTime.day);
          // Check if session date matches selected date AND is Lecture or Availability Slot
          return sessionDate.isAtSameMomentAs(selectedDayStart) &&
              (session.type == 'LECTURE' ||
                  session.type == 'AVAILABILITY_SLOT');
        } catch (e) {
          print("Error processing session date: ${session.id} - $e");
          return false;
        }
      }).toList();

      _sessionsForSelectedDay
          .sort((a, b) => a.startTime.compareTo(b.startTime));

      _selectedSessionEntry = _sessionsForSelectedDay.isNotEmpty
          ? _sessionsForSelectedDay.first
          : null;
      // --- FIX: Access sessionId from the details map ---
      _selectedSessionId = _selectedSessionEntry?.details['sessionId'] as int?;

      if (_selectedSessionEntry == null ||
          _selectedSessionEntry!.type != 'LECTURE') {
        _students = [];
        _isLoadingAttendance = false;
      }

      print(
          'Filtered sessions for ${DateFormat('yyyy-MM-dd').format(date)}: ${_sessionsForSelectedDay.length}');
      print('Selected Session ID set to: $_selectedSessionId');
      print('Selected Session Type: ${_selectedSessionEntry?.type}');
    });
  }

  // Fetch attendance sheet for a specific session ID
  Future<void> _fetchAttendanceData(int sessionId) async {
    if (_authToken == null) return;

    // --- FIX: Access sessionId from the details map ---
    if (_selectedSessionEntry?.type != 'LECTURE' ||
        _selectedSessionEntry?.details['sessionId'] != sessionId) {
      print(
          "Attempted to fetch attendance for a non-lecture or mismatched session. Skipping.");
      if (mounted)
        setState(() {
          _isLoadingAttendance = false;
          _students = [];
        });
      return;
    }

    setState(() {
      _isLoadingAttendance = true;
      _students = [];
      _errorMessage = null; // Clear attendance-specific errors
    });

    try {
      // --- FIX: Use the passed sessionId directly ---
      final studentsData = await _attendanceService.getAttendanceSheet(
          sessionId.toString(), _authToken!);
      if (mounted) {
        if (_selectedSessionId == sessionId) {
          // Check if selection changed during fetch
          setState(() {
            _students = studentsData;
            _isLoadingAttendance = false;
          });
        } else {
          print("Session changed during attendance fetch. Discarding results.");
          if (mounted)
            setState(() {
              _isLoadingAttendance = false;
            });
        }
      }
    } catch (e) {
      print('Error fetching attendance data: $e');
      if (mounted) {
        if (_selectedSessionId == sessionId) {
          // Check if selection changed during fetch error
          setState(() {
            _errorMessage =
                "Attendance: ${e.toString().replaceAll('Exception: ', '')}";
            _isLoadingAttendance = false;
          });
        } else {
          print(
              "Session changed during attendance fetch error. Discarding error message.");
          if (mounted)
            setState(() {
              _isLoadingAttendance = false;
            });
        }
      }
    }
  }

  // --- REFACTORED DATE CHANGE LOGIC ---
  // This new function contains the core logic for changing the date.
  Future<void> _onDateChanged(DateTime newDate) async {
    // 1. Set the new date and clear old data immediately
    setState(() {
      _selectedDate = newDate;
      _students = [];
      _errorMessage = null;
      _selectedSessionId = null;
      _selectedSessionEntry = null;
      // --- FIX: DO NOT set _isLoadingSessions = true here ---
      _isLoadingAttendance = true; // Assume true initially
    });

    final newWeekStartDate = _getWeekStartAndEnd(newDate).$1;

    // 2. Check if we need to fetch new data
    if (newWeekStartDate != _currentFetchedWeekStart ||
        _currentFetchedWeekStart == null) {
      // --- FIX: Set loading to true ONLY when fetching a new week ---
      setState(() {
        _isLoadingSessions = true;
      });
      // This is the "slow" path (network call)
      await _fetchScheduleForWeek(newDate, fetchFirstAttendance: false);
    } else {
      // --- FIX: This is the "fast" path (same week) ---
      // Instantly filter data. No full-screen loader.
      _filterSessionsForDate(newDate); // This is a local (fast) operation

      // We still need to fetch attendance for the (potentially) new session
      if (_selectedSessionEntry?.type == 'LECTURE' &&
          _selectedSessionId != null) {
        // This will set its own _isLoadingAttendance = true
        await _fetchAttendanceData(_selectedSessionId!);
      } else {
        // If no sessions or not a lecture, explicitly stop loading attendance
        if (mounted) setState(() => _isLoadingAttendance = false);
      }
    }
  }

  // Date Navigation (Arrows) - now uses the refactored logic
  void _changeDate(int days) async {
    final newDate = _selectedDate.add(Duration(days: days));
    await _onDateChanged(newDate);
  }

  // NEW: Date Picker (Calendar) - also uses the refactored logic
  Future<void> _showDatePicker() async {
    final DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 1), // One year ago
      lastDate: DateTime(DateTime.now().year + 1), // One year from now
    );

    if (newDate != null && newDate != _selectedDate) {
      // Call the refactored logic
      await _onDateChanged(newDate);
    }
  }
  // --- END REFACTOR ---

  // --- Attendance Logic (remains the same) ---
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

  // --- Save Attendance (remains the same) ---
  Future<void> _saveAttendance() async {
    // Can only save for lectures
    if (_selectedSessionEntry?.type != 'LECTURE' ||
        _selectedSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Attendance can only be saved for lecture sessions.'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    if (_authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Authentication error.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // --- FIX: Use _selectedSessionId ---
      final successMessage = await _attendanceService.markAttendance(
        sessionId: _selectedSessionId!.toString(),
        students: _students,
        authToken: _authToken!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(successMessage), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Failed to save: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // Helper to get Monday (start) and Sunday (end) of the week
  (DateTime, DateTime) _getWeekStartAndEnd(DateTime date) {
    final daysToSubtract = date.weekday - DateTime.monday;
    final monday = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysToSubtract));
    final sunday = monday
        .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return (monday, sunday);
  }

  // --- UI WIDGETS ---
  @override
  Widget build(BuildContext context) {
    // Show initial loading screen until token and first schedule are fetched
    if (_authToken == null && _isLoadingSessions) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Attendance')),
        drawer: const TeacherAppDrawer(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    // Show error if token couldn't be loaded
    if (_authToken == null && _errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Attendance')),
        drawer: const TeacherAppDrawer(),
        body: Center(child: Text('Error: $_errorMessage')),
      );
    }

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
        // --- ADDED REFRESH BUTTON ---
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: (_isLoadingSessions || _isSubmitting)
                ? null
                : _initializeAndFetchData,
            tooltip: 'Refresh Data',
          ),
        ],
        // --- END ADDED ---
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildSessionDropdown(), // Dropdown at the top
              const SizedBox(height: 16),
              _buildDateNavigation(),
              const SizedBox(height: 16),
              Expanded(child: _buildBodyContent()), // Scrollable content below
            ],
          ),
          Positioned(
            // Save button overlay remains at bottom
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildSaveButton(),
          ),
          if (_isSubmitting) // Submission overlay remains the same
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                  child: Card(
                      elevation: 4,
                      child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text("Submitting Attendance...")
                          ])))),
            ),
        ],
      ),
    );
  }

  // Session Dropdown (Shows only Title)
  Widget _buildSessionDropdown() {
    if (_isLoadingSessions) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 12.0),
        child: Center(
            child: Text("Loading sessions...",
                style: TextStyle(color: Colors.grey))),
      );
    }
    // Show specific error if schedule loading failed
    if (_errorMessage != null &&
        _sessionsForSelectedDay.isEmpty &&
        !_isLoadingSessions &&
        !_errorMessage!.startsWith("Attendance:")) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Expanded(
                child: Text("Error loading schedule: $_errorMessage",
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center))
          ]),
        ),
      );
    }

    // Show message if no sessions found for the day
    if (_sessionsForSelectedDay.isEmpty && !_isLoadingSessions) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300)),
          child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("No sessions scheduled for this day",
                    style: TextStyle(color: Colors.grey))
              ]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            // Value is the session String ID
            isExpanded: true,
            value: _selectedSessionEntry?.id, // Use the unique String ID
            hint: const Text("Select a Session"),
            icon: _isLoadingAttendance
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.keyboard_arrow_down),
            style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16),
            onChanged: _isLoadingAttendance || _isSubmitting
                ? null
                : (String? newId) {
                    if (newId != null && newId != _selectedSessionEntry?.id) {
                      final newEntry = _sessionsForSelectedDay
                          .firstWhere((e) => e.id == newId);
                      // --- FIX: Access sessionId from the details map ---
                      final newSessionId =
                          newEntry.details['sessionId'] as int?;
                      print(
                          "Dropdown changed: New Session ID = $newSessionId, Type = ${newEntry.type}");
                      setState(() {
                        _selectedSessionEntry = newEntry;
                        _selectedSessionId = newSessionId;
                        _students = []; // Clear students when changing session
                        _errorMessage = null; // Clear previous errors
                      });
                      // --- FIX: Check newSessionId ---
                      if (newEntry.type == 'LECTURE' && newSessionId != null) {
                        _fetchAttendanceData(newSessionId);
                      } else {
                        // If not a lecture, ensure loading state is false and students are empty
                        setState(() => _isLoadingAttendance = false);
                      }
                    }
                  },
            items: _sessionsForSelectedDay
                .map<DropdownMenuItem<String?>>((TeacherTimetableEntry entry) {
              // Display only the session title
              final String displayTitle = entry.title;

              final isLecture = entry.type == 'LECTURE';
              final titleStyle = TextStyle(
                  color: isLecture ? Colors.black87 : Colors.grey.shade700,
                  fontSize: 16);

              return DropdownMenuItem<String?>(
                value: entry.id, // Use the unique String ID
                enabled: true,
                child: Text(
                  displayTitle, // Use the title only
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Main content area below dropdown and date navigator
  Widget _buildBodyContent() {
    if (_isLoadingSessions && _students.isEmpty) {
      // Show nothing if we are loading sessions for the first time
      // or for a new week
      return const Center(child: CircularProgressIndicator());
    }
    // Show error if schedule loading failed and list is still empty
    if (_errorMessage != null &&
        _sessionsForSelectedDay.isEmpty &&
        !_isLoadingSessions &&
        !_errorMessage!.startsWith("Attendance:")) {
      return Container(); // Error is shown above dropdown
    }

    if (_selectedSessionEntry == null &&
        _sessionsForSelectedDay.isEmpty &&
        !_isLoadingSessions) {
      // Message already shown in dropdown area if no sessions
      return Container();
    }
    if (_selectedSessionEntry == null &&
        _sessionsForSelectedDay.isNotEmpty &&
        !_isLoadingSessions) {
      return const Center(
          child: Text("Please select a session from the dropdown."));
    }

    // Show message for non-lecture sessions
    if (_selectedSessionEntry != null &&
        _selectedSessionEntry!.type != 'LECTURE') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "Attendance is only available for 'LECTURE' sessions.\nSelected: ${_selectedSessionEntry!.title} (${_selectedSessionEntry!.type})",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // Show loading indicator for attendance fetching (only applies to lectures now)
    if (_isLoadingAttendance) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error message if attendance fetch failed (and list is empty)
    if (_errorMessage != null &&
        _students.isEmpty &&
        _selectedSessionId != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text(
                '$_errorMessage', // Show full error message
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                // Retry only if it's an attendance error
                onPressed: _errorMessage!.startsWith("Attendance:")
                    ? () => _fetchAttendanceData(_selectedSessionId!)
                    : null,
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      );
    }

    // Show message if session is selected but no students found
    if (_students.isEmpty &&
        _selectedSessionId != null &&
        !_isLoadingAttendance) {
      return const Center(
        child: Text(
          'No students enrolled in this lecture session.', // More specific message
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Display attendance list (only if _students is not empty)
    if (_students.isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90, left: 16, right: 16, top: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAttendanceSummary(),
            const SizedBox(height: 24),
            const Text('Student List',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildMarkAllPresentButton(),
            const SizedBox(height: 20),
            ..._students.map((student) => _buildStudentCard(student)).toList(),
          ],
        ),
      );
    }

    // Fallback if none of the above conditions met
    return Container();
  }

  // --- Other build methods remain unchanged ---

  Widget _buildDateNavigation() {
    final String displayDate = DateFormat('MMMM d, yyyy').format(_selectedDate);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: _isLoadingSessions || _isSubmitting
                ? null
                : () => _changeDate(-1),
          ),
          Expanded(
            // --- MODIFICATION: Wrapped Center/Text with InkWell ---
            child: InkWell(
              onTap:
                  _isLoadingSessions || _isSubmitting ? null : _showDatePicker,
              child: Center(
                child: Text(displayDate,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            // --- END MODIFICATION ---
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 20),
            onPressed: _isLoadingSessions || _isSubmitting
                ? null
                : () => _changeDate(1),
          ),
        ],
      ),
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
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 1))
            ]),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 4),
            Text('$count',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkAllPresentButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        // Disable if not a lecture or loading/submitting/no students
        onPressed: _selectedSessionEntry?.type != 'LECTURE' ||
                _isLoadingAttendance ||
                _isSubmitting ||
                _students.isEmpty
            ? null
            : _markAllPresent,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: Colors.blue.shade200),
        ),
        child: const Text('Mark All Present',
            style: TextStyle(
                color: Colors.blueAccent, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStudentCard(StudentAttendanceModel student) {
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
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage('assets/profile_dummy.png'),
                  backgroundColor: Colors.grey),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                      'ID: ${student.studentId.length > 8 ? student.studentId.substring(0, 8) : student.studentId}...',
                      style: const TextStyle(color: Colors.grey, fontSize: 14)),
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
      onTap:
          _isSubmitting ? null : () => _updateAttendanceStatus(student, status),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 35,
        height: 35,
        decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: color, width: 2) : null),
        alignment: Alignment.center,
        child: Text(status,
            style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSaveButton() {
    // Disable save if not a lecture
    final bool canSave = _selectedSessionEntry?.type == 'LECTURE';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: !canSave ||
                _isLoadingSessions ||
                _isLoadingAttendance ||
                _isSubmitting ||
                _students.isEmpty
            ? null
            : _saveAttendance,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
        label: Text(_isSubmitting ? 'Saving...' : 'Save Attendance',
            style: const TextStyle(fontSize: 18, color: Colors.white)),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            minimumSize: const Size(double.infinity, 50),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            disabledBackgroundColor: Colors.grey.shade400),
      ),
    );
  }
} // End of _ManageAttendanceScreenState
