class AttendanceRecord {
  final int id;
  final int sessionId;
  final String studentId;
  final String status;
  final AttendanceSession session;

  AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.status,
    required this.session,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? 0,
      sessionId: json['sessionId'] ?? 0,
      studentId: json['studentId']?.toString() ?? '',
      status: (json['status'] ?? 'ABSENT').toString().toUpperCase(),
      session: AttendanceSession.fromJson(json['session'] ?? {}),
    );
  }

  bool get isPresent => status == 'PRESENT';
  bool get isAbsent => status == 'ABSENT';
}

class AttendanceSession {
  final int id;
  final int batchId;
  final String teacherId;
  final int subjectId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final int? mergedLectureId;
  final AttendanceSubject subject;

  AttendanceSession({
    required this.id,
    required this.batchId,
    required this.teacherId,
    required this.subjectId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.mergedLectureId,
    required this.subject,
  });

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      id: json['id'] ?? 0,
      batchId: json['batchId'] ?? 0,
      teacherId: json['teacherId']?.toString() ?? '',
      subjectId: json['subjectId'] ?? 0,
      startTime: DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
      endTime: DateTime.parse(json['endTime'] ?? DateTime.now().toIso8601String()),
      status: (json['status'] ?? 'SCHEDULED').toString().toUpperCase(),
      mergedLectureId: json['mergedLectureId'],
      subject: AttendanceSubject.fromJson(json['subject'] ?? {}),
    );
  }

  String get subjectName => subject.name;

  String get formattedTimeRange {
    final startHour = startTime.hour > 12 ? startTime.hour - 12 : (startTime.hour == 0 ? 12 : startTime.hour);
    final startPeriod = startTime.hour >= 12 ? 'PM' : 'AM';
    final endHour = endTime.hour > 12 ? endTime.hour - 12 : (endTime.hour == 0 ? 12 : endTime.hour);
    final endPeriod = endTime.hour >= 12 ? 'PM' : 'AM';

    return '${startHour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} $startPeriod - ${endHour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')} $endPeriod';
  }
}

class AttendanceSubject {
  final String name;

  AttendanceSubject({required this.name});

  factory AttendanceSubject.fromJson(Map<String, dynamic> json) {
    return AttendanceSubject(
      name: json['name']?.toString() ?? 'Unknown Subject',
    );
  }
}