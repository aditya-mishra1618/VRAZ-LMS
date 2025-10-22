class StudentAttendanceModel {
  final String studentId;
  final String fullName;
  String status; // Stores UI state: 'P', 'A', 'L'

  StudentAttendanceModel({
    required this.studentId,
    required this.fullName,
    required this.status,
  });

  // Factory constructor to create a model from the API's JSON
  factory StudentAttendanceModel.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceModel(
      studentId: json['studentId'] ?? '',
      fullName: json['fullName'] ?? 'Unknown Student',
      // Convert API status ("PRESENT", "ABSENT", "LATE") to UI status ('P', 'A', 'L')
      status: _mapApiStatusToUi(json['status'] ?? 'ABSENT'),
    );
  }

  // Helper method to convert API status string to UI single char
  static String _mapApiStatusToUi(String apiStatus) {
    switch (apiStatus.toUpperCase()) {
      case 'PRESENT':
        return 'P';
      case 'LATE':
        return 'L';
      case ('ABSENT'):
      default:
        return 'A';
    }
  }

  // Helper method to convert UI status back to API string for submission
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

  // Method to create a JSON object for submitting to the "Mark Attendance" API
  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'fullName': fullName, // You might not need to send this back
      'status': _apiStatus, // Convert 'P' back to 'PRESENT'
    };
  }
}
