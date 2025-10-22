class TeacherTimetableEntry {
  final String id;
  final String type;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final Map<String, dynamic> details;

  TeacherTimetableEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.details,
  });

  factory TeacherTimetableEntry.fromJson(Map<String, dynamic> json) {
    return TeacherTimetableEntry(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      details: Map<String, dynamic>.from(json['details'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'details': details,
    };
  }
}
