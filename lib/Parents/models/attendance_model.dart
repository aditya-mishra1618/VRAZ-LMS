import 'package:intl/intl.dart';

class AttendanceRecord {
  final int id;
  final int sessionId;
  final String studentId;
  final String status;
  final DateTime sessionStartTime;
  final String subjectName;

  AttendanceRecord({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.status,
    required this.sessionStartTime,
    required this.subjectName,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final session = json['session'] ?? {};
    final subject = session['subject'] ?? {};

    DateTime startTime;
    if (session['startTime'] != null) {
      startTime = DateTime.tryParse(session['startTime'].toString()) ?? DateTime.now();
    } else {
      startTime = DateTime.now();
    }

    return AttendanceRecord(
      id: json['id'] ?? 0,
      sessionId: json['sessionId'] ?? 0,
      studentId: json['studentId']?.toString() ?? '',
      status: (json['status'] ?? 'UNKNOWN').toString().toUpperCase(),
      sessionStartTime: startTime,
      subjectName: subject['name']?.toString() ?? 'Unknown Subject',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'studentId': studentId,
      'status': status,
      'sessionStartTime': sessionStartTime.toIso8601String(),
      'subjectName': subjectName,
    };
  }

  String get formattedDate => DateFormat('MMM dd, yyyy').format(sessionStartTime);
  String get formattedTime => DateFormat('hh:mm a').format(sessionStartTime);
  String get formattedDateTime => DateFormat('MMM dd, yyyy - hh:mm a').format(sessionStartTime);

  bool get isPresent => status == 'PRESENT';
  bool get isAbsent => status == 'ABSENT';
  bool get isLate => status == 'LATE';
  bool get isLeave => status == 'LEAVE';

  String get displayStatus {
    switch (status) {
      case 'PRESENT':
        return 'Present';
      case 'ABSENT':
        return 'Absent';
      case 'LATE':
        return 'Late';
      case 'LEAVE':
        return 'Leave';
      default:
        return status;
    }
  }

  @override
  String toString() {
    return 'AttendanceRecord(id: $id, date: $formattedDate, status: $status, subject: $subjectName)';
  }
}

class AttendanceSummary {
  final List<AttendanceRecord> records;
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int leaveDays;

  AttendanceSummary({
    required this.records,
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.leaveDays,
  });

  factory AttendanceSummary.fromRecords(List<AttendanceRecord> records) {
    final presentCount = records.where((r) => r.isPresent).length;
    final absentCount = records.where((r) => r.isAbsent).length;
    final lateCount = records.where((r) => r.isLate).length;
    final leaveCount = records.where((r) => r.isLeave).length;

    return AttendanceSummary(
      records: records,
      totalDays: records.length,
      presentDays: presentCount,
      absentDays: absentCount,
      lateDays: lateCount,
      leaveDays: leaveCount,
    );
  }

  double get attendancePercentage {
    if (totalDays == 0) return 0.0;
    return (presentDays / totalDays) * 100;
  }

  String get attendancePercentageString {
    return '${attendancePercentage.toStringAsFixed(1)}%';
  }

  // Get records grouped by date
  Map<String, List<AttendanceRecord>> getRecordsByDate() {
    final Map<String, List<AttendanceRecord>> grouped = {};

    for (var record in records) {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.sessionStartTime);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(record);
    }

    return grouped;
  }

  // Get records for a specific month
  List<AttendanceRecord> getRecordsForMonth(int year, int month) {
    return records.where((record) {
      return record.sessionStartTime.year == year &&
          record.sessionStartTime.month == month;
    }).toList();
  }

  // Get weekly attendance data (last 4 weeks)
  List<double> getWeeklyPercentages() {
    final now = DateTime.now();
    final List<double> percentages = [];

    for (int i = 3; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: (7 * (i + 1))));
      final weekEnd = now.subtract(Duration(days: (7 * i)));

      final weekRecords = records.where((record) {
        return record.sessionStartTime.isAfter(weekStart) &&
            record.sessionStartTime.isBefore(weekEnd);
      }).toList();

      if (weekRecords.isEmpty) {
        percentages.add(0.0);
      } else {
        final presentCount = weekRecords.where((r) => r.isPresent).length;
        percentages.add(presentCount / weekRecords.length);
      }
    }

    return percentages;
  }

  // Get monthly attendance data (last 6 months)
  List<double> getMonthlyPercentages() {
    final now = DateTime.now();
    final List<double> percentages = [];

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthRecords = getRecordsForMonth(monthDate.year, monthDate.month);

      if (monthRecords.isEmpty) {
        percentages.add(0.0);
      } else {
        final presentCount = monthRecords.where((r) => r.isPresent).length;
        percentages.add(presentCount / monthRecords.length);
      }
    }

    return percentages;
  }

  @override
  String toString() {
    return 'AttendanceSummary(total: $totalDays, present: $presentDays, percentage: $attendancePercentageString)';
  }
}