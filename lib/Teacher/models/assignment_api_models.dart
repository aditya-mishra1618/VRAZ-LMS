import 'package:flutter/material.dart'; // For controller helper

// --- Model for GET /assignments/getTemplates ---
class ApiAssignmentTemplate {
  final int id;
  final String title;
  final String description;
  final int subjectId;
  final String type; // "Theory" or "MCQ"
  final List<ApiMcqQuestion> mcqQuestions;

  ApiAssignmentTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectId,
    required this.type,
    this.mcqQuestions = const [],
  });

  factory ApiAssignmentTemplate.fromJson(Map<String, dynamic> json) {
    var questions = <ApiMcqQuestion>[];
    if (json['mcqQuestions'] != null && json['mcqQuestions'] is List) {
      questions = (json['mcqQuestions'] as List)
          .map((q) => ApiMcqQuestion.fromJson(q))
          .toList();
    }

    return ApiAssignmentTemplate(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? '',
      subjectId: json['subjectId'] ?? 0,
      type: json['type'] ?? 'THEORY',
      mcqQuestions: questions,
    );
  }
}

// --- Model for Nested MCQ Questions ---
class ApiMcqQuestion {
  final int id;
  final String questionText;
  final List<String> options; // Simplified from {"optionText": "..."}
  final String correctOptionText; // Stores the *text* of the correct answer

  ApiMcqQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctOptionText,
  });

  factory ApiMcqQuestion.fromJson(Map<String, dynamic> json) {
    var opts = <String>[];
    if (json['options'] != null && json['options'] is List) {
      opts = (json['options'] as List)
          .map((opt) => (opt['optionText'] ?? '').toString())
          .toList();
    }

    String correctText = 'N/A';
    if (json['correctOptionId'] != null) {
      String correctId = json['correctOptionId'].toString();
      int? correctIndex = int.tryParse(correctId);
      if (correctIndex != null &&
          correctIndex > 0 &&
          correctIndex <= opts.length) {
        correctText = opts[correctIndex - 1]; // "3" -> index 2
      } else {
        if (opts.contains(correctId)) {
          correctText = correctId;
        }
      }
    }

    return ApiMcqQuestion(
      id: json['id'] ?? 0,
      questionText: json['questionText'] ?? '',
      options: opts,
      correctOptionText: correctText,
    );
  }
}

// --- Model for GET /batches/myAssigned ---
class ApiBatch {
  final int id;
  final String name;
  final String branchName;

  ApiBatch({required this.id, required this.name, required this.branchName});

