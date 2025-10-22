// 1. DART PACKAGES
import 'dart:io';

// 2. EXTERNAL PACKAGES
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:vraz_application/Student/service/assignment_api.dart';

// 3. PROJECT FILES
// This should be the path to your central navigation drawer.
import '../student_session_manager.dart';
import 'app_drawer.dart';
import 'models/assignment_model.dart';
// Import your SessionManager

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
  });
}

class AssignmentDetails {
  final String description;
  final List<String> howToSteps;
  final List<Map<String, String>> guideSteps;
  final List<Map<String, dynamic>>? mcqQuestions;

  AssignmentDetails({
    required this.description,
    required this.howToSteps,
    required this.guideSteps,
    this.mcqQuestions,
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

  // API Service instance
  late AssignmentApiService _apiService;

  // List to store assignments from API
  List<Assignment> _assignments = [];

  // Loading and error states
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('🎬 DEBUG: AssignmentsScreen initialized');
    print('📅 DEBUG: Current Date/Time: ${DateTime.now().toUtc().toIso8601String()}');

    // Initialize API service without token (will be set from SessionManager)
    _apiService = AssignmentApiService();

    // Fetch assignments after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndFetchAssignments();
    });
  }

  /// Initialize API service with token from SessionManager and fetch assignments
  Future<void> _initializeAndFetchAssignments() async {
    print('🔧 DEBUG: Initializing API service with SessionManager');

    // Get SessionManager from Provider
    final sessionManager = Provider.of<SessionManager>(context, listen: false);

    // Check if user is logged in
    if (!sessionManager.isLoggedIn) {
      print('❌ DEBUG: User is not logged in');
      setState(() {
        _errorMessage = 'Please login to view assignments';
        _isLoading = false;
      });
      return;
    }

    // Get the auth token from SessionManager
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


    // Update API service with the token
    _apiService.updateBearerToken(authToken);

    // Fetch assignments
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
      // Call API service to fetch assignments
      final List<AssignmentResponse> apiAssignments =
      await _apiService.fetchMyAssignments();

      print('✅ DEBUG: Successfully received ${apiAssignments.length} assignments from API');
      print('⏰ DEBUG: Fetch completed at: ${DateTime.now().toUtc().toIso8601String()}');

      // Convert API response to UI Assignment model
      final List<Assignment> convertedAssignments = apiAssignments.map((apiAssignment) {
        print('🔄 DEBUG: Converting assignment ID ${apiAssignment.id}: ${apiAssignment.assignmentTemplate.title}');

        // Determine subject from title (you can modify this logic)
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

        print('📚 DEBUG: Subject identified as: $subject');

        // Determine status based on submissions
        String status = 'Pending';
        String submissionDate = '';
        String statusDetail = 'Upcoming';

        if (apiAssignment.submissions.isNotEmpty) {
          final latestSubmission = apiAssignment.submissions.first;
          print('📝 DEBUG: Latest submission status: ${latestSubmission.status}');
          print('📝 DEBUG: Marks: ${latestSubmission.marks}');

          if (latestSubmission.status == 'GRADED') {
            final marksText = latestSubmission.marks != null
                ? '${latestSubmission.marks}/${apiAssignment.maxMarks}'
                : 'Pending';
            status = 'Graded: $marksText';
            submissionDate = 'Submitted: ${_formatDate(latestSubmission.submittedAt)}';
            statusDetail = '';
          } else {
            status = 'Submitted';
            submissionDate = 'Submitted: ${_formatDate(latestSubmission.submittedAt)}';

            // Check if overdue
            final dueDateTime = DateTime.parse(apiAssignment.dueDate);
            final submittedDateTime = DateTime.parse(latestSubmission.submittedAt);
            statusDetail = submittedDateTime.isAfter(dueDateTime) ? 'Overdue' : 'On Time';
          }
        } else {
          // Check if upcoming or overdue
          final dueDateTime = DateTime.parse(apiAssignment.dueDate);
          final now = DateTime.now();
          statusDetail = now.isAfter(dueDateTime) ? 'Overdue' : 'Upcoming';
        }

        print('✅ DEBUG: Status determined - Status: $status, Detail: $statusDetail');

        // Format due date
        String dueDate = 'Due: ${_formatDate(apiAssignment.dueDate)}';

        return Assignment(
          id: apiAssignment.id,
          subject: subject,
          title: apiAssignment.assignmentTemplate.title,
          professor: 'Prof. Teacher', // API doesn't provide professor name
          status: status,
          dueDate: dueDate,
          submissionDate: submissionDate,
          statusDetail: statusDetail,
          type: apiAssignment.assignmentTemplate.type,
          maxMarks: apiAssignment.maxMarks,
          description: apiAssignment.assignmentTemplate.description,
          submissions: apiAssignment.submissions,
        );
      }).toList();

      print('✅ DEBUG: Successfully converted ${convertedAssignments.length} assignments');

      setState(() {
        _assignments = convertedAssignments;
        _isLoading = false;
      });

      print('✅ DEBUG: UI updated with assignments');

    } catch (e) {
      print('❌ DEBUG: Error fetching assignments: $e');
      print('❌ DEBUG: Error occurred at: ${DateTime.now().toUtc().toIso8601String()}');

      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });

      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  // --- Dummy assignment details (kept as fallback) ---
  final Map<String, AssignmentDetails> _assignmentDetails = {
    'Kinematics': AssignmentDetails(
      description:
      "This assignment focuses on Kinematics, the study of motion. You'll apply concepts like displacement, velocity, acceleration, and time to solve problems involving objects in motion.",
      howToSteps: [
        "Review the fundamental concepts of Kinematics.",
        "Familiarize yourself with the kinematic equations for motion.",
        "Solve the problems provided, showing all steps.",
        "Upload your complete solutions as a single PDF or image file."
      ],
      guideSteps: [
        {
          "title": "1. Identify Knowns & Unknowns",
          "description": "Read the problem carefully and list all given values."
        },
        {
          "title": "2. Choose the Right Equation",
          "description": "Select the appropriate kinematic equation."
        },
        {
          "title": "3. Solve and Verify",
          "description":
          "Check if your answer is reasonable and has the correct units."
        },
      ],
    ),
  };

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

  void _selectAssignment(Assignment assignment) {
    print('🎯 DEBUG: Assignment selected: ${assignment.title} (ID: ${assignment.id})');
    setState(() {
      _selectedAssignment = assignment;
      _uploadedFiles.clear();
      _selectedMcqAnswers.clear();
    });
  }

  void _goBackToList() {
    print('⬅️ DEBUG: Going back to assignment list');
    setState(() {
      _selectedAssignment = null;
    });
  }

  void _submitAssignment() {
    print('📤 DEBUG: ========== ASSIGNMENT SUBMISSION ==========');
    print('📤 DEBUG: Assignment Title: ${_selectedAssignment!.title}');
    print('📤 DEBUG: Assignment ID: ${_selectedAssignment!.id}');
    print('📤 DEBUG: Assignment Type: ${_selectedAssignment!.type}');
    print('📤 DEBUG: Submission Time: ${DateTime.now().toUtc().toIso8601String()}');

    final bool hasMcqs = _selectedAssignment!.type == 'MCQ';

    if (hasMcqs) {
      print('📝 DEBUG: MCQ Assignment Submission');
      print('📝 DEBUG: Total Questions: ${_selectedMcqAnswers.length}');
      print('📝 DEBUG: Selected Answers: $_selectedMcqAnswers');

      _selectedMcqAnswers.forEach((questionIndex, answer) {
        print('📝 DEBUG:   Q${questionIndex + 1}: $answer');
      });
    } else {
      print('📁 DEBUG: Theory Assignment Submission');
      print('📁 DEBUG: Total Files: ${_uploadedFiles.length}');

      for (var i = 0; i < _uploadedFiles.length; i++) {
        print('📁 DEBUG:   File ${i + 1}: ${_uploadedFiles[i].path}');
        print('📁 DEBUG:   File Size: ${_uploadedFiles[i].lengthSync()} bytes');
      }
    }

    // TODO: Implement actual API submission here
    print('⚠️ DEBUG: API submission endpoint not yet implemented');
    print('📤 DEBUG: ========================================');

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Assignment submitted successfully!'),
      backgroundColor: Colors.green,
    ));

    _goBackToList();
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
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error loading assignments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No assignments found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
    final statusColor = assignment.status.contains('Pending')
        ? Colors.orange
        : assignment.status.contains('Submitted')
        ? Colors.blue
        : Colors.green;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
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
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    assignment.status,
                    style: TextStyle(
                        color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    assignment.dueDate,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    assignment.statusDetail,
                    style: TextStyle(
                        color: assignment.statusDetail == 'Upcoming'
                            ? Colors.green
                            : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    assignment.submissionDate,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentDetailView(Assignment assignment) {
    print('🔍 DEBUG: Displaying assignment details for: ${assignment.title} (ID: ${assignment.id})');

    // Use API description or fallback to dummy data
    final details = _assignmentDetails[assignment.title] ?? AssignmentDetails(
      description: assignment.description,
      howToSteps: [
        "Read the assignment description carefully.",
        "Complete the assignment according to the instructions.",
        "Submit your work before the due date.",
      ],
      guideSteps: [
        {
          "title": "1. Understand the Task",
          "description": "Make sure you understand what is required."
        },
        {
          "title": "2. Complete the Work",
          "description": "Work through the assignment systematically."
        },
      ],
    );

    final bool hasMcqs = assignment.type == 'MCQ';
    print('📝 DEBUG: Assignment type: ${assignment.type}, Has MCQs: $hasMcqs');

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
            const SizedBox(height: 12),
            Text(details.description,
                style: TextStyle(color: Colors.grey[700], height: 1.5)),
            const SizedBox(height: 24),
            const Text('How to do it',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...List.generate(
                details.howToSteps.length,
                    (index) => _buildStepRow(
                    (index + 1).toString(), details.howToSteps[index])),
            const SizedBox(height: 24),
            const Text('Step-by-step Guide',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...details.guideSteps.map((step) =>
                _buildGuideCard(step['title']!, step['description']!)),
            if (hasMcqs && details.mcqQuestions != null) ...[
              const SizedBox(height: 24),
              const Text('MCQ Challenge',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: details.mcqQuestions!.length,
                itemBuilder: (context, index) {
                  return _buildMcqCard(details.mcqQuestions![index], index);
                },
                separatorBuilder: (context, index) =>
                const SizedBox(height: 16),
              ),
            ],
            if (!hasMcqs) ...[
              const SizedBox(height: 24),
              const Text('Your Submission',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (_uploadedFiles.isEmpty)
                const Text('No files uploaded yet.',
                    style: TextStyle(color: Colors.grey))
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
      bottomNavigationBar: _buildSubmissionFooter(details),
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

  Widget _buildMcqCard(Map<String, dynamic> mcqData, int questionIndex) {
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
              'Q${questionIndex + 1}: ${mcqData['question']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...(mcqData['options'] as List<String>).map((option) {
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

  Widget _buildSubmissionFooter(AssignmentDetails details) {
    final bool hasMcqs = _selectedAssignment!.type == 'MCQ';
    final int totalMcqs = details.mcqQuestions?.length ?? 0;
    final bool allMcqsAnswered = _selectedMcqAnswers.length == totalMcqs;

    bool isSubmitEnabled;
    if (hasMcqs) {
      isSubmitEnabled = allMcqsAnswered;
      print('🎯 DEBUG: MCQ Progress - Answered: ${_selectedMcqAnswers.length}/$totalMcqs');
    } else {
      isSubmitEnabled = _uploadedFiles.isNotEmpty;
      print('📁 DEBUG: Files uploaded: ${_uploadedFiles.length}');
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: const Text('Submit Assignment',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              onPressed: isSubmitEnabled ? _submitAssignment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ),
          if (!hasMcqs) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                    onPressed: () => _pickImage(ImageSource.camera),
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
                    onPressed: () => _pickImage(ImageSource.gallery),
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