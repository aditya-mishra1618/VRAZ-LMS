class Teacher {
  final String id;
  final String fullName;
  final String? photoUrl;

  Teacher({
    required this.id,
    required this.fullName,
    this.photoUrl,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'photoUrl': photoUrl,
    };
  }

  @override
  String toString() => 'Teacher(id: $id, name: $fullName)';
}