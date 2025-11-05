import 'dart:ui';

import 'package:intl/intl.dart';

class Grievance {
  final int id;
  final int parentId;
  final String title;
  final String description;
  final List<String> attachments;
  final String status;
  final DateTime createdAt;

  Grievance({
    required this.id,
    required this.parentId,
    required this.title,
    required this.description,
    required this.attachments,
    required this.status,
    required this.createdAt,
  });

  factory Grievance.fromJson(Map<String, dynamic> json) {
    return Grievance(
      id: json['id'] ?? 0,
      parentId: json['parentId'] ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      status: (json['status'] ?? 'OPEN').toString().toUpperCase(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'title': title,
      'description': description,
      'attachments': attachments,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Status checks
  bool get isOpen => status == 'OPEN';
  bool get isClosed => status == 'CLOSED' || status == 'RESOLVED';
  bool get isInProgress => status == 'IN_PROGRESS' || status == 'INPROGRESS';
  bool get isResolved => status == 'RESOLVED';

  // Formatted outputs
  String get formattedDate => DateFormat('dd MMM yyyy').format(createdAt);
  String get formattedDateTime => DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);

  String get displayStatus {
    switch (status) {
      case 'OPEN':
        return 'Open';
      case 'CLOSED':
        return 'Closed';
      case 'RESOLVED':
        return 'Resolved';
      case 'IN_PROGRESS':
      case 'INPROGRESS':
        return 'In Progress';
      default:
        return status;
    }
  }

  // Status colors
  Color get statusColor {
    if (isResolved || isClosed) return const Color(0xFF4CAF50); // Green
    if (isInProgress) return const Color(0xFFFF9800); // Orange
    return const Color(0xFF2196F3); // Blue for Open
  }

  Color get statusBackgroundColor {
    if (isResolved || isClosed) return const Color(0xFFE8F5E9);
    if (isInProgress) return const Color(0xFFFFF3E0);
    return const Color(0xFFE3F2FD);
  }

  @override
  String toString() {
    return 'Grievance(id: $id, title: $title, status: $status, date: $formattedDate)';
  }
}

class GrievanceSummary {
  final List<Grievance> grievances;
  final int openCount;
  final int inProgressCount;
  final int resolvedCount;
  final int totalCount;

  GrievanceSummary({
    required this.grievances,
    required this.openCount,
    required this.inProgressCount,
    required this.resolvedCount,
    required this.totalCount,
  });

  factory GrievanceSummary.fromGrievances(List<Grievance> grievances) {
    return GrievanceSummary(
      grievances: grievances,
      openCount: grievances.where((g) => g.isOpen).length,
      inProgressCount: grievances.where((g) => g.isInProgress).length,
      resolvedCount: grievances.where((g) => g.isResolved || g.isClosed).length,
      totalCount: grievances.length,
    );
  }

  List<Grievance> getOpenGrievances() {
    return grievances.where((g) => g.isOpen).toList();
  }

  List<Grievance> getInProgressGrievances() {
    return grievances.where((g) => g.isInProgress).toList();
  }

  List<Grievance> getResolvedGrievances() {
    return grievances.where((g) => g.isResolved || g.isClosed).toList();
  }

  @override
  String toString() {
    return 'GrievanceSummary(total: $totalCount, open: $openCount, inProgress: $inProgressCount, resolved: $resolvedCount)';
  }
}