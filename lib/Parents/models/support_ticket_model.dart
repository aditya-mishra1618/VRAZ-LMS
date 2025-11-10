// Model for Support Ticket
class SupportTicketModel {
  final int id;
  final int parentId;
  final int? assignedToId;
  final String title;
  final String initialMessage;
  final String status;
  final dynamic assignedTo;

  SupportTicketModel({
    required this.id,
    required this.parentId,
    this.assignedToId,
    required this.title,
    required this.initialMessage,
    required this.status,
    this.assignedTo,
  });

  // Factory constructor to create from JSON
  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id'] as int,
      parentId: json['parentId'] as int,
      assignedToId: json['assignedToId'] as int?,
      title: json['title'] as String,
      initialMessage: json['initialMessage'] as String,
      status: json['status'] as String,
      assignedTo: json['assignedTo'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'assignedToId': assignedToId,
      'title': title,
      'initialMessage': initialMessage,
      'status': status,
      'assignedTo': assignedTo,
    };
  }

  // Helper method to get user-friendly status
  String get userFriendlyStatus {
    switch (status) {
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'RESOLVED':
        return 'Resolved';
      case 'PENDING':
        return 'Pending';
      case 'CLOSED':
        return 'Closed';
      default:
        return status;
    }
  }

  // Helper method to check if ticket can be chatted
  bool get canChat {
    return status != 'RESOLVED' && status != 'CLOSED';
  }
}

// Request model for creating a support ticket
class CreateSupportTicketRequest {
  final String title;
  final String initialMessage;

  CreateSupportTicketRequest({
    required this.title,
    required this.initialMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'initialMessage': initialMessage,
    };
  }
}

// API Response wrapper for better error handling
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? errorMessage;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.errorMessage,
    this.statusCode,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse(
      success: true,
      data: data,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      errorMessage: message,
      statusCode: statusCode,
    );
  }
}