// Timetable and Student models used by the Timetable screen/service.

class TimetableModel {
  final String id;
  final int childId;
  final String subject;
  final String teacherName;
  final String? teacherId;
  final String startTime;
  final String endTime;
  final String day;
  final DateTime date;
  final String? roomNumber;
  final String? notes;
  final bool isActive;

  TimetableModel({
    required this.id,
    required this.childId,
    required this.subject,
    required this.teacherName,
    this.teacherId,
    required this.startTime,
    required this.endTime,
    required this.day,
    required this.date,
    this.roomNumber,
    this.notes,
    this.isActive = true,
  });

  factory TimetableModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      final raw = json['date'];
      if (raw == null) {
        parsedDate = DateTime.now();
      } else if (raw is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(raw);
      } else {
        parsedDate = DateTime.parse(raw.toString());
      }
    } catch (_) {
      parsedDate = DateTime.now();
    }

    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v == null) return 0;
      return int.tryParse(v.toString()) ?? 0;
    }

    return TimetableModel(
      id: (json['id']?.toString() ?? json['_id']?.toString() ?? ''),
      childId: parseInt(json['childId'] ?? json['child_id'] ?? json['child']),
      subject: (json['subject'] ?? json['subjectName'] ?? json['title'] ?? '').toString(),
      teacherName: (json['teacherName'] ?? json['teacher'] ?? json['faculty'] ?? '').toString(),
      teacherId: (json['teacherId']?.toString() ?? json['teacher_id']?.toString()),
      startTime: (json['startTime'] ?? json['start_time'] ?? json['from'] ?? '').toString(),
      endTime: (json['endTime'] ?? json['end_time'] ?? json['to'] ?? '').toString(),
      day: (json['day'] ?? json['dayOfWeek'] ?? '').toString(),
      date: parsedDate,
      roomNumber: (json['roomNumber'] ?? json['room'] ?? json['classRoom'])?.toString(),
      notes: (json['notes'] ?? json['description'])?.toString(),
      isActive: json['isActive'] ?? json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'subject': subject,
      'teacherName': teacherName,
      'teacherId': teacherId,
      'startTime': startTime,
      'endTime': endTime,
      'day': day,
      'date': date.toIso8601String(),
      'roomNumber': roomNumber,
      'notes': notes,
      'isActive': isActive,
    };
  }

  String get timeRange => '$startTime - $endTime';

  @override
  String toString() {
    return 'TimetableModel(subject: $subject, teacher: $teacherName, time: $timeRange, date: $date)';
  }
}

class StudentInfoModel {
  final int id;
  final String name;
  final String className;
  final String? rollNumber;
  final String? profilePicture;
  final String? email;
  final String? phone;

  StudentInfoModel({
    required this.id,
    required this.name,
    required this.className,
    this.rollNumber,
    this.profilePicture,
    this.email,
    this.phone,
  });

  factory StudentInfoModel.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['childId'] ?? json['studentId'] ?? json['child_id'] ?? json['_id'];
    int parsedId = 0;
    if (idValue is int) {
      parsedId = idValue;
    } else if (idValue != null) {
      parsedId = int.tryParse(idValue.toString()) ?? 0;
    }

    return StudentInfoModel(
      id: parsedId,
      name: (json['name'] ?? json['fullName'] ?? json['studentName'] ?? '').toString(),
      className: (json['className'] ?? json['class'] ?? json['grade'] ?? '').toString(),
      rollNumber: (json['rollNumber'] ?? json['studentId']?.toString())?.toString(),
      profilePicture: (json['profilePicture'] ?? json['avatar'] ?? json['photo'])?.toString(),
      email: (json['email'] ?? json['studentEmail'])?.toString(),
      phone: (json['phone'] ?? json['phoneNumber'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'className': className,
      'rollNumber': rollNumber,
      'profilePicture': profilePicture,
      'email': email,
      'phone': phone,
    };
  }

  @override
  String toString() {
    return 'StudentInfoModel(id: $id, name: $name, class: $className)';
  }
}

/// Optional: ParentChild model helper (if you want to pass a ParentChild instance later).
class ParentChild {
  final int id;
  final String status;
  final String fullName;
  final String? photoUrl;
  final String branchName;
  final String courseName;

  ParentChild({
    required this.id,
    required this.status,
    required this.fullName,
    this.photoUrl,
    required this.branchName,
    required this.courseName,
  });

  factory ParentChild.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['childId'] ?? json['studentId'] ?? json['_id'];
    int parsedId = 0;
    if (idValue is int) {
      parsedId = idValue;
    } else if (idValue != null) {
      parsedId = int.tryParse(idValue.toString()) ?? 0;
    }

    return ParentChild(
      id: parsedId,
      status: (json['status'] ?? json['active'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['studentUser']?['fullName'] ?? json['name'] ?? '').toString(),
      photoUrl: (json['photoUrl'] ?? json['studentUser']?['photoUrl'] ?? json['avatar'])?.toString(),
      branchName: (json['branch']?['name'] ?? json['branchName'] ?? '').toString(),
      courseName: (json['course']?['name'] ?? json['courseName'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'branchName': branchName,
      'courseName': courseName,
    };
  }
}