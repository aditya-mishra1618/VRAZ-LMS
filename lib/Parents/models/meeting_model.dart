import 'package:intl/intl.dart';

class Meeting {
  final int id;
  final int parentId;
  final String teacherId;
  final List<DateTime> requestedTimeSlots;
  final String reason;
  final String status;
  final DateTime? scheduledTime;
  final String initiatedBy;
  final TeacherInfo teacher;

  Meeting({
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

  factory Meeting.fromJson(Map<String, dynamic> json) {
    List<DateTime> timeSlots = [];
    try {
      if (json['requestedTimeSlots'] != null) {
        final slots = json['requestedTimeSlots'];
        if (slots is List) {
          timeSlots = slots.map((slot) {
            try {
              return DateTime.parse(slot.toString());
            } catch (e) {
              return null;
            }
          }).whereType<DateTime>().toList();
        } else if (slots is String) {
          timeSlots = [DateTime.parse(slots)];
        }
      }
    } catch (e) {
      print('[Meeting] Error parsing slots: $e');
    }

    DateTime? scheduled;
    try {
      if (json['scheduledTime'] != null && json['scheduledTime'] != 'null') {
        scheduled = DateTime.tryParse(json['scheduledTime'].toString());
      }
    } catch (e) {
      print('[Meeting] Error parsing scheduled time: $e');
    }

    return Meeting(
      id: json['id'] ?? 0,
      parentId: json['parentId'] ?? 0,
      teacherId: json['teacherId']?.toString() ?? '',
      requestedTimeSlots: timeSlots,
      reason: json['reason']?.toString() ?? 'No reason provided',
      status: (json['status'] ?? 'UNKNOWN').toString().toUpperCase(),
      scheduledTime: scheduled,
      initiatedBy: (json['initiatedBy'] ?? 'UNKNOWN').toString().toUpperCase(),
      teacher: TeacherInfo.fromJson(json['teacher'] ?? {}),
    );
  }

  // ✅ FIXED: Include AWAITING_PARENT as pending
  bool get isPending => status == 'PENDING' || status == 'AWAITING_PARENT';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isScheduled => status == 'SCHEDULED';
  bool get isCompleted => status == 'COMPLETED';
  bool get isDeclined => status == 'DECLINED';
  bool get isCancelled => status == 'CANCELLED';

  bool get isAdminInitiated => initiatedBy == 'ADMIN' || initiatedBy == 'TEACHER';
  bool get isParentInitiated => initiatedBy == 'PARENT';

  bool get isUpcoming {
    if (scheduledTime != null) {
      return scheduledTime!.isAfter(DateTime.now()) && !isCompleted && !isDeclined;
    }
    if (requestedTimeSlots.isNotEmpty) {
      return requestedTimeSlots.first.isAfter(DateTime.now()) && !isCompleted && !isDeclined;
    }
    return isPending; // ✅ Pending meetings are upcoming
  }

  bool get isPast {
    if (scheduledTime != null) {
      return scheduledTime!.isBefore(DateTime.now()) || isCompleted;
    }
    if (requestedTimeSlots.isNotEmpty) {
      return requestedTimeSlots.first.isBefore(DateTime.now()) || isCompleted;
    }
    return false;
  }

  // ✅ FIXED: Display status for AWAITING_PARENT
  String get displayStatus {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'AWAITING_PARENT':
        return 'Awaiting Response';
      case 'ACCEPTED':
        return 'Accepted';
      case 'SCHEDULED':
        return 'Scheduled';
      case 'COMPLETED':
        return 'Completed';
      case 'DECLINED':
        return 'Declined';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get formattedDate {
    final dateToUse = scheduledTime ??
        (requestedTimeSlots.isNotEmpty ? requestedTimeSlots.first : DateTime.now());
    return DateFormat('MMM dd, yyyy').format(dateToUse);
  }

  String get formattedTime {
    final dateToUse = scheduledTime ??
        (requestedTimeSlots.isNotEmpty ? requestedTimeSlots.first : DateTime.now());
    return DateFormat('hh:mm a').format(dateToUse);
  }

  @override
  String toString() {
    return 'Meeting(id: $id, reason: $reason, status: $status, initiatedBy: $initiatedBy)';
  }
}

class TeacherInfo {
  final String fullName;
  final String photoUrl;

  TeacherInfo({
    required this.fullName,
    required this.photoUrl,
  });

  factory TeacherInfo.fromJson(Map<String, dynamic> json) {
    return TeacherInfo(
      fullName: json['fullName']?.toString() ?? 'Unknown Teacher',
      photoUrl: json['photoUrl']?.toString() ?? '',
    );
  }
}