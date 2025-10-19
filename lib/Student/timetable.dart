import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../session_manager.dart';
import 'api_service.dart';
import 'app_drawer.dart';


// UI Model for timetable entry
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

  Map<int, List<TimetableEntry>> _schedule = {};

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    if (_currentDate.weekday > 5) {
      _currentDate =
          _currentDate.subtract(Duration(days: _currentDate.weekday - 5));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sessionManager =
      Provider.of<SessionManager>(context, listen: false);
      final token = sessionManager.authToken;
      print('🎟️ Bearer Token on TimetableScreen: $token');

      await _fetchTimetable(token!);
    });
  }

  Future<void> _fetchTimetable(String authToken) async {
    try {
      final apiService = ApiService();
      final timetableList = await apiService.fetchTimetable(
        authToken,
        "2025-10-13",
        "2025-11-19",
      );

      print('📊 Total entries from API: ${timetableList.length}');

      final Map<int, List<TimetableEntry>> scheduleMap = {};

      for (var item in timetableList) {
        final weekday = item.startTime.weekday;
        if (!scheduleMap.containsKey(weekday)) {
          scheduleMap[weekday] = [];
        }

        scheduleMap[weekday]!.add(
          TimetableEntry(
            startTime:
            "${item.startTime.hour.toString().padLeft(2, '0')}:${item.startTime.minute.toString().padLeft(2, '0')}",
            endTime:
            "${item.endTime.hour.toString().padLeft(2, '0')}:${item.endTime.minute.toString().padLeft(2, '0')}",
            subject: item.subjectName,
            professor: item.teacherName,
            isBreak: false,
          ),
        );
      }

      for (var day in scheduleMap.keys) {
        scheduleMap[day]!.sort((a, b) => a.startTime.compareTo(b.startTime));
      }

      setState(() {
        _schedule = scheduleMap;
      });
      print('✅ Timetable map ready for UI.');
    } catch (e) {
      print('⚠️ Error fetching timetable: $e');
    }
  }

  void _changeDate(int days) {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: days));
      if (_currentDate.weekday == 6) {
        _currentDate = _currentDate.add(const Duration(days: 2));
      } else if (_currentDate.weekday == 7) {
        _currentDate = _currentDate.add(const Duration(days: 1));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
