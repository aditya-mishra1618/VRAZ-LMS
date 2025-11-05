class ParentProfile {
  final int id;
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String occupation;
  final String? photoUrl;

  ParentProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.occupation,
    this.photoUrl,
  });

  factory ParentProfile.fromJson(Map<String, dynamic> json) {
    return ParentProfile(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? (json['user']?['fullName'] ?? ''),
      phoneNumber: json['phoneNumber'] ?? (json['user']?['phoneNumber'] ?? ''),
      email: json['email'] ?? (json['user']?['email'] ?? ''),
      occupation: json['occupation'] ?? '',
      photoUrl: json['user']?['photoUrl'],
    );
  }
}