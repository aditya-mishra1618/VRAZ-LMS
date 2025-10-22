class TeacherModel {
  final String fullName;

  TeacherModel({required this.fullName});

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    print('Parsing teacher: $json'); // Debug
    return TeacherModel(fullName: json['fullName'] ?? '');
  }
}

class SubjectModel {
  final String name;

  SubjectModel({required this.name});

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    print('Parsing subject: $json'); // Debug
    return SubjectModel(name: json['name'] ?? '');
  }
}

class TopicModel {
  final String name;

  TopicModel({required this.name});

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    print('Parsing topic: $json'); // Debug
    return TopicModel(name: json['name'] ?? '');
  }
}

class GetAllDoubtModel {
  final int id;
  final String status;
  final String initialQuestion;
  final TeacherModel teacher;
  final SubjectModel subject;
  final TopicModel topic;
  final DateTime createdAt; // NEW FIELD

  GetAllDoubtModel({
    required this.id,
    required this.status,
    required this.initialQuestion,
    required this.teacher,
    required this.subject,
    required this.topic,
    required this.createdAt, // NEW FIELD
  });

  factory GetAllDoubtModel.fromJson(Map<String, dynamic> json) {
    print('Parsing doubt: $json'); // Debug
    return GetAllDoubtModel(
      id: json['id'],
      status: json['status'] ?? 'OPEN',
      initialQuestion: json['initialQuestion'] ?? '',
      teacher: TeacherModel.fromJson(json['teacher'] ?? {}),
      subject: SubjectModel.fromJson(json['subject'] ?? {}),
      topic: TopicModel.fromJson(json['topic'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']), // NEW FIELD PARSING
    );
  }

  // Helper method to get relative time
  String getRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  // Helper method to get formatted date
  String getFormattedDate() {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }
}