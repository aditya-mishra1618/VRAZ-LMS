class TimetableModel {
  final int id;
  final int batchId;
  final String teacherId;
  final int subjectId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String teacherName;
  final String subjectName;

  TimetableModel({
    required this.id,
    required this.batchId,
    required this.teacherId,
    required this.subjectId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.teacherName,
    required this.subjectName,
  });

  factory TimetableModel.fromJson(Map<String, dynamic> json) {
    return TimetableModel(
      id: json['id'] ?? 0,
      batchId: json['batchId'] ?? 0,
      teacherId: json['teacherId'] ?? '',
      subjectId: json['subjectId'] ?? 0,
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: json['status'] ?? '',
      teacherName: json['teacher']?['fullName'] ?? 'Unknown',
      subjectName: json['subject']?['name'] ?? 'Unknown',
    );
  }
}