  factory ApiBatch.fromJson(Map<String, dynamic> json) {
    return ApiBatch(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Batch',
      branchName: json['branch']?['name'] ?? 'Unknown Branch',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiBatch && runtimeType == other.runtimeType && id == other.id;
  @override
  int get hashCode => id.hashCode;
  @override
  String toString() => name;
}

// --- Model for Assigned Assignments ---
class ApiAssignedAssignment {
  final int id;
  final int assignmentTemplateId;
  final int batchId;
  final DateTime dueDate;
  final int maxMarks;
  final ApiAssignmentTemplate? template;
  final String title;
  final String subjectName;
  final String type;

  ApiAssignedAssignment(
      {required this.id,
      required this.assignmentTemplateId,
      required this.batchId,
      required this.dueDate,
      required this.maxMarks,
      this.template,
      this.title = 'Assignment',
      this.subjectName = 'Subject',
      this.type = 'THEORY'});

  factory ApiAssignedAssignment.fromJson(Map<String, dynamic> json) {
    final templateData = json['assignmentTemplate'];
    final template = templateData != null
        ? ApiAssignmentTemplate.fromJson(templateData)
        : null;

    return ApiAssignedAssignment(
      id: json['id'] ?? 0,
      assignmentTemplateId: json['assignmentTemplateId'] ?? 0,
      batchId: json['batchId'] ?? 0,
      dueDate: DateTime.parse(json['dueDate']).toLocal(),
      maxMarks: json['maxMarks'] ?? 0,
      template: template,
      title: template?.title ?? 'Assigned Assignment',
      subjectName: getSubjectName(template?.subjectId), // Use helper
      type: template?.type ?? (json['type'] ?? 'THEORY'),
    );
  }

  // --- FIX: Renamed to `getSubjectName` (public) ---
  static String getSubjectName(int? subjectId) {
    switch (subjectId) {
      case 1:
        return 'Chemistry';
      case 2:
        return 'Physics';
      case 3:
        return 'Mathematics';
      case 4:
        return 'Biology';
      default:
        return 'Subject';
    }
  }
}

// --- Model for GET /getSubmissions (List Item) ---
class ApiSubmissionSummary {
  final int id;
  final int batchAssignmentId;
  final String studentId;
  final String studentName;
  final DateTime submittedAt;
  final String status;
  final int? marks;

  ApiSubmissionSummary({
    required this.id,
    required this.batchAssignmentId,
    required this.studentId,
    required this.studentName,
    required this.submittedAt,
    required this.status,
    this.marks,
  });

  factory ApiSubmissionSummary.fromJson(Map<String, dynamic> json) {
    return ApiSubmissionSummary(
      id: json['id'] ?? 0,
      batchAssignmentId: json['batchAssignmentId'] ?? 0,
      studentId: json['studentId'] ?? '',
      studentName: json['student']?['fullName'] ?? 'Unknown Student',
      submittedAt: DateTime.parse(json['submittedAt']).toLocal(),
      status: json['status'] ?? 'PENDING',
      marks: json['marks'],
    );
  }
}

// --- Model for GET /getSubmissionDetail/{id} ---
class ApiSubmissionDetail {
  final int id;
  final String studentName;
  final String? studentPhotoUrl;
  final DateTime submittedAt;
  final String status;
  final int? marks;
  final String? solutionText;
  final List<String> solutionAttachments;
  final Map<String, dynamic> mcqAnswers;
  final ApiAssignedAssignment batchAssignment;

  ApiSubmissionDetail({
    required this.id,
    required this.studentName,
    this.studentPhotoUrl,
    required this.submittedAt,
    required this.status,
    this.marks,
    this.solutionText,
    required this.solutionAttachments,
    required this.mcqAnswers,
    required this.batchAssignment,
  });

  factory ApiSubmissionDetail.fromJson(Map<String, dynamic> json) {
    return ApiSubmissionDetail(
      id: json['id'] ?? 0,
      studentName: json['student']?['fullName'] ?? 'Unknown Student',
      studentPhotoUrl: json['student']?['photoUrl'],
      submittedAt: DateTime.parse(json['submittedAt']).toLocal(),
      status: json['status'] ?? 'PENDING',
      marks: json['marks'],
      solutionText: json['solutionText'],
      solutionAttachments: (json['solutionAttachments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      mcqAnswers: Map<String, dynamic>.from(json['mcqAnswers'] ?? {}),
      batchAssignment:
          ApiAssignedAssignment.fromJson(json['batchAssignment'] ?? {}),
    );
  }
}

// --- UI Helper Class (Not an API Model) ---
class McqQuestionUIData {
  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers =
      List.generate(4, (_) => TextEditingController());
  final TextEditingController correctOptionController = TextEditingController();

  void dispose() {
    questionController.dispose();
    correctOptionController.dispose();
    for (var controller in optionControllers) {
      controller.dispose();
    }
  }

  bool get isValid {
    if (questionController.text.trim().isEmpty) return false;
    if (optionControllers.any((c) => c.text.trim().isEmpty)) return false;
    if (correctOptionController.text.trim().isEmpty) return false;
    if (!optionControllers.any((c) =>
        c.text.trim().toLowerCase() ==
        correctOptionController.text.trim().toLowerCase())) return false;
    return true;
  }

  Map<String, dynamic> toJson() {
    List<Map<String, String>> optionsList =
        optionControllers.map((c) => {"optionText": c.text.trim()}).toList();
    String correctOptionText = correctOptionController.text.trim();
    // Find the 1-based index of the correct option text
    int correctIndex = optionControllers.indexWhere(
        (c) => c.text.trim().toLowerCase() == correctOptionText.toLowerCase());
    String correctOptionId = (correctIndex + 1)
        .toString(); // Convert 0-index to 1-based index string

    return {
      "questionText": questionController.text.trim(),
      "options": optionsList,
      "correctOptionId": correctOptionId
    };
  }
}
