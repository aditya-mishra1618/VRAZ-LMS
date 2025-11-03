import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vraz_application/Parents/service/timetable_service.dart';

import 'models/timetable_model.dart';
import 'parent_app_drawer.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State variables
  WeeklyTimetable? _weeklyTimetable;
  DateTime _selectedDate = DateTime.now();
  DateTime _weekStart = DateTime.now();
  DateTime _weekEnd = DateTime.now();
  bool _isLoading = true;
  String? _authToken;
  int? _selectedChildId;
  String? _selectedChildName;

  @override
  void initState() {
    super.initState();
    _initializeWeek();
    _loadTimetable();
  }

  void _initializeWeek() {
    final weekDates = TimetableApi.getCurrentWeekDates();
    _weekStart = weekDates['start']!;
    _weekEnd = weekDates['end']!;

    print('[TimetableScreen] Current week: ${TimetableApi.getDateRangeString(_weekStart, _weekEnd)}');
    print('[TimetableScreen] Week start: $_weekStart');
    print('[TimetableScreen] Week end: $_weekEnd');
  }

  Future<void> _loadTimetable() async {
    setState(() => _isLoading = true);

    try {
      // 1. Get auth token and selected child
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('parent_auth_token');
      _selectedChildId = prefs.getInt('selected_child_id');
      _selectedChildName = prefs.getString('selected_child_name');

      print('[TimetableScreen] Auth Token: ${_authToken != null ? "Found" : "Missing"}');
      print('Auth token: ${_authToken ?? "null"}');
      print('[TimetableScreen] Selected Child ID: $_selectedChildId');

      if (_authToken == null || _authToken!.isEmpty) {
        _showError('Session expired. Please login again.');
        return;
      }

      if (_selectedChildId == null) {
        _showError('No child selected. Please select a child from dashboard.');
        return;
      }

      // 2. Fetch timetable from API
      print('[TimetableScreen] 🔄 Fetching timetable...');
      _weeklyTimetable = await TimetableApi.fetchChildTimetable(
        authToken: _authToken!,
        childId: _selectedChildId!,
        startDate: _weekStart,
        endDate: _weekEnd,
      );

      if (_weeklyTimetable != null) {
        print('[TimetableScreen] ✅ Loaded ${_weeklyTimetable!.entries.length} entries');
      } else {
        print('[TimetableScreen] ⚠️ No timetable data received');
        _showInfo('No timetable available for this week.');
      }
    } catch (e, stackTrace) {
      print('[TimetableScreen] ❌ Error: $e');
      print('[TimetableScreen] Stack trace: $stackTrace');
      _showError('Failed to load timetable. Please try again.');
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

  void _showInfo(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _navigateWeek(bool isNext) {
    setState(() {
      if (isNext) {
        final nextWeek = TimetableApi.getNextWeekDates(_weekStart);
        _weekStart = nextWeek['start']!;
        _weekEnd = nextWeek['end']!;
      } else {
        final prevWeek = TimetableApi.getPreviousWeekDates(_weekStart);
        _weekStart = prevWeek['start']!;
        _weekEnd = prevWeek['end']!;
      }
      // Set selected date to the start of the new week (Monday)
      _selectedDate = _weekStart;

      print('[TimetableScreen] Navigated to week: ${TimetableApi.getDateRangeString(_weekStart, _weekEnd)}');
    });
    _loadTimetable();
  }

  List<TimetableEntry> get _selectedDateEntries {
    if (_weeklyTimetable == null) return [];
    return _weeklyTimetable!.getEntriesForDate(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black54),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'Daily Timetable',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _isLoading ? null : _loadTimetable,
            tooltip: 'Refresh',
          ),
        ],
        backgroundColor: const Color(0xFFF0F4F8),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: const ParentAppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadTimetable,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStudentInfoCard(),
              const SizedBox(height: 24),
              _buildWeekNavigator(),
              const SizedBox(height: 16),
              _buildWeekCalendar(),
              const SizedBox(height: 24),
              _buildSelectedDateHeader(),
              const SizedBox(height: 16),
              if (_selectedDateEntries.isEmpty)
                _buildNoClassesCard()
              else
                ..._selectedDateEntries.map((entry) => _buildSubjectCard(entry)),
              const SizedBox(height: 24),
              _buildDownloadButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/profile.png'),
            backgroundColor: Colors.blueGrey,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedChildName ?? 'Student',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'ID: ${_selectedChildId ?? 'N/A'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _isLoading ? null : () => _navigateWeek(false),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
        ),
        Text(
          '${DateFormat('MMM dd').format(_weekStart)} - ${DateFormat('MMM dd, yyyy').format(_weekEnd)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        IconButton(
          onPressed: _isLoading ? null : () => _navigateWeek(true),
          icon: const Icon(Icons.arrow_forward_ios, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildWeekCalendar() {
    final weekDays = List.generate(7, (index) => _weekStart.add(Duration(days: index)));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
        children: weekDays.map((date) {
          final isSelected = _selectedDate.year == date.year &&
              _selectedDate.month == date.month &&
              _selectedDate.day == date.day;
          final hasClasses = _weeklyTimetable?.getEntriesForDate(date).isNotEmpty ?? false;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              width: 40,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blueAccent
                    : (hasClasses ? Colors.blue.shade50 : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('E').format(date).substring(0, 1),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (hasClasses && !isSelected)
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
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedDateHeader() {
    return Text(
      DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate),
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildNoClassesCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No classes scheduled',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(TimetableEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(entry.icon, color: Colors.blueAccent),
        ),
        title: Text(
          entry.subjectName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.black54),
                const SizedBox(width: 4),
                Text(entry.timeRange),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.black54),
                const SizedBox(width: 4),
                Text('Faculty: ${entry.teacherName}'),
              ],
            ),
            if (entry.roomNumber != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.room, size: 14, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text('Room: ${entry.roomNumber}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading
            ? null
            : () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📥 Downloading timetable...'),
              backgroundColor: Colors.green,
            ),
          );
        },
        icon: const Icon(Icons.download, color: Colors.white),
        label: const Text(
          'Download Timetable',
          style: TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}