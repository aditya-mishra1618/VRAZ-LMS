import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../teacher_session_manager.dart'; // Make sure this path is correct
// Import the new models and services
import 'models/assignment_api_models.dart';
import 'services/assignment_api_services.dart';
// Import your drawer (adjust path if needed)
import 'teacher_app_drawer.dart'; // Make sure this path is correct

// Enum to manage which view is currently shown
enum AssignmentScreenMode {
  initial,
  listTemplates,
  createTemplate,
  assignTemplate,
  viewSubmissions_SelectBatch,
  viewSubmissions_ListAssignments,
  viewSubmissions_ListSubmissions,
  gradeSubmission
}

// --- Main Screen Widget ---
class UploadAssignmentScreen extends StatefulWidget {
  const UploadAssignmentScreen({super.key});
  @override
  State<UploadAssignmentScreen> createState() => _UploadAssignmentScreenState();
}

class _UploadAssignmentScreenState extends State<UploadAssignmentScreen> {
  // --- State Variables ---
  AssignmentScreenMode _currentMode = AssignmentScreenMode.initial;
  String? _authToken;

  // --- Services ---
  final AssignmentApiService _assignmentApiService = AssignmentApiService();

  // --- Data ---
  List<ApiAssignmentTemplate> _templates = [];
  List<ApiAssignmentTemplate> _filteredTemplates = [];
  List<ApiBatch> _allBatches = [];
  Map<String, int> _subjectMap = {}; // To map Subject Name -> Subject ID

  // Data for List Mode
  final TextEditingController _searchController = TextEditingController();

  // Data for Create Mode
  final _createFormKey = GlobalKey<FormState>();
  final _createTitleController = TextEditingController();
  String? _createSelectedSubject; // Use String for Dropdown
  final _createTopicController = TextEditingController();
  final _createSubTopicController = TextEditingController();
  final _createInstructionsController = TextEditingController();
  String _createSelectedType = 'THEORY';
  List<McqQuestionUIData> _createMcqDataList = [];

  // Data for Assign Mode
  ApiAssignmentTemplate? _templateToAssign;
  final _assignFormKey = GlobalKey<FormState>();
  ApiBatch? _selectedBatch;
  DateTime? _dueDate; // Will store date AND time
  final _assignMarksController = TextEditingController();
  final _assignDateController = TextEditingController();

  // Data for View Submissions Mode
  ApiBatch? _viewSubmissionsSelectedBatch;
  List<ApiAssignedAssignment> _assignmentsForBatch = [];
  ApiAssignedAssignment? _selectedAssignedAssignment;
  List<ApiSubmissionSummary> _submissionsForAssignment = [];

  // Data for Grading Mode
  ApiSubmissionSummary? _submissionToGrade;
  ApiSubmissionDetail? _submissionDetail;
  final _gradeMarksController = TextEditingController();
  final _gradeFeedbackController = TextEditingController();

  // Loading States
  bool _isLoading = false; // Generic loading flag
  String? _errorMessage;

