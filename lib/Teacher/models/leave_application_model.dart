import 'package:intl/intl.dart';

class LeaveApplication {
  final int id; // API uses int
  final String staffUserId;
  final String leaveType; // API uses "SICK", "CASUAL"
  final String reason;
  final DateTime startDate; // Changed from fromDate
  final DateTime endDate; // Changed from toDate
  String status; // API uses "PENDING", "APPROVED", "REJECTED"
  final String deductedAs;

  LeaveApplication({
    required this.id,
    required this.staffUserId,
    required this.leaveType,
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.deductedAs,
  });

  // Factory constructor to create LeaveApplication from API JSON
  factory LeaveApplication.fromJson(Map<String, dynamic> json) {
    try {
      return LeaveApplication(
        id: json['id'] ?? 0,
        staffUserId: json['staffUserId'] ?? '',
        leaveType: json['leaveType'] ?? 'UNKNOWN',
        reason: json['reason'] ?? 'No reason provided',
        // Parse dates safely, providing a default if parsing fails
        startDate: _parseDate(json['startDate']),
        endDate: _parseDate(json['endDate']),
        status: json['status'] ?? 'UNKNOWN',
        deductedAs: json['deductedAs'] ?? '',
      );
    } catch (e) {
      print("Error parsing LeaveApplication JSON: $e");
      print("Problematic JSON: $json");
      // Return a default or throw a more specific error
      throw FormatException("Failed to parse LeaveApplication from JSON: $e");
    }
  }

  // Helper function for safe date parsing
  static DateTime _parseDate(String? dateString) {
    if (dateString == null) {
      print("Warning: Received null date string, using current date.");
      return DateTime.now();
    }
    try {
      // Parse the ISO 8601 string and convert it immediately to local time zone
      return DateTime.parse(dateString).toLocal();
    } catch (e) {
      print(
          "Error parsing date '$dateString': $e. Using current date as fallback.");
      return DateTime.now();
    }
  }

  // Helper to get display-friendly leave type
  String get displayLeaveType {
    switch (leaveType) {
      case 'SICK':
        return 'Sick Leave';
      case 'CASUAL':
        return 'Casual Leave';
      default:
        return leaveType; // Show raw value if unknown
    }
  }

  // Helper to get display-friendly status
  String get displayStatus {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      default:
        return status; // Show raw value if unknown
    }
  }

  // Helper to format date range for display
  String get dateRangeDisplay {
    final DateFormat formatter = DateFormat('MMM dd, yyyy');
    // Check if start and end dates are the same day
    if (startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {
      return formatter.format(startDate); // Show single date
    }
    // Ensure start date is not after end date before formatting range
    if (startDate.isAfter(endDate)) {
      return formatter.format(startDate); // Or show an error/indicator
    }
    return '${formatter.format(startDate)} - ${formatter.format(endDate)}';
  }
}
