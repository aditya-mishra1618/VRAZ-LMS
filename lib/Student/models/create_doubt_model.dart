class CreateDoubtModel {
  final String teacherId;
  final int subjectId;
  final int topicId;
  final String initialQuestion;

  CreateDoubtModel({
    required this.teacherId,
    required this.subjectId,
    required this.topicId,
    required this.initialQuestion,
  });

  // Convert model to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'teacherId': teacherId,
      'subjectId': subjectId,
      'topicId': topicId,
      'initialQuestion': initialQuestion,
    };
  }

  // Create model from JSON (for response if needed)
  factory CreateDoubtModel.fromJson(Map<String, dynamic> json) {
    return CreateDoubtModel(
      teacherId: json['teacherId'] ?? '',
      subjectId: json['subjectId'] ?? 0,
      topicId: json['topicId'] ?? 0,
      initialQuestion: json['initialQuestion'] ?? '',
    );
  }

  @override
  String toString() {
    return 'CreateDoubtModel(teacherId: $teacherId, subjectId: $subjectId, topicId: $topicId, question: $initialQuestion)';
  }
}