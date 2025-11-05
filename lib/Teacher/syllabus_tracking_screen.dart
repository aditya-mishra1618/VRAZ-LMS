import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Import necessary files (adjust paths as needed)
import '../teacher_session_manager.dart'; // To get auth token
// *** ENSURE this model file DOES NOT have the subjectId getter for this version ***
import 'models/timetable_model.dart'; // Timetable Entry model
import 'models/topic_models.dart'; // The new topic models
import 'services/syllabus_tracking_service.dart'; // The updated service
import 'services/timetable_api_service.dart'; // Timetable API calls
import 'teacher_app_drawer.dart';

// Special constant/object for the 'Other' subtopic option
final SubTopic _otherSubtopicOption =
    SubTopic(id: -1, name: 'Other (Enter Manually)...');

class SyllabusTrackingScreen extends StatefulWidget {
  const SyllabusTrackingScreen({super.key});

  @override
  State<SyllabusTrackingScreen> createState() => _SyllabusTrackingScreenState();
}

class _SyllabusTrackingScreenState extends State<SyllabusTrackingScreen> {
  // Services
  late TeacherTimetableService _timetableService;
  final SyllabusTrackingService _syllabusService = SyllabusTrackingService();

  // State - Session & Date
  String? _authToken;
  late DateTime _selectedDate; // Initialized in _initializeAndFetchData
  List<TeacherTimetableEntry> _allFetchedSessions = [];
  List<TeacherTimetableEntry> _sessionsForSelectedDay = [];
  TeacherTimetableEntry? _selectedSessionEntry;
  DateTime? _currentFetchedWeekStart;

  // State - Subject, Topic, SubTopic
  String _subjectName = ''; // To display subject
  List<Topic> _topicsForSubject = [];
  List<SubTopic> _subTopicsForSelectedTopic = [];
  Topic? _selectedTopic;
  SubTopic? _selectedSubTopic; // Can be null or the special 'Other' value
  bool _showManualSubtopic = false; // Flag to show manual entry field

