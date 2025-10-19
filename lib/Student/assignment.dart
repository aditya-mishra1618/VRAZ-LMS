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
        subject: 'Physics',
        title: 'Rotational Motion',
        professor: 'Prof. Zeeshan Sir',
        status: 'Pending',
        dueDate: 'Due: 30 Oct 2024',
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
        title: 'Chemical Bonding',
        professor: 'Prof. Ankit Sir',
        status: 'Pending',
        dueDate: 'Due: 02 Nov 2024',
        submissionDate: '',
        statusDetail: 'Upcoming'),
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
    'Rotational Motion': AssignmentDetails(
        description:
            "This assignment delves into Rotational Motion, a key topic for JEE. It covers concepts like moment of inertia, torque, and angular momentum.",
        howToSteps: [
          "Understand the definition of moment of inertia and the parallel/perpendicular axis theorems.",
          "Apply the concept of torque (τ = Iα) to solve problems.",
          "Analyze the conservation of angular momentum in various scenarios.",
          "Answer all the provided MCQs to complete the assignment."
        ],
        guideSteps: [
          {
            "title": "1. Determine Moment of Inertia",
            "description":
                "Identify the axis of rotation and the mass distribution of the object. Use standard formulas or integration if necessary."
          },
          {
            "title": "2. Analyze Forces and Torques",
            "description":
                "Draw a free-body diagram and calculate the net torque acting on the system about the axis of rotation."
          },
        ],
        mcqQuestions: [
          {
            "question":
                "A solid sphere of mass M and radius R rolls down an inclined plane without slipping. The acceleration of its center of mass is:",
            "options": [
              "(a) g sinθ",
              "(b) (2/3) g sinθ",
              "(c) (5/7) g sinθ",
              "(d) (3/5) g sinθ"
            ],
            "answer": "(c) (5/7) g sinθ"
          },
          {
            "question":
                "A thin circular ring of mass M and radius R is rotating about its axis with a constant angular velocity ω. Two objects each of mass m are attached gently to the opposite ends of a diameter of the ring. The ring now rotates with an angular velocity of:",
            "options": [
              "(a) ωM / (M + 2m)",
              "(b) ω(M - 2m) / (M + 2m)",
              "(c) ωM / (M + m)",
              "(d) ω(M + 2m) / M"
            ],
            "answer": "(a) ωM / (M + 2m)"
          },
        ]),
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
    'Chemical Bonding': AssignmentDetails(
        description:
            "This assignment explores Chemical Bonding and Molecular Structure, a foundational chapter in Chemistry for JEE. You will apply VSEPR theory to predict molecular shapes.",
        howToSteps: [
          "Review Lewis structures and the concept of formal charge.",
          "Master the VSEPR theory to determine electron geometry and molecular geometry.",
          "Understand the concept of hybridization (sp, sp², sp³).",
          "Answer all MCQs below to complete the assignment."
        ],
        guideSteps: [
          {
            "title": "1. Draw the Lewis Structure",
            "description":
                "Determine the central atom and arrange valence electrons to satisfy the octet rule for all atoms."
          },
          {
            "title": "2. Apply VSEPR Theory",
            "description":
                "Count the number of lone pairs and bonding pairs around the central atom to predict the molecular geometry."
          },
        ],
        mcqQuestions: [
          {
            "question":
                "What is the molecular geometry of the Xenon tetrafluoride (XeF₄) molecule?",
            "options": [
              "(a) Tetrahedral",
              "(b) See-saw",
              "(c) Square planar",
              "(d) Octahedral"
            ],
            "answer": "(c) Square planar"
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
      _selectedMcqAnswers.clear();
    });
  }

  void _goBackToList() {
    setState(() {
      _selectedAssignment = null;
    });
  }

  void _submitAssignment() {
    // Simulate submission
    print('Submitting assignment: ${_selectedAssignment!.title}');

    final details = _assignmentDetails[_selectedAssignment!.title]!;
    final bool hasMcqs =
        details.mcqQuestions != null && details.mcqQuestions!.isNotEmpty;

    if (hasMcqs) {
      print('Selected MCQ Answers: $_selectedMcqAnswers');
    } else {
      for (var file in _uploadedFiles) {
        print('File path: ${file.path}');
      }
    }

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
    final details = _assignmentDetails[assignment.title]!;
    // --- FIX: Determine if the assignment has MCQs ---
    final bool hasMcqs =
        details.mcqQuestions != null && details.mcqQuestions!.isNotEmpty;

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
        // Adjust padding to account for the submission footer
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
            if (hasMcqs) ...[
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
            // --- FIX: Conditionally hide the submission section for MCQ assignments ---
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
      // --- FIX: Use the new submission footer ---
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
            setState(() {
              _uploadedFiles
                  .removeWhere((file) => file.path.endsWith(fileName));
            });
          },
        ),
      ),
    );
  }

  // --- FIX: Renamed and updated the submission footer logic ---
  Widget _buildSubmissionFooter(AssignmentDetails details) {
    final bool hasMcqs =
        details.mcqQuestions != null && details.mcqQuestions!.isNotEmpty;
    final int totalMcqs = details.mcqQuestions?.length ?? 0;
    final bool allMcqsAnswered = _selectedMcqAnswers.length == totalMcqs;

    // Determine if the submit button should be enabled
    bool isSubmitEnabled;
    if (hasMcqs) {
      // For MCQ assignments, only check if all questions are answered
      isSubmitEnabled = allMcqsAnswered;
    } else {
      // For file-upload assignments, only check if files are uploaded
      isSubmitEnabled = _uploadedFiles.isNotEmpty;
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
          // --- FIX: Conditionally hide upload buttons for MCQ assignments ---
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
