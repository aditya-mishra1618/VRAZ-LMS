import 'package:flutter/material.dart';

class TimetableEntry {
  final int id;
  final String subjectName;
  final String teacherName;
  final String startTime;
  final String endTime;
  final String dayOfWeek;
  final DateTime date;
  final String? roomNumber;
  final String? batchName;

  TimetableEntry({
    required this.id,
    required this.subjectName,
    required this.teacherName,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
    required this.date,
    this.roomNumber,
    this.batchName,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    // ✅ FIXED: Extract date from startTime ISO string
    DateTime parsedDate;
    DateTime? parsedStartTime;
    DateTime? parsedEndTime;

    if (json['startTime'] != null) {
      parsedStartTime = DateTime.tryParse(json['startTime'].toString());
    }

    if (json['endTime'] != null) {
      parsedEndTime = DateTime.tryParse(json['endTime'].toString());
    }

    // Use startTime for the date, or fall back to 'date' field or now
    if (parsedStartTime != null) {
      parsedDate = DateTime(
        parsedStartTime.year,
        parsedStartTime.month,
        parsedStartTime.day,
      );
    } else if (json['date'] != null) {
      parsedDate = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    // ✅ FIXED: Format times as HH:MM from ISO strings
    String formattedStartTime = '09:00';
    String formattedEndTime = '10:00';

    if (parsedStartTime != null) {
      formattedStartTime = _formatTime(parsedStartTime);
    } else if (json['startTime'] != null && json['startTime'].toString().contains(':')) {
      formattedStartTime = json['startTime'].toString().split('T').last.substring(0, 5);
    }

    if (parsedEndTime != null) {
      formattedEndTime = _formatTime(parsedEndTime);
    } else if (json['endTime'] != null && json['endTime'].toString().contains(':')) {
      formattedEndTime = json['endTime'].toString().split('T').last.substring(0, 5);
    }

    print('[TimetableEntry] Parsed entry: ${json['id']} - Date: $parsedDate, Time: $formattedStartTime-$formattedEndTime');

    return TimetableEntry(
      id: json['id'] ?? json['_id'] ?? 0,
      subjectName: json['subjectName'] ??
          json['subject']?['name'] ??
          json['courseName'] ??
          'Unknown Subject',
      teacherName: json['teacherName'] ??
          json['teacher']?['fullName'] ??
          json['facultyName'] ??
          'Unknown Teacher',
      startTime: formattedStartTime,
      endTime: formattedEndTime,
      dayOfWeek: json['dayOfWeek'] ?? json['day'] ?? _getDayName(parsedDate.weekday),
      date: parsedDate,
      roomNumber: json['roomNumber']?.toString() ?? json['room']?.toString(),
      batchName: json['batchName']?.toString() ?? json['batch']?['name']?.toString(),
    );
  }

  // ✅ NEW: Helper to format DateTime to HH:MM
  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectName': subjectName,
      'teacherName': teacherName,
      'startTime': startTime,
      'endTime': endTime,
      'dayOfWeek': dayOfWeek,
      'date': date.toIso8601String(),
      'roomNumber': roomNumber,
      'batchName': batchName,
    };
  }

  String get timeRange => '$startTime - $endTime';

  IconData get icon {
    final subject = subjectName.toLowerCase();
    if (subject.contains('physics')) return Icons.science_outlined;
    if (subject.contains('chemistry')) return Icons.biotech_outlined;
    if (subject.contains('math')) return Icons.calculate_outlined;
    if (subject.contains('biology')) return Icons.spa_outlined;
    if (subject.contains('doubt')) return Icons.help_outline;
    if (subject.contains('test')) return Icons.quiz_outlined;
    return Icons.book_outlined;
  }

  @override
  String toString() {
    return 'TimetableEntry(id: $id, subject: $subjectName, date: $date, time: $timeRange)';
  }
}

class WeeklyTimetable {
  final DateTime weekStart;
  final DateTime weekEnd;
  final List<TimetableEntry> entries;

  WeeklyTimetable({
    required this.weekStart,
    required this.weekEnd,
    required this.entries,
  });

  factory WeeklyTimetable.fromJson(Map<String, dynamic> json) {
    final entriesList = json['timetable'] ?? json['entries'] ?? json['data'] ?? [];

    final entries = (entriesList as List)
        .map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    return WeeklyTimetable(
      weekStart: DateTime.tryParse(json['weekStart']?.toString() ?? '') ?? DateTime.now(),
      weekEnd: DateTime.tryParse(json['weekEnd']?.toString() ?? '') ?? DateTime.now(),
      entries: entries,
    );
  }

  // Get entries for a specific date
  List<TimetableEntry> getEntriesForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);

    final filtered = entries.where((entry) {
      final entryDateOnly = DateTime(entry.date.year, entry.date.month, entry.date.day);
      return entryDateOnly.isAtSameMomentAs(dateOnly);
    }).toList();

    // Sort by start time
    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));

    print('[WeeklyTimetable] Filtering for date: $dateOnly, found ${filtered.length} entries');

    return filtered;
  }

  // Get entries grouped by day
  Map<DateTime, List<TimetableEntry>> getEntriesByDay() {
    final Map<DateTime, List<TimetableEntry>> grouped = {};

    for (var entry in entries) {
      final dateKey = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(entry);
    }

    // Sort entries within each day
    grouped.forEach((key, value) {
      value.sort((a, b) => a.startTime.compareTo(b.startTime));
    });

    return grouped;
  }

  Map<String, dynamic> toJson() {
    return {
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'entries': entries.map((e) => e.toJson()).toList(),
    };
  }
}