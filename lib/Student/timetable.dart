import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:provider/provider.dart';

// 2. PROJECT FILES
import '../student_session_manager.dart'; // Make sure path is correct
import 'app_drawer.dart'; // Make sure path is correct
import 'service/api_service.dart'; // Make sure path is correct

// UI Model for timetable entry (kept the same)
class TimetableEntry {
  final String startTime;
  final String endTime;
  final String subject;
  final String professor;
  final bool isBreak; // You might not need this if API doesn't indicate breaks

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

// Add SingleTickerProviderStateMixin for TabController
class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  // <-- Added mixin
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController; // <-- Added TabController

  // State Variables
  late DateTime _currentDate; // For daily view navigation
  DateTime? _currentWeekStartDate; // To track the currently fetched week
  Map<int, List<TimetableEntry>> _schedule =
      {}; // Holds data for the fetched week
  bool _isLoading = true;
  String? _errorMessage;
  String? _authToken; // Store the token

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this); // Initialize TabController
    // --- MODIFICATION: Removed weekend skipping ---
    _currentDate = DateTime.now(); // Was: _getInitialDate();

    // Fetch token and initial timetable
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeAndFetch();
    });
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose TabController
    super.dispose();
  }

  // --- REMOVED: _getInitialDate() function is no longer needed ---
  // DateTime _getInitialDate() { ... }

  // Get token and perform initial fetch
  Future<void> _initializeAndFetch() async {
    final sessionManager = Provider.of<SessionManager>(context, listen: false);
    _authToken = sessionManager.authToken;
    print('🎟️ Bearer Token on TimetableScreen: $_authToken');

    if (_authToken == null || _authToken!.isEmpty) {
      setState(() {
        _errorMessage = "Authentication token not found. Please log in.";
        _isLoading = false;
      });
      return;
    }
    // Fetch timetable for the current week
    await _fetchTimetableForWeek(_currentDate);
  }

  // Fetches timetable for the week containing the given date
  Future<void> _fetchTimetableForWeek(DateTime dateInWeek) async {
    if (_authToken == null) return; // Don't fetch without token

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final weekDates = _getWeekStartAndEnd(dateInWeek);
      // --- FIX: Use $1 and $2 ---
      final startDateStr = DateFormat('yyyy-MM-dd').format(weekDates.$1);
      final endDateStr = DateFormat('yyyy-MM-dd').format(weekDates.$2);

      print('🔄 Fetching timetable for week: $startDateStr to $endDateStr');

      final apiService = ApiService();
      final timetableList = await apiService.fetchTimetable(
        _authToken!,
        startDateStr,
        endDateStr,
      );

      print('📊 Total entries from API: ${timetableList.length}');

      final Map<int, List<TimetableEntry>> scheduleMap = {};
      for (var item in timetableList) {
        // Use local time for display purposes
        final localStartTime = item.startTime.toLocal();
        final localEndTime = item.endTime.toLocal();
        final weekday = localStartTime.weekday;

        if (!scheduleMap.containsKey(weekday)) {
          scheduleMap[weekday] = [];
        }

        scheduleMap[weekday]!.add(
          TimetableEntry(
            startTime: DateFormat('HH:mm').format(localStartTime), // Use intl
            endTime: DateFormat('HH:mm').format(localEndTime), // Use intl
            subject: item.subjectName,
            professor: item.teacherName,
            isBreak: false, // Assuming API doesn't specify breaks
          ),
        );
      }

      // Sort entries within each day
      for (var day in scheduleMap.keys) {
        scheduleMap[day]!.sort((a, b) => a.startTime.compareTo(b.startTime));
      }

      setState(() {
        _schedule = scheduleMap;
        _currentWeekStartDate = weekDates
            .$1; // --- FIX: Use $1 --- Store the start date of the fetched week
        _isLoading = false;
      });
      print('✅ Timetable map ready for UI for week starting $startDateStr.');
    } catch (e) {
      print('⚠️ Error fetching timetable: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $_errorMessage'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // Navigate dates in the Daily view
  void _changeDate(int days) {
    final oldDate = _currentDate;
    setState(() {
      _currentDate = _currentDate.add(Duration(days: days));
      // --- MODIFICATION: Removed weekend skipping logic ---
      // if (_currentDate.weekday == DateTime.saturday) { ... }
      // else if (_currentDate.weekday == DateTime.sunday) { ... }
    });

    // Check if the week has changed
    // --- FIX: Use $1 ---
    final newWeekStartDate = _getWeekStartAndEnd(_currentDate).$1;
    if (newWeekStartDate != _currentWeekStartDate) {
      print('❗ Week changed. Refetching data.');
      _fetchTimetableForWeek(_currentDate); // Fetch data for the new week
    }
  }

  // Helper to get Monday (start) and Sunday (end) of the week for a given date
  // Returns a tuple: (Monday_Date, Sunday_Date)
  (DateTime, DateTime) _getWeekStartAndEnd(DateTime date) {
    final daysToSubtract = date.weekday - DateTime.monday;
    final monday = date.subtract(Duration(days: daysToSubtract));
    final sunday = monday.add(const Duration(days: 6));
    return (monday, sunday);
  }

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: Colors.white, // Changed for better tab contrast
        elevation: 1, // Added elevation
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh,
                color: Colors.black54), // Refresh button
            onPressed:
                _isLoading ? null : () => _fetchTimetableForWeek(_currentDate),
          ),
        ],
        // --- Added TabBar ---
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
        // --- End TabBar ---
      ),
      // --- Added TabBarView ---
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyTimetable(), // First tab content
          _buildWeeklyTimetable(), // Second tab content
        ],
      ),
      // --- End TabBarView ---
    );
  }

  // Builds the content for the "Daily" tab
  Widget _buildDailyTimetable() {
    // Use DateFormat for display
    final formattedDate = DateFormat('d MMMM, EEEE').format(_currentDate);
    final dailySchedule = _schedule[_currentDate.weekday] ?? [];

    return Column(
      children: [
        _buildDateNavigator(formattedDate), // Pass formatted date string
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text("Error: $_errorMessage"))
                  : dailySchedule.isEmpty
                      ? const Center(
                          child: Text("No classes scheduled for this day."))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: dailySchedule.length,
                          itemBuilder: (context, index) {
                            return _buildTimelineEntry(dailySchedule[index]);
                          },
                        ),
        ),
      ],
    );
  }

  // Builds the content for the "Weekly" tab
  Widget _buildWeeklyTimetable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text("Error: $_errorMessage"));
    }
    if (_schedule.isEmpty && !_isLoading) {
      return const Center(child: Text("No schedule found for this week."));
    }

    // Get week range string
    final weekDates = _getWeekStartAndEnd(_currentDate);
    // --- FIX: Use $1 and $2 ---
    final weekRange =
        "${DateFormat('d MMM').format(weekDates.$1)} - ${DateFormat('d MMM, yyyy').format(weekDates.$2)}";

    // --- MODIFICATION: Added Saturday and Sunday ---
    final weekdays = [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
      DateTime.sunday
    ];
    final weekdayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    // --- END MODIFICATION ---

    return SingleChildScrollView(
      // Allow scrolling if content overflows
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Week: $weekRange",
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(weekdays.length, (index) {
                final day = weekdays[index];
                final daySchedule = _schedule[day] ?? [];
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        weekdayNames[index],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent),
                      ),
                      const Divider(height: 8),
                      if (daySchedule.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child:
                              Text("—", style: TextStyle(color: Colors.grey)),
                        )
                      else
                        ...daySchedule
                            .map((entry) => _buildWeeklyClassCard(entry)),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // Navigator specific to Daily view
  Widget _buildDateNavigator(String displayDate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: _isLoading ? null : () => _changeDate(-1),
          ),
          Text(
            displayDate, // Use the formatted string
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: _isLoading ? null : () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  // Card for the Daily view list
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

  // Break widget (if needed)
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

  // Class card used in Daily view
  Widget _buildClassCard(TimetableEntry entry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: const Border(
              left: BorderSide(color: Colors.blueAccent, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            )
          ]),
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

  // Smaller card for the Weekly view columns
  Widget _buildWeeklyClassCard(TimetableEntry entry) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.subject,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              overflow: TextOverflow.ellipsis, // Prevent overflow
            ),
            const SizedBox(height: 4),
            Text(
              entry.professor,
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${entry.startTime}-${entry.endTime}',
              style: TextStyle(color: Colors.grey[700], fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
} // End of _TimetableScreenState
