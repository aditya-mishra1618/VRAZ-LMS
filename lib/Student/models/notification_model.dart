class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool isRead;
  final String? type; // e.g., 'announcement', 'assignment', 'doubt', etc.
  final String? actionUrl; // Deep link or route to navigate

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.data,
    required this.createdAt,
    this.isRead = false,
    this.type,
    this.actionUrl,
  });

  // From JSON (from API response)
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? json['message'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image_url'],
      data: json['data'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      type: json['type'],
      actionUrl: json['actionUrl'] ?? json['action_url'],
    );
  }

  // To JSON (for local storage or API request)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'type': type,
      'actionUrl': actionUrl,
    };
  }

  // Create from Firebase RemoteMessage
  factory NotificationModel.fromRemoteMessage(
      dynamic remoteMessage, String notificationId) {
    return NotificationModel(
      id: notificationId,
      title: remoteMessage.notification?.title ?? 'New Notification',
      body: remoteMessage.notification?.body ?? '',
      imageUrl: remoteMessage.notification?.android?.imageUrl ??
          remoteMessage.notification?.apple?.imageUrl,
      data: remoteMessage.data,
      createdAt: DateTime.now(),
      isRead: false,
      type: remoteMessage.data['type'],
      actionUrl: remoteMessage.data['actionUrl'] ?? remoteMessage.data['action_url'],
    );
  }

  // CopyWith method for updating properties
  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    String? type,
    String? actionUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, body: $body, isRead: $isRead, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Response wrapper for API list response
class NotificationListResponse {
  final List<NotificationModel> notifications;
  final int total;
  final int unreadCount;
  final int currentPage;
  final int totalPages;

  NotificationListResponse({
    required this.notifications,
    required this.total,
    this.unreadCount = 0,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    var notificationsList = <NotificationModel>[];

    if (json['notifications'] != null) {
      notificationsList = (json['notifications'] as List)
          .map((item) => NotificationModel.fromJson(item))
          .toList();
    } else if (json['data'] != null) {
      notificationsList = (json['data'] as List)
          .map((item) => NotificationModel.fromJson(item))
          .toList();
    }

    return NotificationListResponse(
      notifications: notificationsList,
      total: json['total'] ?? notificationsList.length,
      unreadCount: json['unreadCount'] ?? json['unread_count'] ?? 0,
      currentPage: json['currentPage'] ?? json['current_page'] ?? 1,
      totalPages: json['totalPages'] ?? json['total_pages'] ?? 1,
    );
  }
}