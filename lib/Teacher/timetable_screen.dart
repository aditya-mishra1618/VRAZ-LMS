import 'package:flutter/material.dart';
import 'package:vraz_application/Teacher/services/timetable_api_service.dart';
import '../teacher_session_manager.dart';
import 'teacher_app_drawer.dart';


// Local UI model
class TimetableEntry {
  final String time;
  final String title;
  final String? center;
  final String duration;
  final String type; // 'class', 'break', 'doubt'

  TimetableEntry({
    required this.time,
    required this.title,
    this.center,
    required this.duration,
    required this.type,
  });
}

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<TimetableEntry> _dailySchedule = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTimetable();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTimetable() async {
    try {
      print('[DEBUG] Fetching teacher session...');
      final sessionManager = TeacherSessionManager();
      final session = await sessionManager.getSession();

      if (session == null) {
        print('[ERROR] No session found. Teacher not logged in.');
        setState(() {
          _error = 'No session found. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      final token = session['token'].toString().trim();
      print('[DEBUG] Token retrieved: $token');

      final service = TeacherTimetableService(token: token);
      final timetable = await service.fetchTimetable(
        startDate: '2025-10-13',
        endDate: '2025-10-19',
      );

      setState(() {
        _dailySchedule = timetable.map((entry) {
          final type = entry.type == 'LECTURE'
              ? 'class'
              : entry.type == 'AVAILABILITY_SLOT'
              ? 'doubt'
              : 'break';

          final duration = entry.endTime
              .difference(entry.startTime)
              .inMinutes
              .toString() +
              ' min';

          final time =
              "${entry.startTime.hour.toString().padLeft(2, '0')}:${entry.startTime.minute.toString().padLeft(2, '0')}";

          return TimetableEntry(
            time: time,
            title: entry.title,
            center: entry.details['batchId']?.toString(),
            duration: duration,
            type: type,
          );
        }).toList();

        _isLoading = false;
      });
    } catch (e) {
      print('[ERROR] Failed to fetch timetable: $e');
      if (e.toString().contains('Unauthorized')) {
        await TeacherSessionManager().clearSession();
        print('[DEBUG] Cleared expired session. Please log in again.');
      }
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: const TeacherAppDrawer(),
      appBar: AppBar(
        title: const Text(
          "Prof. RamSwaroop's Timetable",
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.withOpacity(0.2),
        centerTitle: true,
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyTimetable(),
          _buildWeeklyPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildDailyTimetable() {
    if (_isLoading) {
      print('[DEBUG] Loading timetable...');
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      print('[DEBUG] Displaying error: $_error');
      return Center(child: Text('Error: $_error'));
    }

    if (_dailySchedule.isEmpty) {
      print('[DEBUG] No classes scheduled.');
      return const Center(child: Text('No classes scheduled.'));
    }

    print('[DEBUG] Displaying timetable with ${_dailySchedule.length} entries.');

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Monday, October 21',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 20),
        ..._dailySchedule.map((entry) => _buildTimetableEntry(entry)),
      ],
    );
  }

  Widget _buildTimetableEntry(TimetableEntry entry) {
    Color cardColor;
    switch (entry.type) {
      case 'doubt':
        cardColor = Colors.yellow.shade100;
        break;
      case 'break':
        cardColor = Colors.grey.shade100;
        break;
      case 'class':
      default:
        cardColor = Colors.blue.shade50;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              entry.time,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87),
                  ),
                  if (entry.center != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Center: ${entry.center}',
                      style: TextStyle(
                          fontSize: 14, color: Colors.black.withOpacity(0.6)),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Duration: ${entry.duration}',
                    style: TextStyle(
                        fontSize: 13, color: Colors.black.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_view_week, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Weekly schedule is not yet available.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
