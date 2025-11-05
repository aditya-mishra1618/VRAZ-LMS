import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
  final DateTime startTime;
  final DateTime endTime;

  TimetableEntry({
    required this.time,
    required this.title,
    this.center,
    required this.duration,
    required this.type,
    required this.startTime,
    required this.endTime,
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

  List<TimetableEntry> _allEntries = [];
  bool _isLoading = true;
  String _error = '';

  DateTime _selectedDate = DateTime.now();
  DateTime _weekStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _weekStart = _getWeekStart(DateTime.now());
    _fetchTimetable();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Future<void> _fetchTimetable() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      print('[DEBUG] Fetching teacher session...');
      final sessionManager = Provider.of<TeacherSessionManager>(context, listen: false);
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
      print('[DEBUG] Token retrieved: ${token.substring(0, 20)}...');

      final service = TeacherTimetableService(token: token);

      // Fetch entire week
      final weekEnd = _weekStart.add(const Duration(days: 6));
      final startDateStr = DateFormat('yyyy-MM-dd').format(_weekStart);
      final endDateStr = DateFormat('yyyy-MM-dd').format(weekEnd);

      print('[DEBUG] Fetching timetable from $startDateStr to $endDateStr');

      final timetable = await service.fetchTimetable(
        startDate: startDateStr,
        endDate: endDateStr,
      );

      setState(() {
        _allEntries = timetable.map((entry) {
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
            startTime: entry.startTime,
            endTime: entry.endTime,
          );
        }).toList();

        _isLoading = false;
      });

      print('[DEBUG] ✅ Loaded ${_allEntries.length} entries');
    } catch (e) {
      print('[ERROR] Failed to fetch timetable: $e');
      if (e.toString().contains('Unauthorized')) {
        final sessionManager = Provider.of<TeacherSessionManager>(context, listen: false);
        await sessionManager.clearSession();
        print('[DEBUG] Cleared expired session. Please log in again.');
      }
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<TimetableEntry> get _todaySchedule {
    final today = DateTime.now();
    return _allEntries.where((entry) {
      return entry.startTime.year == today.year &&
          entry.startTime.month == today.month &&
          entry.startTime.day == today.day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Map<int, List<TimetableEntry>> get _weeklySchedule {
    final schedule = <int, List<TimetableEntry>>{};

    for (int i = 0; i < 7; i++) {
      final day = _weekStart.add(Duration(days: i));
      schedule[i] = _allEntries.where((entry) {
        return entry.startTime.year == day.year &&
            entry.startTime.month == day.month &&
            entry.startTime.day == day.day;
      }).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return schedule;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: const TeacherAppDrawer(),
      appBar: AppBar(
        title: const Text(
          "My Timetable",
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.withOpacity(0.2),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _fetchTimetable,
          ),
        ],
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
          _buildWeeklyTimetable(),
        ],
      ),
    );
  }

  // ==================== DAILY VIEW ====================

  Widget _buildDailyTimetable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchTimetable,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final todaySchedule = _todaySchedule;

    if (todaySchedule.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No classes scheduled for today.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTimetable,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            DateFormat('EEEE, MMMM d').format(DateTime.now()),
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 20),
          ...todaySchedule.map((entry) => _buildTimetableEntry(entry)),
        ],
      ),
    );
  }

  // ==================== WEEKLY VIEW ====================

  Widget _buildWeeklyTimetable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchTimetable,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final weekSchedule = _weeklySchedule;

    return RefreshIndicator(
      onRefresh: _fetchTimetable,
      child: Column(
        children: [
          // Week selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _weekStart = _weekStart.subtract(const Duration(days: 7));
                    });
                    _fetchTimetable();
                  },
                ),
                Text(
                  '${DateFormat('MMM d').format(_weekStart)} - ${DateFormat('MMM d').format(_weekStart.add(const Duration(days: 6)))}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _weekStart = _weekStart.add(const Duration(days: 7));
                    });
                    _fetchTimetable();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Days list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 7,
              itemBuilder: (context, index) {
                final day = _weekStart.add(Duration(days: index));
                final daySchedule = weekSchedule[index] ?? [];
                return _buildDayCard(day, daySchedule);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(DateTime day, List<TimetableEntry> schedule) {
    final isToday = day.year == DateTime.now().year &&
        day.month == DateTime.now().month &&
        day.day == DateTime.now().day;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isToday ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isToday
            ? const BorderSide(color: Colors.blueAccent, width: 2)
            : BorderSide.none,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isToday,
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isToday ? Colors.blueAccent : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEE').format(day),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.white : Colors.grey.shade700,
                  ),
                ),
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          title: Text(
            DateFormat('EEEE, MMMM d').format(day),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            schedule.isEmpty
                ? 'No classes scheduled'
                : '${schedule.length} class${schedule.length > 1 ? 'es' : ''}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          children: schedule.isEmpty
              ? [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No classes scheduled for this day',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            )
          ]
              : schedule
              .map((entry) => Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: _buildCompactEntry(entry),
          ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildCompactEntry(TimetableEntry entry) {
    Color cardColor;
    IconData icon;
    switch (entry.type) {
      case 'doubt':
        cardColor = Colors.yellow.shade100;
        icon = Icons.help_outline;
        break;
      case 'break':
        cardColor = Colors.grey.shade100;
        icon = Icons.coffee_outlined;
        break;
      case 'class':
      default:
        cardColor = Colors.blue.shade50;
        icon = Icons.class_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.time} • ${entry.duration}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (entry.center != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Center: ${entry.center}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== COMMON COMPONENTS ====================

  Widget _buildTimetableEntry(TimetableEntry entry) {
    Color cardColor;
    IconData icon;
    switch (entry.type) {
      case 'doubt':
        cardColor = Colors.yellow.shade100;
        icon = Icons.help_outline;
        break;
      case 'break':
        cardColor = Colors.grey.shade100;
        icon = Icons.coffee_outlined;
        break;
      case 'class':
      default:
        cardColor = Colors.blue.shade50;
        icon = Icons.class_outlined;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.time,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.grey.shade700),
                ),
                Icon(icon, size: 16, color: Colors.grey.shade600),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: Colors.black.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          'Center: ${entry.center}',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 14, color: Colors.black.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(
                        'Duration: ${entry.duration}',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.black.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}