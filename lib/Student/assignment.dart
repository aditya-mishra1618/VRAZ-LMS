// 1. DART PACKAGES
import 'dart:io';

// 2. EXTERNAL PACKAGES
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// 3. PROJECT FILES
// This should be the path to your central navigation drawer.
import 'app_drawer.dart';

// 4. DATA MODELS
class Assignment {
  final String subject;
  final String title;
  final String professor;
  final String status;
  final String dueDate;
  final String submissionDate;
  final String statusDetail;

  Assignment({
    required this.subject,
    required this.title,
    required this.professor,
    required this.status,
    required this.dueDate,
    required this.submissionDate,
    required this.statusDetail,
  });
}

class AssignmentDetails {
  final String description;
  final List<String> howToSteps;
  final List<Map<String, String>> guideSteps;

  AssignmentDetails({
    required this.description,
    required this.howToSteps,
    required this.guideSteps,
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

  // --- Dummy Data ---
  final List<Assignment> _assignments = [
    Assignment(
        subject: 'Physics',
        title: 'Kinematics',
        professor: 'Prof. Zeeshan Sir',
        status: 'Pending',
        dueDate: 'Due: 25 Oct 2024',
        submissionDate: '',
        statusDetail: 'Upcoming'),
    Assignment(
        subject: 'Maths',
        title: 'Calculus',
        professor: 'Prof. Ramswaroop Sir',
        status: 'Submitted',
        dueDate: 'Due: 15 Oct 2024',
        submissionDate: '',
        statusDetail: 'Overdue'),
    Assignment(
        subject: 'Chemistry',
        title: 'Organic Reactions',
        professor: 'Prof. Ankit Sir',
        status: 'Graded: A+',
        dueDate: '',
        submissionDate: 'Submitted: 10 Oct 2024',
        statusDetail: ''),
  ];

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
    'Calculus': AssignmentDetails(
        description:
            "This assignment covers the fundamentals of differential calculus.",
        howToSteps: [
          "Review the definition of a limit.",
          "Practice finding derivatives using various rules.",
          "Apply derivatives to find the slope of a tangent line.",
          "Submit your work showing all intermediate steps."
        ],
        guideSteps: [
          {
            "title": "1. Understand Limits",
            "description": "Grasp the concept of approaching a value."
          },
          {
            "title": "2. Master Differentiation",
            "description": "Learn and apply the core rules of differentiation."
          },
        ]),
    'Organic Reactions': AssignmentDetails(
        description: "Explore fundamental organic reactions.",
        howToSteps: [
          "Understand the mechanisms for SN1, SN2, E1, and E2 reactions.",
          "Predict the products of common addition reactions.",
          "Draw curved-arrow mechanisms for each reaction type.",
          "Submit your completed reaction schemes."
        ],
        guideSteps: [
          {
            "title": "1. Learn the Players",
            "description":
                "Identify the nucleophile, electrophile, and leaving group."
          },
          {
            "title": "2. Follow the Electrons",
            "description":
                "Use curved arrows to show the movement of electron pairs."
          },
        ]),
  };

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _uploadedFiles.add(File(pickedFile.path));
      });
    }
  }

  void _selectAssignment(Assignment assignment) {
    setState(() {
      _selectedAssignment = assignment;
      _uploadedFiles.clear();
    });
  }

  void _goBackToList() {
    setState(() {
      _selectedAssignment = null;
    });
  }

  // --- NEW: LOGIC FOR THE SUBMIT BUTTON ---
  void _submitAssignment() {
    if (_uploadedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please upload a file before submitting.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Simulate submission
    print('Submitting assignment: ${_selectedAssignment!.title}');
    for (var file in _uploadedFiles) {
      print('File path: ${file.path}');
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Assignment submitted successfully!'),
      backgroundColor: Colors.green,
    ));

    // Go back to the assignment list
    _goBackToList();
  }

  @override
  Widget build(BuildContext context) {
    return _selectedAssignment == null
        ? _buildAssignmentListView()
        : _buildAssignmentDetailView(_selectedAssignment!);
  }

  // --- SCREEN 1: Assignment List View ---
  Widget _buildAssignmentListView() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const AppDrawer(), // Using the central drawer
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
      ),
      body: ListView.builder(
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
    // ... This widget remains unchanged ...
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

  // --- SCREEN 2: Assignment Detail View ---
  Widget _buildAssignmentDetailView(Assignment assignment) {
    final details = _assignmentDetails[assignment.title]!;
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
        padding: const EdgeInsets.fromLTRB(
            20, 20, 20, 150), // Add padding for bottom bar
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
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildUploadButtons(),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildStepRow(String number, String text) {
    // ... This widget remains unchanged ...
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
              child: Text(text, style: TextStyle(color: Colors.grey[700]))),
        ],
      ),
    );
  }

  Widget _buildGuideCard(String title, String description) {
    // ... This widget remains unchanged ...
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

  Widget _buildSubmissionTile(String fileName, IconData icon) {
    // ... This widget remains unchanged ...
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
            // Logic to remove the file
            setState(() {
              _uploadedFiles
                  .removeWhere((file) => file.path.endsWith(fileName));
            });
          },
        ),
      ),
    );
  }

  // --- UPDATED WIDGET WITH THE SUBMIT BUTTON ---
  Widget _buildUploadButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. The main "Submit" button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: const Text('Submit Assignment',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              // Disable button if no files are uploaded
              onPressed: _uploadedFiles.isEmpty ? null : _submitAssignment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 2. The secondary helper buttons
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
        ],
      ),
    );
  }
}
