// assignment_model.dart
// This file contains all the model classes to parse the API response

class AssignmentResponse {
  final int id;
  final int assignmentTemplateId;
  final int batchId;
  final String dueDate;
  final int maxMarks;
  final AssignmentTemplate assignmentTemplate;
  final List<Submission> submissions;

  AssignmentResponse({
    required this.id,
    required this.assignmentTemplateId,
    required this.batchId,
    required this.dueDate,
    required this.maxMarks,
    required this.assignmentTemplate,
    required this.submissions,
  });

  // Factory constructor to create AssignmentResponse from JSON
  factory AssignmentResponse.fromJson(Map<String, dynamic> json) {
    print('🔄 DEBUG: Parsing AssignmentResponse with id: ${json['id']}');

    try {
      return AssignmentResponse(
        id: json['id'] ?? 0,
        assignmentTemplateId: json['assignmentTemplateId'] ?? 0,
        batchId: json['batchId'] ?? 0,
        dueDate: json['dueDate'] ?? '',
        maxMarks: json['maxMarks'] ?? 0,
        assignmentTemplate: AssignmentTemplate.fromJson(
          json['assignmentTemplate'] ?? {},
        ),
        submissions: (json['submissions'] as List<dynamic>?)
            ?.map((e) => Submission.fromJson(e as Map<String, dynamic>))
            .toList() ??
            [],
      );
    } catch (e) {
      print('❌ DEBUG: Error parsing AssignmentResponse: $e');
      rethrow;
    }
  }

  // Convert AssignmentResponse to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignmentTemplateId': assignmentTemplateId,
      'batchId': batchId,
      'dueDate': dueDate,
      'maxMarks': maxMarks,
      'assignmentTemplate': assignmentTemplate.toJson(),
      'submissions': submissions.map((e) => e.toJson()).toList(),
    };
  }
}

class AssignmentTemplate {
  final String title;
  final String description;
  final String type; // "MCQ" or "Theory"

  AssignmentTemplate({
    required this.title,
    required this.description,
    required this.type,
  });

  factory AssignmentTemplate.fromJson(Map<String, dynamic> json) {
    print('🔄 DEBUG: Parsing AssignmentTemplate: ${json['title']}');

    return AssignmentTemplate(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': type,
    };
  }
}

class Submission {
  final int id;
  final int batchAssignmentId;
  final String studentId;
  final String submittedAt;
  final String solutionText;
  final List<dynamic> solutionAttachments;
  final Map<String, dynamic> mcqAnswers;
  final int? marks;
  final String status; // "GRADED", "PENDING", etc.

  Submission({
    required this.id,
    required this.batchAssignmentId,
    required this.studentId,
    required this.submittedAt,
    required this.solutionText,
    required this.solutionAttachments,
    required this.mcqAnswers,
    this.marks,
    required this.status,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    print('🔄 DEBUG: Parsing Submission with id: ${json['id']}');

    return Submission(
      id: json['id'] ?? 0,
      batchAssignmentId: json['batchAssignmentId'] ?? 0,
      studentId: json['studentId'] ?? '',
      submittedAt: json['submittedAt'] ?? '',
      solutionText: json['solutionText'] ?? '',
      solutionAttachments: json['solutionAttachments'] ?? [],
      mcqAnswers: Map<String, dynamic>.from(json['mcqAnswers'] ?? {}),
      marks: json['marks'],
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batchAssignmentId': batchAssignmentId,
      'studentId': studentId,
      'submittedAt': submittedAt,
      'solutionText': solutionText,
      'solutionAttachments': solutionAttachments,
      'mcqAnswers': mcqAnswers,
      'marks': marks,
      'status': status,
    };
  }
}