// Feedback Form Assignment Model
class FeedbackFormAssignment {
  final int id;
  final int formId;
  final int batchId;
  final String startDate;
  final String endDate;
  final bool isActive;
  final FeedbackForm form;
  final bool hasSubmitted;

  FeedbackFormAssignment({
    required this.id,
    required this.formId,
    required this.batchId,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.form,
    required this.hasSubmitted,
  });

  factory FeedbackFormAssignment.fromJson(Map<String, dynamic> json) {
    return FeedbackFormAssignment(
      id: json['id'] as int,
      formId: json['formId'] as int,
      batchId: json['batchId'] as int,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      isActive: json['isActive'] as bool,
      form: FeedbackForm.fromJson(json['form'] as Map<String, dynamic>),
      hasSubmitted: json['hasSubmitted'] as bool,
    );
  }

  bool isExpired() {
    try {
      final endDateTime = DateTime.parse(endDate);
      return DateTime.now().isAfter(endDateTime);
    } catch (e) {
      return false;
    }
  }

  bool isUpcoming() {
    try {
      final startDateTime = DateTime.parse(startDate);
      return DateTime.now().isBefore(startDateTime);
    } catch (e) {
      return false;
    }
  }

  bool isAvailableNow() {
    return isActive && !isExpired() && !isUpcoming() && !hasSubmitted;
  }
}

// Feedback Form Model
class FeedbackForm {
  final int? id;
  final String title;
  final String description;
  final String formType; // "GENERAL" or "FACULTY_REVIEW"
  final List<FeedbackQuestion>? questions;

  FeedbackForm({
    this.id,
    required this.title,
    required this.description,
    required this.formType,
    this.questions,
  });

  factory FeedbackForm.fromJson(Map<String, dynamic> json) {
    return FeedbackForm(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String,
      formType: json['formType'] as String,
      questions: json['questions'] != null
          ? (json['questions'] as List)
          .map((q) => FeedbackQuestion.fromJson(q as Map<String, dynamic>))
          .toList()
          : null,
    );
  }

  bool isGeneralForm() => formType == 'GENERAL';
  bool isFacultyReview() => formType == 'FACULTY_REVIEW';
}

// Feedback Question Model
class FeedbackQuestion {
  final String text;

  FeedbackQuestion({
    required this.text,
  });

  factory FeedbackQuestion.fromJson(Map<String, dynamic> json) {
    return FeedbackQuestion(
      text: json['text'] as String,
    );
  }
}

// Feedback Form Details (with questions)
class FeedbackFormDetails {
  final int id;
  final int formId;
  final int batchId;
  final String startDate;
  final String endDate;
  final bool isActive;
  final FeedbackForm form;

  FeedbackFormDetails({
    required this.id,
    required this.formId,
    required this.batchId,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.form,
  });

  factory FeedbackFormDetails.fromJson(Map<String, dynamic> json) {
    return FeedbackFormDetails(
      id: json['id'] as int,
      formId: json['formId'] as int,
      batchId: json['batchId'] as int,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      isActive: json['isActive'] as bool,
      form: FeedbackForm.fromJson(json['form'] as Map<String, dynamic>),
    );
  }
}

// Faculty Feedback Submission Model
class FacultyFeedbackSubmission {
  final String teacherId;
  final int rating;
  final String comment;

  FacultyFeedbackSubmission({
    required this.teacherId,
    required this.rating,
    required this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'teacherId': teacherId,
      'rating': rating,
      'comment': comment,
    };
  }
}