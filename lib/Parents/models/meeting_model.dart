import 'dart:ui';

import 'package:intl/intl.dart';

class ParentTeacherMeeting {
  final int id;
  final int parentId;
  final String teacherId;
  final dynamic requestedTimeSlots; // Can be string or array
  final String reason;
  final String status;
  final DateTime? scheduledTime;
  final String initiatedBy;
  final Teacher teacher;

  ParentTeacherMeeting({
    required this.id,
    required this.parentId,
    required this.teacherId,
    required this.requestedTimeSlots,
    required this.reason,
    required this.status,
    this.scheduledTime,
    required this.initiatedBy,
    required this.teacher,
  });

  factory ParentTeacherMeeting.fromJson(Map<String, dynamic> json) {
    DateTime? scheduledTimeValue;
    if (json['scheduledTime'] != null) {
      scheduledTimeValue = DateTime.parse(json['scheduledTime'].toString());
    }

    return ParentTeacherMeeting(
      id: json['id'] ?? 0,
      parentId: json['parentId'] ?? 0,
      teacherId: json['teacherId']?.toString() ?? '',
      requestedTimeSlots: json['requestedTimeSlots'],
      reason: json['reason']?.toString() ?? '',
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      scheduledTime: scheduledTimeValue,
      initiatedBy: (json['initiatedBy'] ?? 'PARENT').toString().toUpperCase(),
      teacher: Teacher.fromJson(json['teacher'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'teacherId': teacherId,
      'requestedTimeSlots': requestedTimeSlots,
      'reason': reason,
      'status': status,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'initiatedBy': initiatedBy,
      'teacher': teacher.toJson(),
    };
  }

  // Status checks
  bool get isAccepted => status == 'ACCEPTED';
  bool get isPending => status == 'PENDING';
  bool get isDeclined => status == 'DECLINED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isCompleted => status == 'COMPLETED';

  // Check if meeting is upcoming
  bool get isUpcoming {
    if (!isAccepted || scheduledTime == null) return false;
    return scheduledTime!.isAfter(DateTime.now());
  }

  // Check if meeting is past
  bool get isPast {
    if (scheduledTime == null) return false;
    return scheduledTime!.isBefore(DateTime.now()) && (isAccepted || isCompleted);
  }

  // Formatted outputs
  String get formattedDate {
    if (scheduledTime == null) return 'Not scheduled';
    return DateFormat('MMM dd, yyyy').format(scheduledTime!);
  }

  String get formattedTime {
    if (scheduledTime == null) return 'Not scheduled';
    return DateFormat('hh:mm a').format(scheduledTime!);
  }

  String get formattedDateTime {
    if (scheduledTime == null) return 'Not scheduled';
    return DateFormat('MMM dd, yyyy · hh:mm a').format(scheduledTime!);
  }

  String get displayStatus {
    switch (status) {
      case 'ACCEPTED':
        return 'Accepted';
      case 'PENDING':
        return 'Pending';
      case 'DECLINED':
        return 'Declined';
      case 'CANCELLED':
        return 'Cancelled';
      case 'COMPLETED':
        return 'Completed';
      default:
        return status;
    }
  }

  // Get requested time slots as list
  List<DateTime> get requestedTimeSlotsAsList {
    if (requestedTimeSlots is List) {
      return (requestedTimeSlots as List)
          .map((slot) => DateTime.parse(slot.toString()))
          .toList();
    } else if (requestedTimeSlots is String) {
      return [DateTime.parse(requestedTimeSlots.toString())];
    }
    return [];
  }

  // Status colors
  Color get statusColor {
    if (isAccepted) return const Color(0xFF4CAF50); // Green
    if (isPending) return const Color(0xFFFF9800); // Orange
    if (isDeclined) return const Color(0xFFF44336); // Red
    if (isCancelled) return const Color(0xFF9E9E9E); // Grey
    if (isCompleted) return const Color(0xFF2196F3); // Blue
    return const Color(0xFF757575);
  }

  Color get statusBackgroundColor {
    if (isAccepted) return const Color(0xFFE8F5E9);
    if (isPending) return const Color(0xFFFFF3E0);
    if (isDeclined) return const Color(0xFFFFEBEE);
    if (isCancelled) return const Color(0xFFF5F5F5);
    if (isCompleted) return const Color(0xFFE3F2FD);
    return const Color(0xFFEEEEEE);
  }

  @override
  String toString() {
    return 'Meeting(id: $id, teacher: ${teacher.fullName}, status: $status, date: $formattedDate)';
  }
}

class Teacher {
  final String fullName;
  final String? photoUrl;

  Teacher({
    required this.fullName,
    this.photoUrl,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      fullName: json['fullName']?.toString() ?? 'Unknown Teacher',
      photoUrl: json['photoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'photoUrl': photoUrl,
    };
  }
}

class MeetingSummary {
  final List<ParentTeacherMeeting> meetings;
  final int acceptedCount;
  final int pendingCount;
  final int declinedCount;
  final int upcomingCount;
  final int pastCount;

  MeetingSummary({
    required this.meetings,
    required this.acceptedCount,
    required this.pendingCount,
    required this.declinedCount,
    required this.upcomingCount,
    required this.pastCount,
  });

  factory MeetingSummary.fromMeetings(List<ParentTeacherMeeting> meetings) {
    return MeetingSummary(
      meetings: meetings,
      acceptedCount: meetings.where((m) => m.isAccepted).length,
      pendingCount: meetings.where((m) => m.isPending).length,
      declinedCount: meetings.where((m) => m.isDeclined).length,
      upcomingCount: meetings.where((m) => m.isUpcoming).length,
      pastCount: meetings.where((m) => m.isPast).length,
    );
  }

  List<ParentTeacherMeeting> getUpcomingMeetings() {
    return meetings.where((m) => m.isUpcoming).toList()
      ..sort((a, b) => a.scheduledTime!.compareTo(b.scheduledTime!));
  }

  List<ParentTeacherMeeting> getPastMeetings() {
    return meetings.where((m) => m.isPast).toList()
      ..sort((a, b) => b.scheduledTime!.compareTo(a.scheduledTime!));
  }

  List<ParentTeacherMeeting> getPendingMeetings() {
    return meetings.where((m) => m.isPending).toList();
  }

  @override
  String toString() {
    return 'MeetingSummary(total: ${meetings.length}, accepted: $acceptedCount, pending: $pendingCount, upcoming: $upcomingCount)';
  }
}