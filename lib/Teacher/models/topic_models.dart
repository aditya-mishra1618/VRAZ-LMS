// lib/Teacher/models/topic_models.dart

// Represents a SubTopic
class SubTopic {
  final int id;
  final String name;
  final int? parentId; // ID of the main topic it belongs to

  SubTopic({
    required this.id,
    required this.name,
    this.parentId,
  });

  factory SubTopic.fromJson(Map<String, dynamic> json) {
    return SubTopic(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown SubTopic',
      parentId: json['parentId'],
    );
  }

  // Override equals and hashCode for comparison in Dropdowns
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubTopic && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return name; // How it appears in the dropdown
  }
}

// Represents a main Topic which can contain SubTopics
class Topic {
  final int id;
  final String name;
  final int subjectId;
  final List<SubTopic> subTopics;

  Topic({
    required this.id,
    required this.name,
    required this.subjectId,
    required this.subTopics,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    var subTopicList = <SubTopic>[];
    if (json['subTopics'] != null && json['subTopics'] is List) {
      subTopicList = (json['subTopics'] as List)
          .map((subJson) => SubTopic.fromJson(subJson as Map<String, dynamic>))
          .toList();
    }
    return Topic(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Topic',
      subjectId: json['subjectId'] ?? 0,
      subTopics: subTopicList,
    );
  }

  // Override equals and hashCode for comparison in Dropdowns
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Topic && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return name; // How it appears in the dropdown
  }
}

// Simple Subject model (if needed elsewhere)
class SubjectInfo {
  final int id;
  final String name;

  SubjectInfo({required this.id, required this.name});

  factory SubjectInfo.fromJson(Map<String, dynamic> json) {
    return SubjectInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Subject',
    );
  }
}
