import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vraz_application/Student/service/attendance_api.dart';

import '../student_session_manager.dart';
import 'app_drawer.dart';
import 'models/attendance_model.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  int _selectedDateIndex = 0;
  bool _isLoading = true;

  // ✅ Week navigation variables
  DateTime _weekStart = DateTime.now();
  DateTime _weekEnd = DateTime.now();
  List<DateTime> _weekDates = [];

  // Daily data from API (keyed by full date string like '2025-01-13')
  Map<String, Map<String, dynamic>> _dailyData = {};

  @override
  void initState() {
    super.initState();
    _initializeWeek();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendance();
    });
  }

  // ✅ Initialize current week (Mon-Sun)
  void _initializeWeek() {
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday

    // Find Monday of current week
    _weekStart = now.subtract(Duration(days: weekday - 1));
    _weekEnd = _weekStart.add(const Duration(days: 6));

    _generateWeekDates();

    // Set selected index to today
    _selectedDateIndex = weekday - 1;

    print('[AttendanceScreen] Current week: ${_getDateRangeString()}');
    print('[AttendanceScreen] Week start: $_weekStart');
    print('[AttendanceScreen] Week end: $_weekEnd');
  }

  // ✅ Generate list of dates for current week
  void _generateWeekDates() {
    _weekDates.clear();
    for (int i = 0; i < 7; i++) {
      _weekDates.add(_weekStart.add(Duration(days: i)));
    }
  }

  // ✅ Navigate to previous/next week
  void _navigateWeek(bool isNext) {
    setState(() {
      if (isNext) {
        _weekStart = _weekStart.add(const Duration(days: 7));
        _weekEnd = _weekEnd.add(const Duration(days: 7));
      } else {
        _weekStart = _weekStart.subtract(const Duration(days: 7));
        _weekEnd = _weekEnd.subtract(const Duration(days: 7));
      }

      _generateWeekDates();
      _selectedDateIndex = 0; // Reset to Monday

      print('[AttendanceScreen] Navigated to week: ${_getDateRangeString()}');
    });
    _loadAttendance();
  }

  String _getDateRangeString() {
    return '${DateFormat('MMM dd').format(_weekStart)} - ${DateFormat('MMM dd, yyyy').format(_weekEnd)}';
  }

  // ✅ Load attendance from API
  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);

    try {
      final sessionManager = Provider.of<SessionManager>(context, listen: false);
      final authToken = await sessionManager.loadToken();

      if (authToken == null || authToken.isEmpty) {
        print('[Attendance] ❌ No auth token');
        _showError('Session expired. Please login again.');
        setState(() => _isLoading = false);
        return;
      }

      final records = await AttendanceApi.fetchAttendance(authToken: authToken);

      // Convert API data to daily format
      _convertApiDataToDailyFormat(records);

      print('[Attendance] ✅ Loaded ${records.length} records');
    } catch (e) {
      print('[Attendance] ❌ Error: $e');
      _showError('Failed to load attendance. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ✅ Convert API records to daily format
  void _convertApiDataToDailyFormat(List<AttendanceRecord> records) {
    _dailyData.clear();

    // Group records by full date
    for (var record in records) {
      final date = record.session.startTime;
      final dateKey = DateFormat('yyyy-MM-dd').format(date);

      if (!_dailyData.containsKey(dateKey)) {
        _dailyData[dateKey] = {
          'punchInTime': '09:05 AM',
          'punchInStatus': 'On-time',
          'punchOutTime': '05:00 PM',
          'punchOutStatus': 'Completed',
          'lectures': [],
        };
      }

      // Add lecture
      (_dailyData[dateKey]!['lectures'] as List).add({
        'icon': _getIconForSubject(record.session.subjectName),
        'subject': record.session.subjectName,
        'time': record.session.formattedTimeRange,
        'status': record.isPresent ? 'Attended' : 'Missed',
      });
    }
  }

  IconData _getIconForSubject(String subject) {
    final sub = subject.toLowerCase();
    if (sub.contains('physics')) return Icons.thermostat;
    if (sub.contains('chemistry')) return Icons.science_outlined;
    if (sub.contains('math')) return Icons.calculate_outlined;
    if (sub.contains('biology')) return Icons.biotech_outlined;
    if (sub.contains('computer')) return Icons.computer;
    if (sub.contains('geography')) return Icons.public;
    if (sub.contains('history')) return Icons.history_edu;
    if (sub.contains('trigonometry')) return Icons.functions;
    return Icons.book;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Safety checks
    if (_weekDates.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          title: const Text('Attendance'),
          backgroundColor: const Color(0xFFF0F4F8),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Ensure selectedDateIndex is valid
    if (_selectedDateIndex >= _weekDates.length) {
      _selectedDateIndex = 0;
    }

    final selectedDate = _weekDates[_selectedDateIndex];
    final dateKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    final dataForSelectedDay = _dailyData[dateKey];

    // Check if selected date is in future
    final now = DateTime.now();
    final isFutureDate = selectedDate.isAfter(DateTime(now.year, now.month, now.day));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Attendance',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _isLoading ? null : _loadAttendance,
          ),
        ],
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadAttendance,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // ✅ NEW: Week Navigator
              _buildWeekNavigator(),
              const SizedBox(height: 16),
              // ✅ Date Selector (7 days of current week)
              _buildDateSelector(),
              const SizedBox(height: 24),
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
              Text(
                DateFormat('EEEE, MMMM dd, yyyy').format(selectedDate),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildLecturesSection(dataForSelectedDay, isFutureDate),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NEW: Week Navigator Widget
  Widget _buildWeekNavigator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _isLoading ? null : () => _navigateWeek(false),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black54, size: 20),
            tooltip: 'Previous Week',
          ),
          Text(
            _getDateRangeString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          IconButton(
            onPressed: _isLoading ? null : () => _navigateWeek(true),
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 20),
            tooltip: 'Next Week',
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_weekDates.length, (index) {
          final date = _weekDates[index];
          final isSelected = index == _selectedDateIndex;

          // Check if this date has lectures
          final dateKey = DateFormat('yyyy-MM-dd').format(date);
          final hasLectures = _dailyData[dateKey] != null &&
              (_dailyData[dateKey]!['lectures'] as List).isNotEmpty;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDateIndex = index;
              });
            },
            child: Container(
              width: 40,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blueAccent
                    : (hasLectures ? Colors.blue.shade50 : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('E').format(date).substring(0, 1),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (hasLectures && !isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

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
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No lectures scheduled for this day.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
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