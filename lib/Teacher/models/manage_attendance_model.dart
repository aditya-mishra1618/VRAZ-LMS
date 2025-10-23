class StudentAttendanceModel {
  final String studentId;
  final String fullName;
  String status; // Stores UI state: 'P', 'A', 'L'

  StudentAttendanceModel({
    required this.studentId,
    required this.fullName,
    required this.status,
  });

  factory StudentAttendanceModel.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceModel(
      studentId: json['studentId'] ?? '',
      fullName: json['fullName'] ?? 'Unknown Student',
      status: _mapApiStatusToUi(json['status'] ?? 'ABSENT'),
    );
  }

  static String _mapApiStatusToUi(String apiStatus) {
    switch (apiStatus.toUpperCase()) {
      case 'PRESENT':
        return 'P';
      case 'LATE':
        return 'L';
      case 'ABSENT':
      default:
        return 'A';
    }
  }

  String get _apiStatus {
    switch (status) {
      case 'P':
        return 'PRESENT';
      case 'L':
        return 'LATE';
      case 'A':
      default:
        return 'ABSENT';
    }
  }

  // --- ENSURE THIS IS CORRECT ---
  // We are sending the full object back.
  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'fullName': fullName,
      'status': _apiStatus,
    };
  }
}