  // Text Controllers
  final TextEditingController _manualSubTopicController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Loading and Error States
  bool _isLoadingSessions = true;
  bool _isLoadingTopics = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Global Key for the Scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndFetchData();
    });
  }

  @override
  void dispose() {
    _manualSubTopicController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- Core Logic ---

  Future<void> _initializeAndFetchData() async {
    _selectedDate = DateTime.now(); // Initialize date
    final sessionManager = TeacherSessionManager();
    final session = await sessionManager.getSession();
    if (session == null ||
        session['token'] == null ||
        (session['token'] as String).isEmpty) {
      _handleError("Authentication token not found. Please log in again.");
      return;
    }
    _authToken = session['token'] as String;
    _timetableService = TeacherTimetableService(token: _authToken!);
    // Pass isInitialFetch: true
    await _fetchScheduleForWeek(_selectedDate, isInitialFetch: true);
  }

  Future<void> _fetchScheduleForWeek(DateTime dateInWeek,
      {bool isInitialFetch = false}) async {
    if (_authToken == null) return;
    final weekDates = _getWeekStartAndEnd(dateInWeek);

    // Avoid refetching if we already have data for this week
    if (weekDates.$1 == _currentFetchedWeekStart && !isInitialFetch) {
      _filterSessionsForDate(_selectedDate);
      return;
    }

    setState(() {
      _isLoadingSessions = true;
      _errorMessage = null;
      _clearSyllabusFields();
    });

    try {
      final startDateStr = DateFormat('yyyy-MM-dd').format(weekDates.$1);
      final endDateStr = DateFormat('yyyy-MM-dd').format(weekDates.$2);
      _allFetchedSessions = await _timetableService.fetchTimetable(
          startDate: startDateStr, endDate: endDateStr);
      _currentFetchedWeekStart = weekDates.$1;

      // --- **MODIFIED LOGIC: Set initial date ONLY on first fetch** ---
      if (isInitialFetch) {
        // --- **BUG FIX** ---
        // The faulty logic that reset _selectedDate to the start of the
        // week has been removed. We now just filter for _selectedDate,
        // which is correctly set to DateTime.now() on initial load.
        // --- **END BUG FIX** ---
      }
      // --- **END MODIFIED LOGIC** ---

      _filterSessionsForDate(_selectedDate);

      if (mounted)
        setState(() {
          _isLoadingSessions = false;
        });
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _filterSessionsForDate(DateTime date) {
    final selectedDayStart = DateTime(date.year, date.month, date.day);
    List<TeacherTimetableEntry> filtered = _allFetchedSessions.where((session) {
      try {
        // *** Ensure details['subjectId'] exists and is int ***
        if (session.details['subjectId'] == null && session.type == 'LECTURE') {
          print(
              "Warning: Lecture session ${session.id} is missing subjectId in details.");
        }
        final sessionDate = DateTime(session.startTime.year,
            session.startTime.month, session.startTime.day);
        return sessionDate.isAtSameMomentAs(selectedDayStart) &&
            session.type == 'LECTURE'; // Only Lectures
      } catch (e) {
        return false;
      }
    }).toList();
    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));

    setState(() {
      _sessionsForSelectedDay = filtered;
      bool retainSelection = _selectedSessionEntry != null &&
          filtered.any((s) => s.id == _selectedSessionEntry!.id);

      TeacherTimetableEntry? newSelectedEntry = _selectedSessionEntry;
      if (!retainSelection) {
        newSelectedEntry = filtered.isNotEmpty ? filtered.first : null;
        _clearSyllabusFields(clearSession: false);
      }
      _selectedSessionEntry = newSelectedEntry;

      final currentSubjectId = _selectedSessionEntry?.details['subjectId'];

      if (_selectedSessionEntry != null && currentSubjectId is int) {
        if (!retainSelection ||
            _topicsForSubject.isEmpty ||
            (_topicsForSubject.isNotEmpty &&
                _topicsForSubject.first.subjectId != currentSubjectId)) {
          _fetchSubjectNameAndTopics(currentSubjectId);
        }
      } else {
        _subjectName = '';
        _topicsForSubject = [];
        _selectedTopic = null;
        _subTopicsForSelectedTopic = [];
        _selectedSubTopic = null;
        _showManualSubtopic = false;
        _isLoadingTopics = false;
      }
    });
  }

  Future<void> _fetchSubjectNameAndTopics(int subjectId) async {
    if (_authToken == null) return;
    setState(() {
      _isLoadingTopics = true;
      _errorMessage = null;
      _topicsForSubject = [];
      _selectedTopic = null;
      _subTopicsForSelectedTopic = [];
      _selectedSubTopic = null;
      _showManualSubtopic = false;
      _subjectName = 'Loading...';
    });

    try {
      final subjectName =
          await _syllabusService.getSubjectNameById(subjectId, _authToken!);
      final topics =
          await _syllabusService.getTopicsForSubject(subjectId, _authToken!);
      if (mounted) {
        setState(() {
          _subjectName = subjectName;
          _topicsForSubject = topics;
          _isLoadingTopics = false;
        });
      }
    } catch (e) {
      _handleError(e.toString());
      if (mounted)
        setState(() {
          _isLoadingTopics = false;
          _subjectName = 'Error';
        });
    }
  }

  // --- REFACTORED DATE CHANGE LOGIC ---
  Future<void> _onDateChanged(DateTime newDate) async {
    setState(() {
      _selectedDate = newDate;
      _clearSyllabusFields();
      _errorMessage = null;
      _sessionsForSelectedDay = [];
      _isLoadingSessions = true;
      _isLoadingTopics = false;
    });

    final newWeekStartDate = _getWeekStartAndEnd(newDate).$1;
    if (newWeekStartDate != _currentFetchedWeekStart ||
        _currentFetchedWeekStart == null) {
      await _fetchScheduleForWeek(newDate, isInitialFetch: false);
    } else {
      _filterSessionsForDate(newDate);
      final currentSubjectId = _selectedSessionEntry?.details['subjectId'];
      if (_selectedSessionEntry != null && currentSubjectId is int) {
        await _fetchSubjectNameAndTopics(currentSubjectId);
      } else {
        if (mounted) setState(() => _isLoadingSessions = false);
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

  Future<void> _saveSyllabus() async {
    if (_authToken == null) {
      _showSnackbar("Auth Error", isError: true);
      return;
    }
    // --- FIX: Access sessionId from the details map ---
    final currentSessionId =
        _selectedSessionEntry?.details['sessionId'] as int?;
    if (_selectedSessionEntry == null || currentSessionId == null) {
      _showSnackbar("Please select a valid lecture session.", isError: true);
      return;
    }
    if (_selectedTopic == null) {
      _showSnackbar("Please select a topic.", isError: true);
      return;
    }
    if (_showManualSubtopic && _manualSubTopicController.text.trim().isEmpty) {
      _showSnackbar("Please enter the sub-topic taught.", isError: true);
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showSnackbar("Please enter a description.", isError: true);
      return;
    }

    int topicIdToSend;
    String finalRemark = _descriptionController.text.trim();

    if (_selectedSubTopic != null &&
        _selectedSubTopic != _otherSubtopicOption) {
      topicIdToSend = _selectedSubTopic!.id;
    } else if (_showManualSubtopic &&
        _manualSubTopicController.text.trim().isNotEmpty) {
      topicIdToSend = _selectedTopic!.id;
      finalRemark =
          "Sub-Topic: ${_manualSubTopicController.text.trim()}\nDetails: $finalRemark";
    } else {
      topicIdToSend = _selectedTopic!.id;
    }

    print('--- Saving Syllabus ---'); /* ... debug prints ... */

    setState(() => _isSubmitting = true);
    try {
      final message = await _syllabusService.submitSyllabusRemark(
          sessionId: currentSessionId,
          topicId: topicIdToSend,
          remark: finalRemark,
          authToken: _authToken!);
      if (mounted) {
        _showSnackbar(message);
        _clearSyllabusFields(clearSession: false, clearSubject: false);
      }
    } catch (e) {
      _showSnackbar(
          'Failed to save: ${e.toString().replaceAll("Exception: ", "")}',
          isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // FIX: Ensure this always returns a tuple
  (DateTime, DateTime) _getWeekStartAndEnd(DateTime date) {
    final daysToSubtract = date.weekday - DateTime.monday;
    final monday = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysToSubtract));
    final sunday = monday
        .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    return (monday, sunday); // Explicitly return tuple
  }

  void _clearSyllabusFields(
      {bool clearSession = true, bool clearSubject = true}) {
    if (clearSession) _selectedSessionEntry = null;
    if (clearSubject) {
      _subjectName = '';
      _topicsForSubject = [];
    }
    _selectedTopic = null;
    _subTopicsForSelectedTopic = [];
    _selectedSubTopic = null;
    _showManualSubtopic = false;
    _manualSubTopicController.clear();
    _descriptionController.clear();
  }

  void _handleError(String errorMsg) {
    final displayMsg = errorMsg.replaceAll('Exception: ', '');
    print('Error: $displayMsg');
    if (mounted) {
      setState(() {
        _errorMessage = displayMsg;
        _isLoadingSessions = false;
        _isLoadingTopics = false;
      });
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : Colors.green,
          behavior: SnackBarBehavior.floating));
    }
  }

  // --- UI Building ---
  @override
  Widget build(BuildContext context) {
    if (_authToken == null && _isLoadingSessions) {
      return Scaffold(
          appBar: AppBar(title: const Text('Syllabus Tracking')),
          drawer: const TeacherAppDrawer(),
          body: const Center(child: CircularProgressIndicator()));
    }
    if (_authToken == null && _errorMessage != null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Syllabus Tracking')),
          drawer: const TeacherAppDrawer(),
          body: Center(child: Text('Error: $_errorMessage')));
    }

    return Scaffold(
      key: _scaffoldKey, // Assign key here
      backgroundColor: Colors.grey[50],
      drawer: const TeacherAppDrawer(),
      appBar: AppBar(
        // Use key to open drawer if needed, though default back button works too
        // leading: IconButton(icon: Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        surfaceTintColor: Colors.white, backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Syllabus Tracking',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // FIX: Added padding here
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSessionDropdown(), const SizedBox(height: 16),
            _buildDateSelector(), const SizedBox(height: 24),
            const Text("Syllabus Entry",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDisplayField(label: 'Subject', value: _subjectName),
            const SizedBox(height: 16),
            _buildTopicDropdown(), const SizedBox(height: 16),
            if (_selectedTopic != null &&
                _selectedTopic!.subTopics.isNotEmpty) ...[
              _buildSubTopicDropdown(),
              const SizedBox(height: 16),
            ],
            // --- FIX for Line 278 errors (Corrected Call) ---
            if (_showManualSubtopic ||
                (_selectedTopic != null &&
                    _selectedTopic!.subTopics.isEmpty)) ...[
              _buildTextField(
                  // USE NAMED PARAMETERS
                  label: 'Enter Sub-Topic Taught *',
                  hint: 'Specify sub-topic name...',
                  controller: _manualSubTopicController,
                  maxLines: 1,
                  isRequired: true),
              const SizedBox(height: 16),
            ],
            // --- FIX for Line 281 errors (Corrected Call) ---
            _buildTextField(
                // USE NAMED PARAMETERS
                label: 'Description / Details *',
                hint: 'Describe what was taught in detail...',
                controller: _descriptionController,
                maxLines: 4,
                isRequired: true),
            const SizedBox(height: 20), // Spacer before bottom bar is rendered
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: ElevatedButton.icon(
          onPressed: _isLoadingSessions || _isLoadingTopics || _isSubmitting
              ? null
              : _saveSyllabus,
          icon: _isSubmitting
              ? Container(
                  width: 20,
                  height: 20,
                  padding: const EdgeInsets.all(2.0),
                  child: const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3))
              : const Icon(Icons.save_alt_rounded, color: Colors.white),
          label: Text(_isSubmitting ? 'Saving...' : 'Save Syllabus Entry',
              style: const TextStyle(color: Colors.white, fontSize: 16)),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              disabledBackgroundColor: Colors.grey.shade400),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _isLoadingSessions || _isSubmitting
                ? null
                : () => _changeDate(-1)),
        // --- MODIFICATION: Wrapped Center/Text with InkWell ---
        Expanded(
          child: InkWell(
            onTap: _isLoadingSessions || _isSubmitting ? null : _showDatePicker,
            child: Center(
              child: Text(DateFormat('MMMM d, yyyy').format(_selectedDate),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        // --- END MODIFICATION ---
        IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _isLoadingSessions ||
                    _isSubmitting ||
                    DateUtils.isSameDay(_selectedDate, DateTime.now())
                ? null
                : () => _changeDate(1),
            color: DateUtils.isSameDay(_selectedDate, DateTime.now())
                ? Colors.grey
                : null),
      ]),
    );
  }

  Widget _buildSessionDropdown() {
    if (_isLoadingSessions) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Center(
              child: Text("Loading sessions...",
                  style: TextStyle(color: Colors.grey))));
    }
    if (_errorMessage != null &&
        _sessionsForSelectedDay.isEmpty &&
        !_isLoadingSessions &&
        !_errorMessage!.startsWith("Attendance:")) {
      return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200)),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Expanded(
                    child: Text("Error: $_errorMessage",
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center))
              ])));
    }
    if (_sessionsForSelectedDay.isEmpty && !_isLoadingSessions) {
      return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300)),
              child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("No lectures scheduled for this day",
                        style: TextStyle(color: Colors.grey))
                  ])));
    }

    return DropdownButtonFormField<String?>(
      value: _selectedSessionEntry?.id,
      hint: const Text("Select Lecture Session *"),
      isExpanded: true,
      decoration: _inputDecoration(),
      onChanged: _isSubmitting
          ? null
          : (String? newId) {
              if (newId != null && newId != _selectedSessionEntry?.id) {
                final newEntry =
                    _sessionsForSelectedDay.firstWhere((e) => e.id == newId);
                // --- FIX: Access sessionId from the details map ---
                final newSubjectId =
                    newEntry.details['subjectId']; // Access directly
                print(
                    "Session changed: ID=${newEntry.details['sessionId']}, SubjectID=$newSubjectId");
                setState(() {
                  _selectedSessionEntry = newEntry;
                  _clearSyllabusFields(clearSession: false);
                });
                if (newSubjectId is int) {
                  _fetchSubjectNameAndTopics(newSubjectId);
                } else {
                  setState(() {
                    _subjectName = 'N/A';
                    _topicsForSubject = [];
                    _isLoadingTopics = false;
                  });
                }
              }
            },
      items: _sessionsForSelectedDay.map<DropdownMenuItem<String?>>((entry) {
        final String displayTitle = entry.title;
        // --- FIX: Access sessionId from the details map ---
        final bool isValidLecture = entry.type == 'LECTURE' &&
            entry.details['sessionId'] != null &&
            entry.details['subjectId'] is int;
        return DropdownMenuItem<String?>(
          value: entry.id,
          enabled: isValidLecture,
          child: Text(displayTitle,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 16,
                  color:
                      isValidLecture ? Colors.black87 : Colors.grey.shade400)),
        );
      }).toList(),
      validator: (value) => value == null ? 'Please select a session' : null,
    );
  }

  Widget _buildDisplayField({required String label, required String value}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300)),
        child: Text(value.isEmpty ? '-' : value,
            style: TextStyle(
                fontSize: 16,
                color: value.isEmpty ? Colors.grey[600] : Colors.black87)),
      )
    ]);
  }

  Widget _buildTopicDropdown() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Topic Taught *',
          style: TextStyle(fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      DropdownButtonFormField<Topic>(
        value: _selectedTopic,
        hint: Text(_isLoadingTopics ? "Loading Topics..." : "Select Topic"),
        isExpanded: true,
        decoration: _inputDecoration(),
        onChanged: _isLoadingTopics ||
                _selectedSessionEntry == null ||
                _subjectName.isEmpty ||
                _subjectName == 'Error' ||
                _subjectName == 'N/A' ||
                _isSubmitting
            ? null
            : (Topic? newValue) {
                setState(() {
                  _selectedTopic = newValue;
                  _selectedSubTopic = null;
                  _manualSubTopicController.clear();
                  _showManualSubtopic = false;
                  if (newValue != null && newValue.subTopics.isNotEmpty) {
                    _subTopicsForSelectedTopic = newValue.subTopics;
                  } else {
                    _subTopicsForSelectedTopic = [];
                    _showManualSubtopic = newValue != null;
                  }
                });
              },
        items: _topicsForSubject
            .map<DropdownMenuItem<Topic>>((Topic topic) =>
                DropdownMenuItem<Topic>(
                    value: topic,
                    child:
                        Text(topic.name, style: const TextStyle(fontSize: 16))))
            .toList(),
        validator: (value) => value == null ? 'Please select a topic' : null,
      ),
    ]);
  }

  Widget _buildSubTopicDropdown() {
    List<SubTopic> itemsWithOther = [];
    if (_selectedTopic != null && _selectedTopic!.subTopics.isNotEmpty) {
      itemsWithOther = List.from(_selectedTopic!.subTopics);
      itemsWithOther.add(_otherSubtopicOption);
    } else {
      return Container(); // Fallback empty widget
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Sub-Topic (Optional)',
          style: TextStyle(fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      DropdownButtonFormField<SubTopic>(
        value: _selectedSubTopic,
        hint: const Text("Select Sub-Topic (or Other)"),
        isExpanded: true,
        decoration: _inputDecoration(),
        onChanged: _isSubmitting
            ? null
            : (SubTopic? newValue) {
                setState(() {
                  _selectedSubTopic = newValue;
                  _showManualSubtopic = newValue == _otherSubtopicOption;
                  if (!_showManualSubtopic) {
                    _manualSubTopicController.clear();
                  }
                });
              },
        items:
            itemsWithOther.map<DropdownMenuItem<SubTopic>>((SubTopic subTopic) {
          return DropdownMenuItem<SubTopic>(
            value: subTopic,
            child: Text(subTopic.name,
                style: TextStyle(
                    fontSize: 16,
                    fontStyle: subTopic == _otherSubtopicOption
                        ? FontStyle.italic
                        : FontStyle.normal,
                    color: subTopic == _otherSubtopicOption
                        ? Colors.grey[700]
                        : Colors.black87)),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _buildTextField(
      {required String label,
      required String hint,
      required TextEditingController controller,
      int maxLines = 1,
      bool isRequired = false}) {
    String displayLabel = isRequired ? '$label *' : label;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(displayLabel, style: const TextStyle(fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: _isSubmitting,
        decoration: _inputDecoration(hint: hint),
        validator: isRequired
            ? (value) => (value == null || value.trim().isEmpty)
                ? 'Please enter ${label.replaceAll(' *', '')}'
                : null
            : null,
      ),
    ]);
  }

  InputDecoration _inputDecoration({String hint = ''}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.0)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2.0)),
    );
  }
} // End Screen State
