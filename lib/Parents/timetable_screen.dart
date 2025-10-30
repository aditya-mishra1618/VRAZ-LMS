import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vraz_application/Parents/service/timetable_service.dart';
import '../parent_session_manager.dart';
import 'models/timetable_model.dart';
import 'parent_app_drawer.dart';

class TimetableScreen extends StatefulWidget {
  final int? childId;

  const TimetableScreen({super.key, this.childId});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  DateTime _selectedDate = DateTime.now();
  List<TimetableModel> _weeklyTimetable = [];
  List<TimetableModel> _dailyTimetable = [];
  StudentInfoModel? _studentInfo;
  bool _isLoading = false;
  String? _errorMessage;

  late DateTime _currentWeekStart;

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getWeekStart(_selectedDate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTimetable();
    });
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // Comprehensive child entry parser that handles all possible types
  int? _parseChildEntry(dynamic entry) {
    print('[PARSE] Raw entry: $entry');
    print('[PARSE] Entry type: ${entry.runtimeType}');

    try {
      if (entry == null) {
        print('[PARSE] Entry is null');
        return null;
      }

      // Direct int
      if (entry is int) {
        print('[PARSE] ✅ Direct int: $entry');
        return entry;
      }

      // String number
      if (entry is String) {
        final parsed = int.tryParse(entry);
        print('[PARSE] String "$entry" -> ${parsed ?? "null"}');
        return parsed;
      }

      // ParentChild model (has .id property)
      if (entry.runtimeType.toString().contains('ParentChild')) {
        try {
          final id = (entry as dynamic).id;
          print('[PARSE] ✅ ParentChild model, id: $id');
          if (id is int) return id;
          if (id is String) return int.tryParse(id);
        } catch (e) {
          print('[PARSE] Error accessing ParentChild.id: $e');
        }
      }

      // Always visible debug card (even in release mode for troubleshooting)
      Widget _buildDebugCard() {
        final sessionManager = Provider.of<ParentSessionManager>(context, listen: false);
        final token = sessionManager.token;
        final parent = sessionManager.currentParent;

        String childrenInfo = 'null';

        if (parent != null) {
          try {
            final children = parent.children; // List<String>
            childrenInfo = 'Type: ${children.runtimeType}\n';
            childrenInfo += 'Count: ${children.length}\n';

            if (children.isNotEmpty) {
              childrenInfo += 'IDs: ${children.join(", ")}\n';
              childrenInfo += 'First ID: ${children.first}';
            } else {
              childrenInfo += 'List is EMPTY!';
            }
          } catch (e) {
            childrenInfo = 'Error: $e';
          }
        }

        return Card(
          color: Colors.orange.shade100,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔍 DEBUG INFO',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'Token: ${token != null ? "✅ Present" : "❌ Missing"}\n'
                      'Widget childId: ${widget.childId ?? "null"}\n'
                      'Parent: ${parent != null ? "✅ ${parent.fullName}" : "❌ Missing"}\n'
                      'Children (String IDs):\n$childrenInfo',
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        );
      }

      Future<void> _loadTimetable() async {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        try {
          final sessionManager = Provider.of<ParentSessionManager>(context, listen: false);
          final token = sessionManager.token;

          print('\n========== LOAD TIMETABLE START ==========');
          print('[TimetableScreen] Token present: ${token != null}');

          if (token == null) {
            setState(() {
              _errorMessage = 'Session expired. Please login again.';
              _isLoading = false;
            });
            return;
          }

          // Resolve childId with detailed logging
          int? childId = widget.childId;
          print('[TimetableScreen] Widget childId: $childId');

          if (childId == null) {
            final parent = sessionManager.currentParent;
            print('[TimetableScreen] CurrentParent: ${parent != null ? "present" : "null"}');

            if (parent != null) {
              try {
                // ParentModel.children is List<String> of student IDs
                final children = parent.children;
                print('[TimetableScreen] Children raw: $children');
                print('[TimetableScreen] Children type: ${children.runtimeType}');

                if (children.isNotEmpty) {
                  final firstChildId = children.first;
                  print('[TimetableScreen] First child ID (String): $firstChildId');

                  // Parse the String ID to int
                  childId = int.tryParse(firstChildId);
                  print('[TimetableScreen] Parsed childId: $childId');
                } else {
                  print('[TimetableScreen] ❌ Children list is empty');
                }
              } catch (e, st) {
                print('[TimetableScreen] ❌ Error accessing children: $e');
                print(st);
              }
            } else {
              print('[TimetableScreen] ❌ CurrentParent is null');
            }
          }

          print('[TimetableScreen] Final resolved childId: $childId');
          print('========== LOAD TIMETABLE END ==========\n');

          if (childId == null) {
            setState(() {
              _errorMessage = 'No student linked. Please check parent profile.';
              _isLoading = false;
            });
            return;
          }

          print('[TimetableScreen] 🔍 Fetching timetable for child: $childId');

          final response = await TimetableApiService.fetchTimetable(
            childId: childId,
            token: token,
            selectedDate: _selectedDate,
          );

          print('[TimetableScreen] API Response received: ${response != null}');

          if (response != null && response['error'] != true) {
            final rawTimetable = response['timetable'];
            final List<TimetableModel> timetable = <TimetableModel>[];

            if (rawTimetable is List) {
              for (var item in rawTimetable) {
                try {
                  if (item is TimetableModel) {
                    timetable.add(item);
                  } else if (item is Map) {
                    timetable.add(TimetableModel.fromJson(Map<String, dynamic>.from(item)));
                  }
                } catch (e) {
                  print('[TimetableScreen] Error parsing timetable item: $e');
                }
              }
            }

            StudentInfoModel? student;
            final rawStudent = response['student'];
            if (rawStudent is StudentInfoModel) {
              student = rawStudent;
            } else if (rawStudent is Map) {
              try {
                student = StudentInfoModel.fromJson(Map<String, dynamic>.from(rawStudent));
              } catch (e) {
                print('[TimetableScreen] Error parsing student info: $e');
              }
            }

            final daily = timetable.where((item) {
              return item.date.year == _selectedDate.year &&
                  item.date.month == _selectedDate.month &&
                  item.date.day == _selectedDate.day;
            }).toList();

            daily.sort((a, b) => a.startTime.compareTo(b.startTime));

            setState(() {
              _weeklyTimetable = timetable;
              _dailyTimetable = daily;
              _studentInfo = student;
              _isLoading = false;
              _currentWeekStart = _getWeekStart(_selectedDate);
            });

            print('[TimetableScreen] ✅ Loaded ${_weeklyTimetable.length} total classes');
            print('[TimetableScreen] ✅ ${_dailyTimetable.length} classes for ${DateFormat('yyyy-MM-dd').format(_selectedDate)}');
          } else {
            setState(() {
              _errorMessage = response?['message'] ?? 'Failed to load timetable';
              _isLoading = false;
            });

            if (response?['statusCode'] == 401) {
              if (!mounted) return;
              _showSessionExpiredDialog();
            }
          }
        } catch (e, st) {
          print('[TimetableScreen] ❌ Error in _loadTimetable: $e');
          print(st.toString());
          setState(() {
            _errorMessage = 'An error occurred: $e';
            _isLoading = false;
          });
        }
      }

      void _showSessionExpiredDialog() {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Session Expired'),
            content: const Text('Your session has expired. Please login again.'),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  final sessionManager = Provider.of<ParentSessionManager>(context, listen: false);
                  await sessionManager.clearSession();
                  if (!mounted) return;
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      Future<void> _handleDateChange(DateTime newDate) async {
        final DateTime newWeekStart = _getWeekStart(newDate);
        final DateTime previousWeekStart = _currentWeekStart;

        setState(() {
          _selectedDate = newDate;
        });

        final daily = _weeklyTimetable.where((item) {
          return item.date.year == newDate.year &&
              item.date.month == newDate.month &&
              item.date.day == newDate.day;
        }).toList();

        setState(() {
          _dailyTimetable = daily;
        });

        if (newWeekStart != previousWeekStart) {
          _currentWeekStart = newWeekStart;
          await _loadTimetable();
        }
      }

      Future<void> _handleDownload() async {
        final sessionManager = Provider.of<ParentSessionManager>(context, listen: false);
        final token = sessionManager.token;

        if (token == null) return;

        int? childId = widget.childId;
        if (childId == null) {
          final parent = sessionManager.currentParent;
          if (parent != null && parent.children.isNotEmpty) {
            // ParentModel.children is List<String>, parse first ID
            childId = int.tryParse(parent.children.first);
          }
        }

        if (childId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot download: No student selected'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        final result = await TimetableApiService.downloadTimetable(childId: childId, token: token);

        if (!mounted) return;
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['success'] == true
                ? result['message'] ?? 'Timetable downloaded successfully!'
                : result['message'] ?? 'Download failed. Please try again.'),
            backgroundColor: result['success'] == true ? Colors.green : Colors.red,
          ),
        );
      }

      IconData _getSubjectIcon(String subject) {
        final subjectLower = subject.toLowerCase();
        if (subjectLower.contains('physics') || subjectLower.contains('chemistry')) {
          return Icons.science_outlined;
        } else if (subjectLower.contains('math')) {
          return Icons.calculate_outlined;
        } else if (subjectLower.contains('biology')) {
          return Icons.biotech_outlined;
        } else if (subjectLower.contains('english')) {
          return Icons.book_outlined;
        } else if (subjectLower.contains('doubt')) {
          return Icons.help_outline;
        } else {
          return Icons.subject_outlined;
        }
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
            backgroundColor: const Color(0xFFF0F4F8),
            elevation: 0,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.black54),
                onPressed: _loadTimetable,
                tooltip: 'Refresh',
              ),
            ],
          ),
          drawer: const ParentAppDrawer(),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? _buildErrorView()
              : RefreshIndicator(
            onRefresh: _loadTimetable,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDebugCard(), // Always visible for troubleshooting
                  if (_studentInfo != null) _buildStudentInfoCard(),
                  const SizedBox(height: 24),
                  _buildCalendar(),
                  const SizedBox(height: 24),
                  _buildTimetableHeader(),
                  const SizedBox(height: 12),
                  if (_dailyTimetable.isEmpty)
                    _buildNoClassesView()
                  else
                    ..._dailyTimetable.map((subject) => _buildSubjectCard(subject)),
                  const SizedBox(height: 24),
                  _buildDownloadButton(context),
                ],
              ),
            ),
          ),
        );
      }

      Widget _buildErrorView() {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(_errorMessage ?? 'Something went wrong', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadTimetable,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A65F8)),
                ),
              ],
            ),
          ),
        );
      }

      Widget _buildStudentInfoCard() {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: _studentInfo?.profilePicture != null ? NetworkImage(_studentInfo!.profilePicture!) : null,
                backgroundColor: Colors.blueGrey,
                child: _studentInfo?.profilePicture == null ? Text(_studentInfo?.name[0].toUpperCase() ?? 'S', style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)) : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_studentInfo?.name ?? 'Student', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text(_studentInfo?.className ?? '', style: const TextStyle(color: Colors.black54, fontSize: 16)),
                  if (_studentInfo?.rollNumber != null) Text('ID: ${_studentInfo!.rollNumber}', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ]),
              ),
            ],
          ),
        );
      }

      Widget _buildCalendar() {
        final now = _selectedDate;
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
        final daysInMonth = lastDayOfMonth.day;
        final startWeekday = firstDayOfMonth.weekday % 7;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(onPressed: () => _handleDateChange(DateTime(now.year, now.month - 1, now.day)), icon: const Icon(Icons.arrow_back_ios)),
              Text(DateFormat('MMMM d, y').format(now), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              IconButton(onPressed: () => _handleDateChange(DateTime(now.year, now.month + 1, now.day)), icon: const Icon(Icons.arrow_forward_ios)),
            ]),
            const SizedBox(height: 16),
            Table(children: [
              const TableRow(children: [
                Center(child: Text('S', style: TextStyle(fontWeight: FontWeight.bold))),
                Center(child: Text('M', style: TextStyle(fontWeight: FontWeight.bold))),
                Center(child: Text('T', style: TextStyle(fontWeight: FontWeight.bold))),
                Center(child: Text('W', style: TextStyle(fontWeight: FontWeight.bold))),
                Center(child: Text('T', style: TextStyle(fontWeight: FontWeight.bold))),
                Center(child: Text('F', style: TextStyle(fontWeight: FontWeight.bold))),
                Center(child: Text('S', style: TextStyle(fontWeight: FontWeight.bold))),
              ]),
              ..._buildCalendarRows(startWeekday, daysInMonth, now),
            ]),
          ]),
        );
      }

      List<TableRow> _buildCalendarRows(int startWeekday, int daysInMonth, DateTime currentDate) {
        List<TableRow> rows = [];
        int dayCounter = 1;
        int weekCounter = 0;

        while (dayCounter <= daysInMonth) {
          List<Widget> cells = [];

          for (int i = 0; i < 7; i++) {
            if (weekCounter == 0 && i < startWeekday) {
              cells.add(_buildDateCell('', isPlaceholder: true));
            } else if (dayCounter <= daysInMonth) {
              final isSelected = dayCounter == currentDate.day;
              final cellDate = DateTime(currentDate.year, currentDate.month, dayCounter);

              final hasClasses = _weeklyTimetable.any((item) => item.date.year == cellDate.year && item.date.month == cellDate.month && item.date.day == cellDate.day);

              cells.add(GestureDetector(onTap: () => _handleDateChange(cellDate), child: _buildDateCell(dayCounter.toString(), isSelected: isSelected, hasClasses: hasClasses)));
              dayCounter++;
            } else {
              cells.add(_buildDateCell('', isPlaceholder: true));
            }
          }

          rows.add(TableRow(children: cells));
          weekCounter++;
        }

        return rows;
      }

      Widget _buildDateCell(String date, {bool isSelected = false, bool isPlaceholder = false, bool hasClasses = false}) {
        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: isSelected ? Colors.blueAccent.withOpacity(0.8) : Colors.transparent, shape: BoxShape.circle, border: hasClasses && !isSelected ? Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 1.5) : null),
            child: Center(
              child: Text(date, style: TextStyle(color: isPlaceholder ? Colors.transparent : (isSelected ? Colors.white : Colors.black87), fontWeight: isSelected || hasClasses ? FontWeight.bold : FontWeight.normal)),
            ),
          ),
        );
      }

      Widget _buildTimetableHeader() {
        return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Classes (${_dailyTimetable.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(DateFormat('EEEE').format(_selectedDate), style: const TextStyle(fontSize: 14, color: Colors.black54)),
        ]);
      }

      Widget _buildNoClassesView() {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('No classes scheduled', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(DateFormat('MMMM d, y').format(_selectedDate), style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                ],
              ),
            ),
          ),
        );
      }

      Widget _buildSubjectCard(TimetableModel subject) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: Icon(_getSubjectIcon(subject.subject), color: Colors.blueAccent)),
              title: Text(subject.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 6),
                Row(children: [const Icon(Icons.access_time, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(subject.timeRange, style: const TextStyle(fontSize: 13))]),
                const SizedBox(height: 4),
                Row(children: [const Icon(Icons.person_outline, size: 14, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text('Faculty: ${subject.teacherName}', style: const TextStyle(color: Colors.black54, fontSize: 13)))]),
                if (subject.roomNumber != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [const Icon(Icons.room_outlined, size: 14, color: Colors.grey), const SizedBox(width: 4), Text('Room: ${subject.roomNumber}', style: const TextStyle(color: Colors.black54, fontSize: 13))]),
                ],
                if (subject.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(subject.notes!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ]),
              trailing: subject.isActive ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)), child: Text('Active', style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.w600))) : Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)), child: Text('Cancelled', style: TextStyle(color: Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.w600)))),
        );
      }

      Widget _buildDownloadButton(BuildContext context) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleDownload,
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text('Download Weekly Timetable', style: TextStyle(color: Colors.white, fontSize: 16)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        );
      }
    }