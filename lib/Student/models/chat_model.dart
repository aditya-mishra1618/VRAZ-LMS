// Permission Model
class Permission {
  final Map<String, dynamic> permissions;

  Permission({required this.permissions});

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(permissions: json);
  }

  Map<String, dynamic> toJson() => permissions;
}

// Role Model
class Role {
  final int id;
  final String roleName;
  final Permission permissions;

  Role({
    required this.id,
    required this.roleName,
    required this.permissions,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] ?? 0,
      roleName: json['roleName'] ?? '',
      permissions: Permission.fromJson(json['permissions'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roleName': roleName,
      'permissions': permissions.toJson(),
    };
  }
}

// Sender Model
class Sender {
  final String fullName;
  final Role role;

  Sender({
    required this.fullName,
    required this.role,
  });

  factory Sender.fromJson(Map<String, dynamic> json) {
    return Sender(
      fullName: json['fullName'] ?? '',
      role: Role.fromJson(json['role'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'role': role.toJson(),
    };
  }

  bool get isStudent => role.roleName.toLowerCase() == 'student';
  bool get isTeacher => role.roleName.toLowerCase() == 'teacher';
}

// Chat Message Model
class ChatMessageModel {
  final int id;
  final int doubtId;
  final String senderId;
  final String? text;
  final String? imageUrl;
  final String? voiceNoteUrl;
  final DateTime sentAt;
  final Sender sender;

  ChatMessageModel({
    required this.id,
    required this.doubtId,
    required this.senderId,
    this.text,
    this.imageUrl,
    this.voiceNoteUrl,
    required this.sentAt,
    required this.sender,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? 0,
      doubtId: json['doubtId'] ?? 0,
      senderId: json['senderId'] ?? '',
      text: json['text'],
      imageUrl: json['imageUrl'],
      voiceNoteUrl: json['voiceNoteUrl'],
      sentAt: json['sentAt'] != null
          ? DateTime.parse(json['sentAt'])
          : DateTime.now(),
      sender: Sender.fromJson(json['sender'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doubtId': doubtId,
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'voiceNoteUrl': voiceNoteUrl,
      'sentAt': sentAt.toIso8601String(),
      'sender': sender.toJson(),
    };
  }

  // Helper methods
  bool get hasText => text != null && text!.isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasVoice => voiceNoteUrl != null && voiceNoteUrl!.isNotEmpty;

  String getMessageType() {
    if (hasText) return 'text';
    if (hasImage) return 'image';
    if (hasVoice) return 'voice';
    return 'unknown';
  }

  String getDisplayTime() {
    final now = DateTime.now();
    final difference = now.difference(sentAt);

    if (difference.inDays > 0) {
      return '${sentAt.day}/${sentAt.month}/${sentAt.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String getFormattedTime() {
    final hour = sentAt.hour > 12 ? sentAt.hour - 12 : sentAt.hour;
    final minute = sentAt.minute.toString().padLeft(2, '0');
    final period = sentAt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

// Doubt Chat Response Model
class DoubtChatModel {
  final int id;
  final String studentId;
  final String teacherId;
  final int subjectId;
  final int topicId;
  final String initialQuestion;
  final String? attachments;
  final String status;
  final List<ChatMessageModel> messages;

  DoubtChatModel({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.subjectId,
    required this.topicId,
    required this.initialQuestion,
    this.attachments,
    required this.status,
    required this.messages,
  });

  factory DoubtChatModel.fromJson(Map<String, dynamic> json) {
    return DoubtChatModel(
      id: json['id'] ?? 0,
      studentId: json['studentId'] ?? '',
      teacherId: json['teacherId'] ?? '',
      subjectId: json['subjectId'] ?? 0,
      topicId: json['topicId'] ?? 0,
      initialQuestion: json['initialQuestion'] ?? '',
      attachments: json['attachments'],
      status: json['status'] ?? 'OPEN',
      messages: (json['messages'] as List<dynamic>?)
          ?.map((msg) => ChatMessageModel.fromJson(msg))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'teacherId': teacherId,
      'subjectId': subjectId,
      'topicId': topicId,
      'initialQuestion': initialQuestion,
      'attachments': attachments,
      'status': status,
      'messages': messages.map((msg) => msg.toJson()).toList(),
    };
  }

  bool get isOpen => status.toUpperCase() == 'OPEN';
  bool get isClosed => status.toUpperCase() == 'CLOSED';
}

// Send Message Request Model
class SendMessageRequest {
  final String? text;
  final String? imageUrl;
  final String? voiceNoteUrl;

  SendMessageRequest({
    this.text,
    this.imageUrl,
    this.voiceNoteUrl,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (text != null && text!.isNotEmpty) data['text'] = text;
    if (imageUrl != null && imageUrl!.isNotEmpty) data['imageUrl'] = imageUrl;
    if (voiceNoteUrl != null && voiceNoteUrl!.isNotEmpty) {
      data['voiceNoteUrl'] = voiceNoteUrl;
    }
    return data;
  }

  // Validation
  bool isValid() {
    return (text != null && text!.isNotEmpty) ||
        (imageUrl != null && imageUrl!.isNotEmpty) ||
        (voiceNoteUrl != null && voiceNoteUrl!.isNotEmpty);
  }
}