import 'dart:convert';

class Permissions {
  final bool readDoubts;
  final bool writeDoubts;
  final bool readProfile;
  final bool readResults;
  final bool writeFeedback;
  final bool readTimetable;
  final bool readAttendance;
  final bool readAssignments;
  final bool writeAssignments;
  final bool readCourseContent;
  final bool readNotifications;

  Permissions({
    required this.readDoubts,
    required this.writeDoubts,
    required this.readProfile,
    required this.readResults,
    required this.writeFeedback,
    required this.readTimetable,
    required this.readAttendance,
    required this.readAssignments,
    required this.writeAssignments,
    required this.readCourseContent,
    required this.readNotifications,
  });

  factory Permissions.fromJson(Map<String, dynamic> json) {
    return Permissions(
      readDoubts: json['doubts']?['read'] ?? false,
      writeDoubts: json['doubts']?['write'] ?? false,
      readProfile: json['profile']?['read'] ?? false,
      readResults: json['results']?['read'] ?? false,
      writeFeedback: json['feedback']?['write'] ?? false,
      readTimetable: json['timetable']?['read'] ?? false,
      readAttendance: json['attendance']?['read'] ?? false,
      readAssignments: json['assignments']?['read'] ?? false,
      writeAssignments: json['assignments']?['write'] ?? false,
      readCourseContent: json['courseContent']?['read'] ?? false,
      readNotifications: json['notifications']?['read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doubts': {'read': readDoubts, 'write': writeDoubts},
      'profile': {'read': readProfile},
      'results': {'read': readResults},
      'feedback': {'write': writeFeedback},
      'timetable': {'read': readTimetable},
      'attendance': {'read': readAttendance},
      'assignments': {'read': readAssignments, 'write': writeAssignments},
      'courseContent': {'read': readCourseContent},
      'notifications': {'read': readNotifications},
    };
  }
}

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final int admissionId;
  final Permissions permissions;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.admissionId,
    required this.permissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      role: json['role'],
      admissionId: json['admissionId'],
      permissions: Permissions.fromJson(json['permissions'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'admissionId': admissionId,
      'permissions': permissions.toJson(),
    };
  }

  // Helper method to create a user from a JSON string
  static UserModel fromJsonString(String jsonString) {
    return UserModel.fromJson(json.decode(jsonString));
  }

  // Helper method to convert user to a JSON string
  String toJsonString() {
    return json.encode(toJson());
  }
}