  get _createSubjectController => null;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterTemplates);
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    await _loadToken();
    if (_authToken != null) {
      await _loadInitialData(); // Pre-fetch batches and subjects
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _createTitleController.dispose();
    _createSubjectController.dispose();
    _createTopicController.dispose();
    _createSubTopicController.dispose();
    _createInstructionsController.dispose();
    for (var mcqData in _createMcqDataList) {
      mcqData.dispose();
    }
    _assignMarksController.dispose();
    _assignDateController.dispose();
    _gradeMarksController.dispose();
    _gradeFeedbackController.dispose();
    super.dispose();
  }

  // --- Core Logic ---
  Future<void> _loadToken() async {
    final sessionManager = TeacherSessionManager();
    final session = await sessionManager.getSession();
    if (session != null &&
        session['token'] != null &&
        (session['token'] as String).isNotEmpty) {
      _authToken = session['token'] as String;
    } else {
      if (mounted) {
        _showSnackbar("Authentication error. Please restart.", isError: true);
        setState(() => _errorMessage = "Authentication token not found.");
      }
    }
  }

  Future<void> _loadInitialData() async {
    if (_authToken == null) return;
    setState(() => _isLoading = true);
    try {
      final batchesFuture =
          _assignmentApiService.getMyAssignedBatches(_authToken!);
      final subjectsFuture = _assignmentApiService.getSubjectsMap(_authToken!);
      _allBatches = await batchesFuture;
      _subjectMap = await subjectsFuture;
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted)
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
    }
  }

  void _filterTemplates() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTemplates = _templates
          .where((t) =>
              t.title.toLowerCase().contains(query) ||
              // --- FIX: Call the public static method ---
              ApiAssignedAssignment.getSubjectName(t.subjectId)
                  .toLowerCase()
                  .contains(query))
          .toList();
    });
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // --- Mode Switching ---
  void _setMode(AssignmentScreenMode newMode) {
    if (newMode == AssignmentScreenMode.listTemplates) {
      _searchController.clear();
      _filteredTemplates = _templates;
    }
    if (newMode == AssignmentScreenMode.initial) {
      _clearCreateState();
      _clearAssignState();
      _clearViewSubmissionsState();
      _clearGradeState();
      _filteredTemplates = _templates;
      _searchController.clear();
    }
    setState(() {
      _currentMode = newMode;
      _errorMessage = null;
    });
  }

  // --- State Clearing Helpers ---
  void _clearCreateState() {
    _createFormKey.currentState?.reset();
    _createTitleController.clear();
    _createSelectedSubject = null;
    _createTopicController.clear();
    _createSubTopicController.clear();
    _createInstructionsController.clear();
    _createSelectedType = 'THEORY';
    for (var mcq in _createMcqDataList) {
      mcq.dispose();
    }
    _createMcqDataList = [];
  }

  void _clearAssignState() {
    _assignFormKey.currentState?.reset();
    _selectedBatch = null;
    _dueDate = null;
    _assignMarksController.clear();
    _assignDateController.clear();
    _templateToAssign = null;
  }

  void _clearViewSubmissionsState() {
    _viewSubmissionsSelectedBatch = null;
    _assignmentsForBatch = [];
    _selectedAssignedAssignment = null;
    _submissionsForAssignment = [];
  }

  void _clearGradeState() {
    _submissionToGrade = null;
    _submissionDetail = null;
    _gradeMarksController.clear();
    _gradeFeedbackController.clear();
  }

  // --- Navigation/Action Methods ---
  void _enterListMode() async {
    if (_authToken == null) {
      _showSnackbar("Not authenticated", isError: true);
      return;
    }
    _setMode(AssignmentScreenMode.listTemplates);
    setState(() => _isLoading = true);
    try {
      final templates = await _assignmentApiService.getTemplates(_authToken!);
      if (mounted)
        setState(() {
          _templates = templates;
          _filteredTemplates = templates;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
    }
  }

  void _enterCreateMode() {
    _clearCreateState();
    _setMode(AssignmentScreenMode.createTemplate);
  }

  void _enterAssignMode(ApiAssignmentTemplate template) {
    _clearAssignState();
    _templateToAssign = template;
    setState(() {
      _currentMode = AssignmentScreenMode.assignTemplate;
    });
  }

  void _enterViewSubmissionsBatchSelect() {
    _clearViewSubmissionsState();
    _setMode(AssignmentScreenMode.viewSubmissions_SelectBatch);
  }

  void _enterViewSubmissionsAssignmentList(ApiBatch batch) async {
    _viewSubmissionsSelectedBatch = batch;
    _setMode(AssignmentScreenMode.viewSubmissions_ListAssignments);
    if (_authToken == null) return;
    setState(() => _isLoading = true);
    try {
      final assignments = await _assignmentApiService.getAssignmentsForBatch(
          batch.id, _authToken!);
      if (mounted)
        setState(() {
          _assignmentsForBatch = assignments;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
    }
  }

  void _enterSubmissionDetail(ApiAssignedAssignment assignment) async {
    _selectedAssignedAssignment = assignment;
    _setMode(AssignmentScreenMode.viewSubmissions_ListSubmissions);
    if (_authToken == null) return;
    setState(() => _isLoading = true);
    try {
      final submissions = await _assignmentApiService
          .getSubmissionsForAssignment(assignment.id, _authToken!);
      if (mounted)
        setState(() {
          _submissionsForAssignment = submissions;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
    }
  }

  void _enterGradeSubmission(ApiSubmissionSummary submission) async {
    _clearGradeState();
    _submissionToGrade = submission;
    _setMode(AssignmentScreenMode.gradeSubmission);
    if (_authToken == null) return;
    setState(() => _isLoading = true);
    try {
      final detail = await _assignmentApiService.getSubmissionDetail(
          submission.id, _authToken!);
      if (mounted)
        setState(() {
          _submissionDetail = detail;
          _gradeMarksController.text = detail.marks?.toString() ?? '';
          _gradeFeedbackController.text = ''; // API response lacks 'feedback'
          _isLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
    }
  }

  void _goBack() {
    switch (_currentMode) {
      case AssignmentScreenMode.createTemplate:
      case AssignmentScreenMode.assignTemplate:
        _setMode(AssignmentScreenMode.listTemplates);
        break;
      case AssignmentScreenMode.viewSubmissions_SelectBatch:
      case AssignmentScreenMode.listTemplates:
        _setMode(AssignmentScreenMode.initial);
        break;
      case AssignmentScreenMode.viewSubmissions_ListAssignments:
        _setMode(AssignmentScreenMode.viewSubmissions_SelectBatch);
        break;
      case AssignmentScreenMode.viewSubmissions_ListSubmissions:
        _setMode(AssignmentScreenMode.viewSubmissions_ListAssignments);
        break;
      case AssignmentScreenMode.gradeSubmission:
        _setMode(AssignmentScreenMode.viewSubmissions_ListSubmissions);
        break;
      case AssignmentScreenMode.initial:
      default:
        break;
    }
  }

  // --- Save/Assign/Grade Actions ---
  Future<void> _saveTemplateAction() async {
    if (_authToken == null) {
      _showSnackbar("Auth Error", isError: true);
      return;
    }
    if (_createFormKey.currentState!.validate()) {
      if (_createSelectedSubject == null ||
          _subjectMap[_createSelectedSubject] == null) {
        _showSnackbar("Please select a valid subject.", isError: true);
        return;
      }
      bool mcqsValid = true;
      List<Map<String, dynamic>> mcqQuestionsJson = [];
      if (_createSelectedType == 'MCQ') {
        if (_createMcqDataList.isEmpty) {
          _showSnackbar('Please add at least one MCQ question.', isError: true);
          return;
        }
        for (var mcqData in _createMcqDataList) {
          if (!mcqData.isValid) {
            mcqsValid = false;
            break;
          }
          mcqQuestionsJson.add(mcqData.toJson());
        }
        if (!mcqsValid) {
          _showSnackbar(
              'Fill all MCQ fields (Question, 4 Options, and Correct Answer text).',
              isError: true);
          return;
        }
      }
      setState(() => _isLoading = true);
      try {
        final newTemplate = await _assignmentApiService.createTemplate(
          title: _createTitleController.text.trim(),
          subjectId: _subjectMap[_createSelectedSubject]!,
          topic: _createTopicController.text.trim(),
          subTopic: _createSubTopicController.text.trim(),
          type: _createSelectedType,
          instructions: _createInstructionsController.text.trim(),
          mcqQuestions: mcqQuestionsJson,
          authToken: _authToken!,
        );
        _templates.insert(0, newTemplate); // Add to local list
        if (mounted) setState(() => _isLoading = false);
        _showSnackbar('Template Saved Successfully!');
        _setMode(AssignmentScreenMode.listTemplates);
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
        _showSnackbar(e.toString(), isError: true);
      }
    } else {
      _showSnackbar('Please fix form errors.', isError: true);
    }
  }

  Future<void> _assignTemplateAction() async {
    if (_authToken == null) {
      _showSnackbar("Auth Error", isError: true);
      return;
    }
    if (_assignFormKey.currentState!.validate()) {
      if (_selectedBatch == null || _dueDate == null) {
        _showSnackbar('Select batch and due date.', isError: true);
        return;
      }
      setState(() => _isLoading = true);
      try {
        await _assignmentApiService.assignToBatch(
          templateId: _templateToAssign!.id,
          batchId: _selectedBatch!.id,
          dueDate: _dueDate!,
          maxMarks: int.parse(_assignMarksController.text.trim()),
          authToken: _authToken!,
        );
        if (mounted) setState(() => _isLoading = false);
        _showSnackbar('Template Assigned Successfully!');
        _setMode(AssignmentScreenMode.listTemplates);
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
        _showSnackbar(e.toString(), isError: true);
      }
    } else {
      _showSnackbar('Please fix form errors.', isError: true);
    }
  }

  Future<void> _saveGradeAction() async {
    if (_submissionToGrade == null || _authToken == null) return;
    if (_submissionDetail == null) {
      _showSnackbar("Submission details not loaded.", isError: true);
      return;
    }

    if (_submissionDetail!.batchAssignment.template?.type == 'THEORY') {
      final marks = int.tryParse(_gradeMarksController.text.trim());
      final maxMarks = _submissionDetail!.batchAssignment.maxMarks;
      if (marks == null) {
        _showSnackbar("Please enter valid marks.", isError: true);
        return;
      }
      if (marks < 0) {
        _showSnackbar("Marks cannot be negative.", isError: true);
        return;
      }
      if (marks > maxMarks) {
        _showSnackbar("Marks cannot exceed $maxMarks.", isError: true);
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final gradedSubmission = await _assignmentApiService.gradeSubmission(
        submissionId: _submissionToGrade!.id,
        marks: int.parse(_gradeMarksController.text.trim()),
        feedback: _gradeFeedbackController.text.trim(),
        authToken: _authToken!,
      );
      _submissionsForAssignment = _submissionsForAssignment.map((s) {
        return s.id == gradedSubmission.id
            ? ApiSubmissionSummary(
                id: gradedSubmission.id,
                batchAssignmentId: gradedSubmission.batchAssignment.id,
                studentId: gradedSubmission.studentName,
                studentName: gradedSubmission.studentName,
                submittedAt: gradedSubmission.submittedAt,
                status: gradedSubmission.status,
                marks: gradedSubmission.marks)
            : s;
      }).toList();
      if (mounted) setState(() => _isLoading = false);
      _showSnackbar("Grade Saved Successfully!");
      _setMode(AssignmentScreenMode.viewSubmissions_ListSubmissions);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showSnackbar(e.toString(), isError: true);
    }
  }

  void _addEmptyMcqField() {
    setState(() {
      _createMcqDataList.add(McqQuestionUIData());
    });
  }

  void _removeMcqField(int index) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Remove Question'),
              content: const Text('Are you sure?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      setState(() {
                        _createMcqDataList[index].dispose();
                        _createMcqDataList.removeAt(index);
                      });
                    },
                    child: const Text('Remove',
                        style: TextStyle(color: Colors.red))),
              ],
            ));
  }

  // --- UI Building ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: (_currentMode == AssignmentScreenMode.initial ||
              _currentMode == AssignmentScreenMode.listTemplates)
          ? const TeacherAppDrawer()
          : null,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  AppBar _buildAppBar() {
    String title;
    Widget? leading;
    PreferredSizeWidget? bottom;
    leading = (_currentMode != AssignmentScreenMode.initial)
        ? IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black54),
            onPressed: _goBack)
        : null;
    switch (_currentMode) {
      case AssignmentScreenMode.createTemplate:
        title = 'Create New Template';
        break;
      case AssignmentScreenMode.assignTemplate:
        title = 'Assign Template';
        break;
      case AssignmentScreenMode.listTemplates:
        title = 'Assignment Templates';
        bottom = PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                    hintText: 'Search templates...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none))),
          ),
        );
        break;
      case AssignmentScreenMode.viewSubmissions_SelectBatch:
        title = 'View Submissions';
        break;
      case AssignmentScreenMode.viewSubmissions_ListAssignments:
        title = 'Select Assignment';
        break;
      case AssignmentScreenMode.viewSubmissions_ListSubmissions:
        title = 'Submissions';
        break;
      case AssignmentScreenMode.gradeSubmission:
        title = 'Grade Submission';
        break;
      case AssignmentScreenMode.initial:
      default:
        title = 'Assignments';
        break;
    }
    return AppBar(
        title: Text(title,
            style: const TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold)),
        leading: leading,
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        bottom: bottom);
  }

  Widget? _buildFloatingActionButton() {
    switch (_currentMode) {
      case AssignmentScreenMode.createTemplate:
        return FloatingActionButton.extended(
            onPressed: _isLoading ? null : _saveTemplateAction,
            icon: _isLoading ? _miniLoader() : const Icon(Icons.save),
            label: Text(_isLoading ? 'Saving...' : 'Save Template'),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white);
      case AssignmentScreenMode.assignTemplate:
        return FloatingActionButton.extended(
            onPressed: _isLoading ? null : _assignTemplateAction,
            icon: _isLoading
                ? _miniLoader()
                : const Icon(Icons.assignment_turned_in),
            label: Text(_isLoading ? 'Assigning...' : 'Assign to Batch'),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white);
      case AssignmentScreenMode.listTemplates:
        return FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Create New'),
            onPressed: _enterCreateMode,
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white);
      default:
        return null;
    }
  }

  Widget _miniLoader() => const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));

  Widget _buildBody() {
    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child:
            Container(key: ValueKey(_currentMode), child: _buildCurrentView()));
  }

  Widget _buildCurrentView() {
    if (_isLoading && _currentMode != AssignmentScreenMode.listTemplates) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_errorMessage!,
                  style: const TextStyle(color: Colors.red))));
    }
    switch (_currentMode) {
      case AssignmentScreenMode.createTemplate:
        return _buildCreateTemplateForm();
      case AssignmentScreenMode.assignTemplate:
        return _buildAssignTemplateForm();
      case AssignmentScreenMode.listTemplates:
        return _buildTemplateList();
      case AssignmentScreenMode.viewSubmissions_SelectBatch:
        return _buildViewSubmissionsBatchSelect();
      case AssignmentScreenMode.viewSubmissions_ListAssignments:
        return _buildViewSubmissionsAssignmentList();
      case AssignmentScreenMode.viewSubmissions_ListSubmissions:
        return _buildViewSubmissionsList();
      case AssignmentScreenMode.gradeSubmission:
        return _buildGradeSubmissionForm();
      case AssignmentScreenMode.initial:
      default:
        return _buildInitialView();
    }
  }

  // --- UI Views ---

  Widget _buildInitialView() {
    if (_isLoading && _allBatches.isEmpty)
      return const Center(child: CircularProgressIndicator());
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          _buildDashboardCard(
              icon: Icons.list_alt_rounded,
              title: 'Manage Assignment Templates',
              subtitle: 'Create, view, and assign your reusable templates',
              color: Colors.blueAccent,
              onTap: _enterListMode),
          const SizedBox(height: 20),
          _buildDashboardCard(
              icon: Icons.grading_rounded,
              title: 'View Submissions & Grade',
              subtitle: 'Check student submissions by batch and grade',
              color: Colors.green.shade600,
              onTap: _enterViewSubmissionsBatchSelect),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required VoidCallback onTap}) {
    return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(children: [
                  Icon(icon, size: 40, color: color),
                  const SizedBox(width: 20),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14))
                      ])),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.grey, size: 18),
                ]))));
  }

  Widget _buildTemplateList() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_templates.isEmpty)
      return const Center(
          child: Text('No templates created yet. Click + to create one.'));
    if (_filteredTemplates.isEmpty)
      return const Center(child: Text('No templates match your search.'));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _filteredTemplates.length,
      itemBuilder: (context, index) {
        final template = _filteredTemplates[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(
                template.type.toUpperCase() == 'MCQ'
                    ? Icons.check_circle_outline
                    : Icons.description_outlined,
                color: Colors.blueGrey,
                size: 30),
            title: Text(template.title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            // --- FIX: Use the public static method ---
            subtitle: Text(
                '${ApiAssignedAssignment.getSubjectName(template.subjectId)} (${template.type})',
                style: TextStyle(color: Colors.grey[600])),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.blueAccent),
            onTap: () => _enterAssignMode(template),
          ),
        );
      },
    );
  }

  Widget _buildCreateTemplateForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Form(
          key: _createFormKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildFormTextField(_createTitleController, 'Title',
                'e.g., Introduction to Kinematics',
                isRequired: true),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _createSelectedSubject,
              hint: const Text('Select Subject *'),
              items: _subjectMap.keys.map((String subjectName) {
                return DropdownMenuItem<String>(
                    value: subjectName, child: Text(subjectName));
              }).toList(),
              onChanged: (String? newValue) =>
                  setState(() => _createSelectedSubject = newValue),
              decoration: _inputDecoration(hint: 'Select Subject'),
              validator: (value) =>
                  value == null ? 'Please select a subject' : null,
              isExpanded: true,
            ),
            const SizedBox(height: 16),
            _buildFormTextField(
                _createTopicController, 'Topic', 'e.g., Mechanics',
                isRequired: true),
            const SizedBox(height: 16),
            _buildFormTextField(
                _createSubTopicController, 'Sub-Topic', 'e.g., Kinematics',
                isRequired: true),
            const SizedBox(height: 16),
            _buildFormTextField(_createInstructionsController,
                'Instructions (Description)', 'e.g., Answer all questions...',
                maxLines: 4, isRequired: true),
            const SizedBox(height: 20),
            const Text('Assignment Type *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Row(children: [
              Expanded(
                  child: RadioListTile<String>(
                      title: const Text('Theory/Upload'),
                      value: 'THEORY',
                      groupValue: _createSelectedType,
                      onChanged: (val) => setState(() {
                            _createSelectedType = val!;
                            _createMcqDataList.clear();
                          }),
                      contentPadding: EdgeInsets.zero)),
              Expanded(
                  child: RadioListTile<String>(
                      title: const Text('MCQ'),
                      value: 'MCQ',
                      groupValue: _createSelectedType,
                      onChanged: (val) => setState(() {
                            _createSelectedType = val!;
                            if (_createMcqDataList.isEmpty) _addEmptyMcqField();
                          }),
                      contentPadding: EdgeInsets.zero)),
            ]),
            if (_createSelectedType.toUpperCase() == 'MCQ') ...[
              const Divider(height: 30, thickness: 1),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('MCQ Questions',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: const Text('Add Question'),
                    onPressed: _addEmptyMcqField)
              ]),
              const SizedBox(height: 10),
              if (_createMcqDataList.isEmpty)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Click "Add Question" to start.',
                            style: TextStyle(color: Colors.grey)))),
              ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _createMcqDataList.length,
                  itemBuilder: (context, index) => _buildMcqInputCard(index)),
            ],
          ])),
    );
  }

  Widget _buildMcqInputCard(int index) {
    final mcqData = _createMcqDataList[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Question ${index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueAccent)),
              IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 20),
                  onPressed: () => _removeMcqField(index),
                  tooltip: 'Remove Question',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints())
            ]),
            const SizedBox(height: 12),
            TextFormField(
                controller: mcqData.questionController,
                decoration: InputDecoration(
                    labelText: 'Question Text *',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8))),
                maxLines: 2,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null),
            const SizedBox(height: 12),
            ...List.generate(mcqData.optionControllers.length, (optIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TextFormField(
                    controller: mcqData.optionControllers[optIndex],
                    decoration: InputDecoration(
                        labelText: 'Option ${optIndex + 1} *',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8))),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null),
              );
            }),
            const SizedBox(height: 8),
            TextFormField(
                controller: mcqData.correctOptionController,
                decoration: InputDecoration(
                    labelText: 'Correct Option (Enter text exactly as above) *',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8))),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!mcqData.optionControllers.any((c) =>
                      c.text.trim().toLowerCase() == v.trim().toLowerCase()))
                    return 'Must match one of the options';
                  return null;
                }),
          ])),
    );
  }

  Widget _buildAssignTemplateForm() {
    if (_templateToAssign == null)
      return const Center(child: Text("Error: No template selected."));
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Form(
        key: _assignFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Template: ${_templateToAssign!.title}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
                '${ApiAssignedAssignment.getSubjectName(_templateToAssign!.subjectId)} (${_templateToAssign!.type})',
                style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            const Divider(height: 30),
            const Text('Select Batch *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _isLoading
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2)))
                : DropdownButtonFormField<ApiBatch>(
                    value: _selectedBatch,
                    hint: const Text('Choose a batch'),
                    items: _allBatches
                        .map((ApiBatch batch) => DropdownMenuItem<ApiBatch>(
                            value: batch, child: Text(batch.name)))
                        .toList(),
                    onChanged: (ApiBatch? newValue) =>
                        setState(() => _selectedBatch = newValue),
                    decoration: _inputDecoration(hint: 'Select Batch'),
                    validator: (value) =>
                        value == null ? 'Please select a batch' : null,
                    isExpanded: true),
            const SizedBox(height: 16),
            const Text('Due Date & Time *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _assignDateController,
              readOnly: true,
              decoration: _inputDecoration(
                  hint: 'Select Due Date and Time',
                  suffixIcon:
                      const Icon(Icons.calendar_today_outlined, size: 20)),
              onTap: () => _selectDueDateTime(context),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'Please select a due date and time'
                  : null,
            ),
            if (_dueDate != null)
              Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Time left: ${_calculateTimeLeft(_dueDate!)}',
                      style: TextStyle(
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic))),
            const SizedBox(height: 16),
            const Text('Max Marks *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextFormField(
                controller: _assignMarksController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(hint: 'Enter maximum marks'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'Please enter max marks';
                  if (int.tryParse(value.trim()) == null ||
                      int.parse(value.trim()) <= 0)
                    return 'Enter a valid positive number';
                  return null;
                }),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDueDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 90)));
    if (pickedDate == null) return;
    final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
            _dueDate ?? DateTime.now().add(const Duration(hours: 1))));
    if (pickedTime == null) return;
    if (mounted) {
      setState(() {
        _dueDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute);
        _assignDateController.text =
            DateFormat('MMMM dd, yyyy - hh:mm a').format(_dueDate!);
      });
    }
  }

  String _calculateTimeLeft(DateTime due) {
    final Duration difference = due.difference(DateTime.now());
    if (difference.isNegative) return "Overdue";
    if (difference.inDays > 0)
      return '${difference.inDays} days, ${difference.inHours % 24} hours left';
    if (difference.inHours > 0)
      return '${difference.inHours} hours, ${difference.inMinutes % 60} minutes left';
    if (difference.inMinutes > 0) return '${difference.inMinutes} minutes left';
    return "Due very soon";
  }

  // --- NEW UI Views for Submissions/Grading ---

  Widget _buildViewSubmissionsBatchSelect() {
    if (_isLoading && _allBatches.isEmpty)
      return const Center(child: CircularProgressIndicator());
    if (_allBatches.isEmpty)
      return const Center(child: Text("No batches found."));
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Select Batch to View Submissions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        DropdownButtonFormField<ApiBatch>(
          value: _viewSubmissionsSelectedBatch,
          hint: const Text('Choose a batch'),
          items: _allBatches
              .map((ApiBatch batch) => DropdownMenuItem<ApiBatch>(
                  value: batch, child: Text(batch.name)))
              .toList(),
          onChanged: (ApiBatch? newValue) {
            if (newValue != null) _enterViewSubmissionsAssignmentList(newValue);
          },
          decoration: _inputDecoration(hint: 'Select Batch'),
          isExpanded: true,
          validator: (value) => value == null ? 'Please select a batch' : null,
        ),
      ]),
    );
  }

  Widget _buildViewSubmissionsAssignmentList() {
    if (_viewSubmissionsSelectedBatch == null)
      return const Center(child: Text("Error: No batch selected."));
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_assignmentsForBatch.isEmpty)
      return Center(
          child: Text(
              'No assignments found for "${_viewSubmissionsSelectedBatch!.name}".'));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
              'Assignments for "${_viewSubmissionsSelectedBatch!.name}"',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      Expanded(
          child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _assignmentsForBatch.length,
        itemBuilder: (context, index) {
          final assignment = _assignmentsForBatch[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            child: ListTile(
              leading: Icon(
                  assignment.type.toUpperCase() == 'MCQ'
                      ? Icons.check_circle_outline
                      : Icons.description_outlined,
                  color: Colors.blueGrey),
              title: Text(assignment.title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  'Due: ${DateFormat('MMM dd, yyyy').format(assignment.dueDate)} - ${assignment.subjectName}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _enterSubmissionDetail(assignment),
            ),
          );
        },
      )),
    ]);
  }

  Widget _buildViewSubmissionsList() {
    if (_selectedAssignedAssignment == null)
      return const Center(child: Text("Error: No assignment selected."));
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_submissionsForAssignment.isEmpty)
      return const Center(
          child: Text('No submissions yet for this assignment.'));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Submissions for "${_selectedAssignedAssignment!.title}"',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      Expanded(
          child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _submissionsForAssignment.length,
        itemBuilder: (context, index) {
          final submission = _submissionsForAssignment[index];
          Color statusColor =
              submission.status == 'GRADED' ? Colors.green : Colors.orange;
          String marksInfo = submission.marks != null
              ? ' (${submission.marks}/${_selectedAssignedAssignment!.maxMarks})'
              : '';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            child: ListTile(
              leading: CircleAvatar(
                  child: Text(
                      submission.studentName.substring(0, 1).toUpperCase())),
              title: Text(submission.studentName,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(
                  'Submitted: ${DateFormat('MMM dd, hh:mm a').format(submission.submittedAt)}'),
              trailing: Text('${submission.status}$marksInfo',
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              onTap: () => _enterGradeSubmission(submission),
            ),
          );
        },
      )),
    ]);
  }

  Widget _buildGradeSubmissionForm() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_submissionToGrade == null || _submissionDetail == null)
      return const Center(
          child: Text("Error: Submission details could not be loaded."));

    bool isTheory =
        _submissionDetail!.batchAssignment.template?.type.toUpperCase() ==
            'THEORY';

    if (_gradeMarksController.text.isEmpty)
      _gradeMarksController.text = _submissionDetail!.marks?.toString() ?? '';
    // TODO: Pre-fill feedback from _submissionDetail.feedback if API adds it

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Form(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Student: ${_submissionDetail!.studentName}',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
              'Assignment: ${_submissionDetail!.batchAssignment.template?.title ?? 'N/A'}'),
          Text(
              'Submitted: ${DateFormat('MMM dd, yyyy hh:mm a').format(_submissionDetail!.submittedAt)}'),
          const Divider(height: 30),
          const Text('Submission Content:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8)),
              child: isTheory
                  ? _buildTheorySubmissionContent(_submissionDetail!)
                  : _buildMcqSubmissionContent(_submissionDetail!)),
          const Divider(height: 30),
          if (isTheory) ...[
            Text(
                'Grading (Out of ${_submissionDetail!.batchAssignment.maxMarks}):',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _gradeMarksController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: 'Marks Awarded *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8))),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Marks required';
                final marks = int.tryParse(v);
                final maxMarks = _submissionDetail!.batchAssignment.maxMarks;
                if (marks == null) return 'Enter a valid number';
                if (marks < 0) return 'Marks cannot be negative';
                if (marks > maxMarks) return 'Marks cannot exceed $maxMarks';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
                controller: _gradeFeedbackController,
                decoration: InputDecoration(
                    labelText: 'Feedback (Optional)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8))),
                maxLines: 4),
            const SizedBox(height: 20),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveGradeAction,
                  icon: _isLoading ? _miniLoader() : const Icon(Icons.save),
                  label: Text(_isLoading ? 'Saving...' : 'Save Grade'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                )),
          ] else ...[
            Text('Grading (Auto-Calculated):',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Text(
                '${_submissionDetail!.marks ?? 0} / ${_submissionDetail!.batchAssignment.maxMarks}',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700)),
            const SizedBox(height: 10),
            const Center(
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Text(
                        'MCQ assignments are auto-graded by the system.',
                        style: TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.grey)))),
          ]
        ]),
      ),
    );
  }

  Widget _buildTheorySubmissionContent(ApiSubmissionDetail detail) {
    final bool hasText =
        detail.solutionText != null && detail.solutionText!.isNotEmpty;
    final bool hasAttachments = detail.solutionAttachments.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasText) Text(detail.solutionText!),
        if (hasText && hasAttachments) const Divider(height: 20),
        if (hasAttachments)
          ...detail.solutionAttachments
              .map((url) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: InkWell(
                      onTap: () => _showSnackbar(
                          "Open attachment: $url (Not implemented)"),
                      child: Row(children: [
                        Icon(Icons.link, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(url.split('/').last,
                                style: TextStyle(
                                    color: Colors.blue.shade700,
                                    decoration: TextDecoration.underline),
                                overflow: TextOverflow.ellipsis)),
                      ]),
                    ),
                  ))
              .toList(),
        if (!hasText && !hasAttachments)
          const Text('No content submitted.',
              style:
                  TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMcqSubmissionContent(ApiSubmissionDetail detail) {
    if (detail.batchAssignment.template == null ||
        detail.batchAssignment.template!.mcqQuestions.isEmpty) {
      return const Text('MCQ Questions not found in template.');
    }
    final questions = detail.batchAssignment.template!.mcqQuestions;
    final answers = detail.mcqAnswers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: questions.asMap().entries.map((entry) {
        int qIndex = entry.key;
        ApiMcqQuestion question = entry.value;
        String questionKey = question.id.toString();
        String? studentAnswer = answers[questionKey]?.toString();
        String? correctAnswer = question.correctOptionText;

        bool isCorrect = studentAnswer != null &&
            studentAnswer.toLowerCase() == correctAnswer.toLowerCase();
        Color color = studentAnswer == null
            ? Colors.grey
            : (isCorrect ? Colors.green : Colors.red);
        IconData icon = studentAnswer == null
            ? Icons.help_outline
            : (isCorrect ? Icons.check_circle : Icons.cancel);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Q${qIndex + 1}: ${question.questionText}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          studentAnswer == null
                              ? 'Not Answered'
                              : 'Answered: $studentAnswer',
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w500))),
                ],
              ),
              if (!isCorrect && studentAnswer != null)
                Padding(
                  padding: const EdgeInsets.only(left: 26.0, top: 4.0),
                  child: Text('Correct: $correctAnswer',
                      style: TextStyle(
                          color: Colors.green.shade700, fontSize: 12)),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // --- Helper Widgets ---
  InputDecoration _inputDecoration({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildFormTextField(
      TextEditingController controller, String label, String hint,
      {int maxLines = 1, bool isRequired = false}) {
    return TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: _inputDecoration(hint: hint).copyWith(
            labelText: label + (isRequired ? ' *' : ''),
            floatingLabelBehavior: FloatingLabelBehavior.always),
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return 'Please enter ${label.replaceAll(' *', '')}';
          }
          return null;
        });
  }
}
