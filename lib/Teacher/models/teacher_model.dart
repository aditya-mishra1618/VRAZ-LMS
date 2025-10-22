class TeacherModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final Map<String, dynamic> permissions;
  final String? admissionId;

  TeacherModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.permissions,
    this.admissionId,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      role: json['role'],
      permissions: json['permissions'] ?? {},
      admissionId: json['admissionId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'permissions': permissions,
      'admissionId': admissionId,
    };
  }
}
