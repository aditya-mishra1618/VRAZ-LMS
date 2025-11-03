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
    // Parse date
    DateTime parsedDate;
    if (json['date'] != null) {
      parsedDate = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

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
      startTime: json['startTime'] ?? json['start_time'] ?? '09:00',
      endTime: json['endTime'] ?? json['end_time'] ?? '10:00',
      dayOfWeek: json['dayOfWeek'] ?? json['day'] ?? _getDayName(parsedDate.weekday),
      date: parsedDate,
      roomNumber: json['roomNumber']?.toString() ?? json['room']?.toString(),
      batchName: json['batchName']?.toString() ?? json['batch']?['name']?.toString(),
    );
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
    return 'TimetableEntry(id: $id, subject: $subjectName, date: $date)';
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
    return entries.where((entry) {
      return entry.date.year == date.year &&
          entry.date.month == date.month &&
          entry.date.day == date.day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
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