// Notification model used across the app (Student/Teacher/Admin)
//
// Place this file under lib/models/

import 'dart:convert';

class NotificationModel {
  /// Unique identifier for the notification (string to be tolerant of numeric ids)
  final String id;

  /// Visible title / heading (nullable)
  final String? title;

  /// Visible body / message (nullable)
  final String? body;

  /// Any custom data payload from the server / FCM data map
  final Map<String, dynamic> data;

  /// When the notification was created / received
  final DateTime createdAt;

  /// Local read/unread flag
  bool isRead;

  /// Optional type/category (if server provides)
  final String? type;

  NotificationModel({
    required this.id,
    this.title,
    this.body,
    required this.data,
    required this.createdAt,
    this.isRead = false,
    this.type,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Be tolerant of different server shapes
    final idVal = json['id'] ?? json['notificationId'] ?? json['_id'] ?? json['notification_id'];
    final createdAtVal = json['createdAt'] ?? json['receivedAt'] ?? json['timestamp'] ?? json['created_at'];

    DateTime parsedDate;
    if (createdAtVal == null) {
      parsedDate = DateTime.now();
    } else if (createdAtVal is int) {
      // unix timestamp in seconds or milliseconds
      parsedDate = createdAtVal > 9999999999
          ? DateTime.fromMillisecondsSinceEpoch(createdAtVal)
          : DateTime.fromMillisecondsSinceEpoch(createdAtVal * 1000);
    } else {
      parsedDate = DateTime.tryParse(createdAtVal.toString()) ?? DateTime.now();
    }

    final dataField = json['data'] ?? <String, dynamic>{};
    final Map<String, dynamic> dataMap = dataField is Map ? Map<String, dynamic>.from(dataField) : <String, dynamic>{};

    return NotificationModel(
      id: idVal?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? json['notificationTitle']?.toString(),
      body: json['body']?.toString() ?? json['message']?.toString() ?? json['notificationBody']?.toString(),
      data: dataMap,
      createdAt: parsedDate,
      isRead: json['isRead'] == true || json['read'] == true || json['is_read'] == true,
      type: json['type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'type': type,
    };
  }

  @override
  String toString() => 'NotificationModel(id: $id, title: $title, isRead: $isRead)';
}