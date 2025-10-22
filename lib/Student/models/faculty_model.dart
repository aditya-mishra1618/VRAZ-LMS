// File: lib/Student/models/faculty_model.dart

class FacultyModel {
  final String id;
  final String fullName;
  final String photoUrl;

  FacultyModel({
    required this.id,
    required this.fullName,
    required this.photoUrl,
  });

  factory FacultyModel.fromJson(Map<String, dynamic> json) {
    return FacultyModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'photoUrl': photoUrl,
    };
  }

  // Helper method to check if faculty has photo
  bool hasPhoto() => photoUrl.isNotEmpty;

  // Helper method to get initials for avatar fallback
  String getInitials() {
    if (fullName.isEmpty) return '?';

    final names = fullName.trim().split(' ');
    if (names.length == 1) {
      return names[0][0].toUpperCase();
    }
    return (names[0][0] + names[names.length - 1][0]).toUpperCase();
  }
}