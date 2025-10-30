// ParentChild model used by parent/children listings

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

  @override
  String toString() {
    return 'ParentChild(id: $id, name: $fullName)';
  }
}