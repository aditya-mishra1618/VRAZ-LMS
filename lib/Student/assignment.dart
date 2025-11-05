// 1. DART PACKAGES
import 'dart:io';

// 2. EXTERNAL PACKAGES
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:vraz_application/Student/service/assignment_api.dart';

// 3. PROJECT FILES
import '../student_session_manager.dart';
import 'app_drawer.dart';
import 'models/assignment_model.dart';

// 4. DATA MODELS
class Assignment {
  final int id;
  final String subject;
  final String title;
  final String professor;
  final String status;
  final String dueDate;
  final String submissionDate;
  final String statusDetail;
  final String type; // "MCQ" or "Theory"
  final int maxMarks;
  final String description;
  final List<Submission> submissions;
  final List<McqQuestion>? mcqQuestions;
  final bool isSubmitted;
  final bool isGraded;
  final int? obtainedMarks;

  Assignment({
    required this.id,
    required this.subject,
    required this.title,
    required this.professor,
    required this.status,
    required this.dueDate,
    required this.submissionDate,
    required this.statusDetail,
    required this.type,
    required this.maxMarks,
    required this.description,
    required this.submissions,
    this.mcqQuestions,
    required this.isSubmitted,
    required this.isGraded,
    this.obtainedMarks,
  });
}

// 5. MAIN SCREEN WIDGET
class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Assignment? _selectedAssignment;

  final List<File> _uploadedFiles = [];
  final ImagePicker _picker = ImagePicker();

  final Map<int, String> _selectedMcqAnswers = {};
  final TextEditingController _solutionTextController = TextEditingController();

  // API Service instance
  late AssignmentApiService _apiService;

  // List to store assignments from API
  List<Assignment> _assignments = [];

  // Loading and error states
  bool _isLoading = true;
  bool _isLoadingDetails = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('🎬 DEBUG: AssignmentsScreen initialized');
    print('📅 DEBUG: Current Date/Time: ${DateTime.now().toUtc().toIso8601String()}');

    _apiService = AssignmentApiService();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndFetchAssignments();
    });
  }

  @override
  void dispose() {
    _solutionTextController.dispose();
    super.dispose();
  }

  /// Initialize API service with token from SessionManager and fetch assignments
  Future<void> _initializeAndFetchAssignments() async {
    print('🔧 DEBUG: Initializing API service with SessionManager');

    final sessionManager = Provider.of<SessionManager>(context, listen: false);

    if (!sessionManager.isLoggedIn) {
      print('❌ DEBUG: User is not logged in');
      setState(() {
        _errorMessage = 'Please login to view assignments';
        _isLoading = false;
      });
      return;
    }

    final authToken = sessionManager.authToken;

    if (authToken == null || authToken.isEmpty) {
      print('❌ DEBUG: Auth token is null or empty');
      setState(() {
        _errorMessage = 'Authentication token not found. Please login again.';
        _isLoading = false;
      });
      return;
    }

    print('✅ DEBUG: Auth token retrieved from SessionManager');
    print('🔐 DEBUG: Token preview: ${authToken.substring(0, 20)}...');

    _apiService.updateBearerToken(authToken);
    await _fetchAssignments();
  }

  /// Fetches assignments from the API
  Future<void> _fetchAssignments() async {
    print('🔄 DEBUG: Starting to fetch assignments from API');
    print('⏰ DEBUG: Fetch started at: ${DateTime.now().toUtc().toIso8601String()}');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<AssignmentResponse> apiAssignments =
      await _apiService.fetchMyAssignments();

      print('✅ DEBUG: Successfully received ${apiAssignments.length} assignments from API');

      final List<Assignment> convertedAssignments =
      apiAssignments.map((apiAssignment) {
        print('🔄 DEBUG: Converting assignment ID ${apiAssignment.id}: ${apiAssignment.assignmentTemplate.title}');

        String subject = 'General';
        final titleLower = apiAssignment.assignmentTemplate.title.toLowerCase();

        if (titleLower.contains('math') || titleLower.contains('mcq')) {
          subject = 'Maths';
        } else if (titleLower.contains('physic')) {
          subject = 'Physics';
        } else if (titleLower.contains('chem')) {
          subject = 'Chemistry';
        } else if (titleLower.contains('theory')) {
          subject = 'Science';
        }

        // ✅ IMPROVED: Better status handling
        String status = 'Pending';
        String submissionDate = '';
        String statusDetail = 'Not Submitted';
        bool isSubmitted = false;
        bool isGraded = false;
        int? obtainedMarks;

        if (apiAssignment.submissions.isNotEmpty) {
          final latestSubmission = apiAssignment.submissions.first;
          isSubmitted = true;

          if (latestSubmission.status == 'GRADED') {
            isGraded = true;
            obtainedMarks = latestSubmission.marks;
            final marksText = latestSubmission.marks != null
                ? '${latestSubmission.marks}/${apiAssignment.maxMarks}'
                : 'Grading Pending';
            status = marksText;
            submissionDate = _formatDate(latestSubmission.submittedAt);
            statusDetail = 'Graded';
          } else if (latestSubmission.status == 'SUBMITTED') {
            status = 'Submitted';
            submissionDate = _formatDate(latestSubmission.submittedAt);
            statusDetail = 'Awaiting Review';
          }

          print('   - Submission Status: ${latestSubmission.status}');
          print('   - Is Graded: $isGraded');
          print('   - Marks: ${obtainedMarks ?? "Not graded"}');
        } else {
          // No submission yet - check if overdue
          final dueDateTime = DateTime.parse(apiAssignment.dueDate);
          final now = DateTime.now();

          if (now.isAfter(dueDateTime)) {
            statusDetail = 'Overdue';
            status = 'Overdue';
          } else {
            statusDetail = 'Pending';
            status = 'Not Submitted';
          }
        }

        String dueDate = _formatDate(apiAssignment.dueDate);

        return Assignment(
          id: apiAssignment.id,
          subject: subject,
          title: apiAssignment.assignmentTemplate.title,
          professor: 'Prof. Teacher',
          status: status,
          dueDate: dueDate,
          submissionDate: submissionDate,
          statusDetail: statusDetail,
          type: apiAssignment.assignmentTemplate.type,
          maxMarks: apiAssignment.maxMarks,
          description: apiAssignment.assignmentTemplate.description,
          submissions: apiAssignment.submissions,
          mcqQuestions: apiAssignment.assignmentTemplate.mcqQuestions,
          isSubmitted: isSubmitted,
          isGraded: isGraded,
          obtainedMarks: obtainedMarks,
        );
      }).toList();

      setState(() {
        _assignments = convertedAssignments;
        _isLoading = false;
      });

      print('✅ DEBUG: UI updated with ${_assignments.length} assignments');
    } catch (e) {
      print('❌ DEBUG: Error fetching assignments: $e');

      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _fetchAssignments,
            ),
          ),
        );
      }
    }
  }

  /// Fetch detailed assignment when user taps on it
  Future<void> _selectAssignment(Assignment assignment) async {
    print('🎯 DEBUG: Assignment selected: ${assignment.title} (ID: ${assignment.id})');

    // Reset state
    _uploadedFiles.clear();
    _selectedMcqAnswers.clear();
    _solutionTextController.clear();

    // If MCQ assignment, fetch detailed questions
    if (assignment.type == 'MCQ') {
      setState(() {
        _isLoadingDetails = true;
        _selectedAssignment = assignment;
      });

      try {
        print('📡 DEBUG: Fetching detailed assignment data...');
        final detailedAssignment = await _apiService.getAssignmentDetails(assignment.id);

        print('✅ DEBUG: Detailed assignment fetched successfully');

        // Update the assignment with detailed MCQ questions
        final updatedAssignment = Assignment(
          id: detailedAssignment.id,
          subject: assignment.subject,
          title: detailedAssignment.assignmentTemplate.title,
          professor: assignment.professor,
          status: assignment.status,
          dueDate: assignment.dueDate,
          submissionDate: assignment.submissionDate,
          statusDetail: assignment.statusDetail,
          type: detailedAssignment.assignmentTemplate.type,
          maxMarks: detailedAssignment.maxMarks,
          description: detailedAssignment.assignmentTemplate.description,
          submissions: detailedAssignment.submissions,
          mcqQuestions: detailedAssignment.assignmentTemplate.mcqQuestions,
          isSubmitted: assignment.isSubmitted,
          isGraded: assignment.isGraded,
          obtainedMarks: assignment.obtainedMarks,
        );

        setState(() {
          _selectedAssignment = updatedAssignment;
          _isLoadingDetails = false;
        });

        print('✅ DEBUG: Assignment details loaded with ${updatedAssignment.mcqQuestions?.length ?? 0} MCQ questions');
      } catch (e) {
        print('❌ DEBUG: Error fetching assignment details: $e');

        setState(() {
          _isLoadingDetails = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load assignment details: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }

        // Still show the basic assignment
        setState(() {
          _selectedAssignment = assignment;
        });
      }
    } else {
      // For Theory assignments, just show directly
      setState(() {
        _selectedAssignment = assignment;
      });
    }
  }

  /// Helper method to format date strings
  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      print('⚠️ DEBUG: Error formatting date: $e');
      return dateString;
    }
  }

  /// Helper method to get month name
  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  Future<void> _pickImage(ImageSource source) async {
    print('📸 DEBUG: Picking image from ${source == ImageSource.camera ? "Camera" : "Gallery"}');

    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      print('✅ DEBUG: Image picked successfully: ${pickedFile.path}');
      setState(() {
        _uploadedFiles.add(File(pickedFile.path));
      });
      print('📁 DEBUG: Total uploaded files: ${_uploadedFiles.length}');
    } else {
      print('⚠️ DEBUG: No image selected');
    }
  }

  void _goBackToList() {
    print('⬅️ DEBUG: Going back to assignment list');
    setState(() {
      _selectedAssignment = null;
    });
  }

  /// Submit Assignment with API integration
  Future<void> _submitAssignment() async {
    if (_selectedAssignment == null) return;

    print('📤 DEBUG: ========== ASSIGNMENT SUBMISSION ==========');
    print('📤 DEBUG: Assignment Title: ${_selectedAssignment!.title}');
    print('📤 DEBUG: Assignment ID: ${_selectedAssignment!.id}');
    print('📤 DEBUG: Assignment Type: ${_selectedAssignment!.type}');
    print('📤 DEBUG: Submission Time: ${DateTime.now().toUtc().toIso8601String()}');

    final bool hasMcqs = _selectedAssignment!.type == 'MCQ';

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (hasMcqs) {
        // MCQ Submission
        print('📝 DEBUG: MCQ Assignment Submission');
        print('📝 DEBUG: Total Questions Answered: ${_selectedMcqAnswers.length}');

        // Convert Map<int, String> to Map<String, String> with question IDs
        final Map<String, String> mcqAnswersForApi = {};
        _selectedMcqAnswers.forEach((questionIndex, selectedOption) {
          final questionId = _selectedAssignment!.mcqQuestions![questionIndex].id.toString();
          mcqAnswersForApi[questionId] = selectedOption;
          print('📝 DEBUG:   Question ID $questionId: $selectedOption');
        });

        print('📝 DEBUG: Formatted MCQ Answers: $mcqAnswersForApi');

        await _apiService.submitMcqAssignment(
          assignmentId: _selectedAssignment!.id,
          mcqAnswers: mcqAnswersForApi,
        );

        print('✅ DEBUG: MCQ assignment submitted successfully!');
      } else {
        // ✅ Theory Submission - Attachments are OPTIONAL
        print('📁 DEBUG: Theory Assignment Submission');

        final String solutionText = _solutionTextController.text.trim();

        // ✅ FIXED: Only text is required, files are optional
        if (solutionText.isEmpty) {
          throw Exception('Please provide a text solution');
        }

        print('📁 DEBUG: Solution Text: $solutionText');
        print('📁 DEBUG: Total Files to upload: ${_uploadedFiles.length}');

        // Upload files and get URLs (optional)
        List<String> uploadedUrls = [];

        if (_uploadedFiles.isNotEmpty) {
          print('📤 DEBUG: Starting file uploads...');

          for (int i = 0; i < _uploadedFiles.length; i++) {
            final file = _uploadedFiles[i];
            print('📤 DEBUG: Uploading file ${i + 1}/${_uploadedFiles.length}: ${file.path}');

            try {
              final url = await _apiService.uploadFile(file);
              uploadedUrls.add(url);
              print('✅ DEBUG: File ${i + 1} uploaded successfully: $url');

              // Show progress
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Uploaded ${i + 1}/${_uploadedFiles.length} files'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            } catch (e) {
              print('❌ DEBUG: Failed to upload file ${i + 1}: $e');
              throw Exception('Failed to upload file ${i + 1}: ${e.toString()}');
            }
          }

          print('✅ DEBUG: All files uploaded successfully!');
          print('📎 DEBUG: Uploaded URLs: $uploadedUrls');
        } else {
          print('ℹ️ DEBUG: No files to upload (optional)');
        }

        // Submit assignment with text and URLs
        await _apiService.submitTheoryAssignment(
          assignmentId: _selectedAssignment!.id,
          solutionText: solutionText,
          solutionAttachments: uploadedUrls.isEmpty ? [] : uploadedUrls,
        );

        print('✅ DEBUG: Theory assignment submitted successfully!');
      }

      setState(() {
        _isSubmitting = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment submitted successfully! ✅'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      print('📤 DEBUG: ========================================');

      // Refresh assignments and go back
      await _fetchAssignments();
      _goBackToList();

    } catch (e) {
      print('❌ DEBUG: Submission failed: $e');

      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _selectedAssignment == null
        ? _buildAssignmentListView()
        : _buildAssignmentDetailView(_selectedAssignment!);
  }

  Widget _buildAssignmentListView() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black54),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'Assignments',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: () {
              print('🔄 DEBUG: Refresh button pressed by user');
              _fetchAssignments();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading assignments...'),
          ],
        ),
      )
          : _errorMessage != null && _assignments.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error loading assignments',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchAssignments,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      )
          : _assignments.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No assignments found',
              style: TextStyle(
                  fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchAssignments,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _assignments.length,
        itemBuilder: (context, index) {
          final assignment = _assignments[index];
          return _buildAssignmentCard(assignment);
        },
      ),
    );
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    // ✅ IMPROVED: Better color coding based on status
    Color statusColor;
    Color cardBorderColor;

    if (assignment.isGraded) {
      statusColor = Colors.green;
      cardBorderColor = Colors.green.shade200;
    } else if (assignment.isSubmitted) {
      statusColor = Colors.blue;
      cardBorderColor = Colors.blue.shade200;
    } else if (assignment.statusDetail == 'Overdue') {
      statusColor = Colors.red;
      cardBorderColor = Colors.red.shade200;
    } else {
      statusColor = Colors.orange;
      cardBorderColor = Colors.grey.shade200;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardBorderColor, width: 2),
      ),
      child: InkWell(
        onTap: () => _selectAssignment(assignment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    assignment.subject == 'Physics'
                        ? Icons.rocket_launch_outlined
                        : assignment.subject == 'Maths'
                        ? Icons.calculate_outlined
                        : Icons.science_outlined,
                    color: Colors.grey[600],
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${assignment.subject}: ${assignment.title}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          assignment.professor,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // ✅ IMPROVED: Better status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Text(
                      assignment.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${assignment.dueDate}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  if (assignment.isSubmitted)
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          assignment.submissionDate,
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        assignment.statusDetail,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              // ✅ NEW: Show marks if graded
              if (assignment.isGraded) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.grade, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Score: ${assignment.obtainedMarks}/${assignment.maxMarks}',
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${((assignment.obtainedMarks! / assignment.maxMarks) * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentDetailView(Assignment assignment) {
    print('🔍 DEBUG: Displaying assignment details for: ${assignment.title} (ID: ${assignment.id})');

    if (_isLoadingDetails) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black54),
            onPressed: _goBackToList,
          ),
          title: const Text('Assignment Details',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading assignment details...'),
            ],
          ),
        ),
      );
    }

    final String description = assignment.description;
    final bool hasMcqs = assignment.type == 'MCQ';
    final List<McqQuestion> questionsToDisplay = assignment.mcqQuestions ?? [];

    print('📝 DEBUG: Assignment type: ${assignment.type}, Has MCQs: $hasMcqs');
    print('📝 DEBUG: MCQ Questions count: ${questionsToDisplay.length}');
    print('📝 DEBUG: Is Submitted: ${assignment.isSubmitted}');
    print('📝 DEBUG: Is Graded: ${assignment.isGraded}');

    // If already submitted, show submission details instead
    if (assignment.isSubmitted) {
      return _buildSubmissionDetailsView(assignment);
    }

    final dummyHowToSteps = [
      "Read the assignment description carefully.",
      "Complete the assignment according to the instructions.",
      "Submit your work before the due date.",
    ];
    final dummyGuideSteps = [
      {
        "title": "1. Understand the Task",
        "description": "Make sure you understand what is required."
      },
      {
        "title": "2. Complete the Work",
        "description": "Work through the assignment systematically."
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: _goBackToList,
        ),
        title: const Text('Assignment Details',
            style:
            TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${assignment.subject}: ${assignment.title}',
                style:
                const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Due: ${assignment.dueDate}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(Icons.score, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Max Marks: ${assignment.maxMarks}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(description,
                style: TextStyle(color: Colors.grey[700], height: 1.5)),
            const SizedBox(height: 24),
            const Text('How to do it',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...List.generate(
                dummyHowToSteps.length,
                    (index) => _buildStepRow(
                    (index + 1).toString(), dummyHowToSteps[index])),
            const SizedBox(height: 24),
            const Text('Step-by-step Guide',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...dummyGuideSteps.map((step) =>
                _buildGuideCard(step['title']!, step['description']!)),

            if (hasMcqs && questionsToDisplay.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('MCQ Questions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: questionsToDisplay.length,
                itemBuilder: (context, index) {
                  return _buildMcqCard(questionsToDisplay[index], index);
                },
                separatorBuilder: (context, index) =>
                const SizedBox(height: 16),
              ),
            ],

            if (!hasMcqs) ...[
              const SizedBox(height: 24),
              const Text('Your Solution',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              // ✅ FIXED: Added onChanged to trigger setState
              TextField(
                controller: _solutionTextController,
                maxLines: 6,
                onChanged: (value) {
                  // ✅ Trigger rebuild when text changes
                  setState(() {
                    print('📝 DEBUG: Text changed, length: ${value.length}');
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Enter your solution here... (Optional if attaching files)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Attachments (Optional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_uploadedFiles.isEmpty)
                Text('No files added. You can optionally attach files using buttons below.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14))
              else
                ..._uploadedFiles.map((file) {
                  final fileName = file.path.split('/').last;
                  return _buildSubmissionTile(fileName, Icons.image);
                }),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar:
      _buildSubmissionFooter(assignment, questionsToDisplay),
    );
  }


  // ✅ NEW: Submission Details View (shown after submission)
  Widget _buildSubmissionDetailsView(Assignment assignment) {
    final submission = assignment.submissions.isNotEmpty
        ? assignment.submissions.first
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: _goBackToList,
        ),
        title: const Text('Submission Details',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assignment Info
            Text('${assignment.subject}: ${assignment.title}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Submission Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: assignment.isGraded
                    ? Colors.green.shade50
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: assignment.isGraded
                      ? Colors.green.shade200
                      : Colors.blue.shade200,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    assignment.isGraded
                        ? Icons.check_circle
                        : Icons.pending_actions,
                    size: 64,
                    color: assignment.isGraded
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    assignment.isGraded ? 'Graded' : 'Submitted',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: assignment.isGraded
                          ? Colors.green.shade900
                          : Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (assignment.isGraded) ...[
                    Text(
                      '${assignment.obtainedMarks} / ${assignment.maxMarks}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${((assignment.obtainedMarks! / assignment.maxMarks) * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Awaiting Review',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Submitted on: ${assignment.submissionDate}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submission Details
            const Text(
              'Your Submission',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (submission != null) ...[
              // For Theory assignments
              if (assignment.type == 'Theory') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Solution Text:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        submission.solutionText.isNotEmpty
                            ? submission.solutionText
                            : 'No text provided',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      if (submission.solutionAttachments.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Attachments:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...submission.solutionAttachments.map((url) =>
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.attach_file, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      url.toString(),
                                      style: TextStyle(color: Colors.blue[700]),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // For MCQ assignments
              if (assignment.type == 'MCQ' && submission.mcqAnswers.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Answers:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...submission.mcqAnswers.entries.map((entry) =>
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Q${entry.key}',
                                      style: TextStyle(
                                        color: Colors.blue.shade900,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Answer: ${entry.value}',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 24),

            // Info message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      assignment.isGraded
                          ? 'Your assignment has been graded. Check your score above.'
                          : 'Your assignment has been submitted and is awaiting review by your teacher.',
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$number. ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
              child: Text(text, style: TextStyle(color: Colors.grey[700]))),
        ],
      ),
    );
  }

  Widget _buildGuideCard(String title, String description) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildMcqCard(McqQuestion mcqQuestion, int questionIndex) {
    final String question = mcqQuestion.questionText;
    final List<String> options = mcqQuestion.options.map((o) => o.optionText).toList();

    return Card(
      elevation: 0,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Q${questionIndex + 1}: $question',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...options.map((option) {
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: _selectedMcqAnswers[questionIndex],
                onChanged: (value) {
                  print('✅ DEBUG: MCQ Answer selected - Q${questionIndex + 1}: $value');
                  setState(() {
                    if (value != null) {
                      _selectedMcqAnswers[questionIndex] = value;
                    }
                  });
                },
                activeColor: Colors.blueAccent,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionTile(String fileName, IconData icon) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(fileName, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            print('🗑️ DEBUG: Removing file: $fileName');
            setState(() {
              _uploadedFiles
                  .removeWhere((file) => file.path.endsWith(fileName));
            });
            print('📁 DEBUG: Remaining files: ${_uploadedFiles.length}');
          },
        ),
      ),
    );
  }

  Widget _buildSubmissionFooter(
      Assignment assignment, List<McqQuestion> currentQuestions) {
    final bool hasMcqs = assignment.type == 'MCQ';
    final int totalMcqs = currentQuestions.length;
    final bool allMcqsAnswered = _selectedMcqAnswers.length == totalMcqs &&
        totalMcqs > 0;

    bool isSubmitEnabled;
    String buttonHint = '';

    if (hasMcqs) {
      isSubmitEnabled = allMcqsAnswered && !_isSubmitting;
      buttonHint = allMcqsAnswered
          ? 'All questions answered'
          : 'Please answer all ${totalMcqs} questions';
      print('🎯 DEBUG: MCQ Progress - Answered: ${_selectedMcqAnswers.length}/$totalMcqs');
    } else {
      // ✅ FIXED: Check current values
      final bool hasText = _solutionTextController.text.trim().isNotEmpty;
      final bool hasFiles = _uploadedFiles.isNotEmpty;

      isSubmitEnabled = (hasText || hasFiles) && !_isSubmitting;

      print('📁 DEBUG: ===== SUBMIT BUTTON STATE CHECK =====');
      print('📁 DEBUG: Solution text: "${_solutionTextController.text}"');
      print('📁 DEBUG: Solution text length: ${_solutionTextController.text.length}');
      print('📁 DEBUG: Has text (trimmed): $hasText');
      print('📁 DEBUG: Files count: ${_uploadedFiles.length}');
      print('📁 DEBUG: Has files: $hasFiles');
      print('📁 DEBUG: Is submitting: $_isSubmitting');
      print('📁 DEBUG: Submit enabled: $isSubmitEnabled');
      print('📁 DEBUG: =====================================');

      if (hasText && hasFiles) {
        buttonHint = 'Ready to submit with text + ${_uploadedFiles.length} file(s)';
      } else if (hasText) {
        buttonHint = 'Ready to submit with text solution';
      } else if (hasFiles) {
        buttonHint = 'Ready to submit with ${_uploadedFiles.length} file(s)';
      } else {
        buttonHint = 'Provide text solution OR attach files to submit';
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show hint text
          if (buttonHint.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSubmitEnabled
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSubmitEnabled
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSubmitEnabled ? Icons.check_circle : Icons.info_outline,
                    size: 16,
                    color: isSubmitEnabled
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      buttonHint,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSubmitEnabled
                            ? Colors.green.shade900
                            : Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isSubmitting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.upload_file, color: Colors.white),
              label: Text(
                _isSubmitting ? 'Submitting...' : 'Submit Assignment',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: isSubmitEnabled ? _submitAssignment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.grey.shade300,
                elevation: isSubmitEnabled ? 2 : 0,
              ),
            ),
          ),

          // Camera and Gallery buttons for Theory
          if (!hasMcqs) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                    onPressed: _isSubmitting ? null : () => _pickImage(ImageSource.camera),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                    onPressed: _isSubmitting ? null : () => _pickImage(ImageSource.gallery),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}