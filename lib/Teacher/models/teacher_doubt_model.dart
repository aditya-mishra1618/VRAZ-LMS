class TeacherDoubtModel {
  final int id;
  final String studentId;
  final String teacherId;
  final int subjectId;
  final int topicId;
  final String initialQuestion;
  final String? attachments;
  final String status;

  // Related objects
  final StudentInfo student;
  final TeacherInfo teacher;
  final SubjectInfo subject;
  final TopicInfo topic;

  TeacherDoubtModel({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.subjectId,
    required this.topicId,
    required this.initialQuestion,
    this.attachments,
    required this.status,
    required this.student,
    required this.teacher,
    required this.subject,
    required this.topic,
  });

  factory TeacherDoubtModel.fromJson(Map<String, dynamic> json) {
    print('Parsing doubt: $json');

    return TeacherDoubtModel(
      id: json['id'] as int,
      studentId: json['studentId'] as String,
      teacherId: json['teacherId'] as String,
      subjectId: json['subjectId'] as int,
      topicId: json['topicId'] as int,
      initialQuestion: json['initialQuestion'] as String,
      attachments: json['attachments'] as String?,
      status: json['status'] as String,
      student: StudentInfo.fromJson(json['student'] as Map<String, dynamic>),
      teacher: TeacherInfo.fromJson(json['teacher'] as Map<String, dynamic>),
      subject: SubjectInfo.fromJson(json['subject'] as Map<String, dynamic>),
      topic: TopicInfo.fromJson(json['topic'] as Map<String, dynamic>),
    );
  }

  String getRelativeTime() {
    // Since API doesn't return createdAt, we'll show generic text
    // You can update this when you get the timestamp from backend
    return 'Recently';
  }

  bool get isNew => status.toUpperCase() == 'OPEN';
  bool get isResolved => status.toUpperCase() == 'CLOSED' || status.toUpperCase() == 'RESOLVED';
  bool get isInProgress => status.toUpperCase() == 'IN_PROGRESS';

  String get displayStatus {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return 'New';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'CLOSED':
      case 'RESOLVED':
        return 'Resolved';
      default:
        return status;
    }
  }
}

class StudentInfo {
  final String fullName;

  StudentInfo({required this.fullName});

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    print('Parsing student: $json');
    return StudentInfo(
      fullName: json['fullName'] as String,
    );
  }

  String getInitials() {
    final names = fullName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}

class TeacherInfo {
  final String fullName;

  TeacherInfo({required this.fullName});

  factory TeacherInfo.fromJson(Map<String, dynamic> json) {
    return TeacherInfo(
      fullName: json['fullName'] as String,
    );
  }
}

class SubjectInfo {
  final String name;

  SubjectInfo({required this.name});

  factory SubjectInfo.fromJson(Map<String, dynamic> json) {
    print('Parsing subject: $json');
    return SubjectInfo(
      name: json['name'] as String,
    );
  }
}

class TopicInfo {
  final String name;

  TopicInfo({required this.name});

  factory TopicInfo.fromJson(Map<String, dynamic> json) {
    print('Parsing topic: $json');
    return TopicInfo(
      name: json['name'] as String,
    );
  }
}

// ========== NEW CHAT MODELS ==========

/// Represents the complete chat response with doubt info and messages
class DoubtChatResponse {
  final int id;
  final String studentId;
  final String teacherId;
  final int subjectId;
  final int topicId;
  final String initialQuestion;
  final String? attachments;
  final String status;
  final List<ChatMessage> messages;

  DoubtChatResponse({
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

  factory DoubtChatResponse.fromJson(Map<String, dynamic> json) {
    print('📥 Parsing chat response for doubt ID: ${json['id']}');

    final messagesList = json['messages'] as List<dynamic>? ?? [];
    print('📨 Messages count: ${messagesList.length}');

    return DoubtChatResponse(
      id: json['id'] as int,
      studentId: json['studentId'] as String,
      teacherId: json['teacherId'] as String,
      subjectId: json['subjectId'] as int,
      topicId: json['topicId'] as int,
      initialQuestion: json['initialQuestion'] as String,
      attachments: json['attachments'] as String?,
      status: json['status'] as String,
      messages: messagesList
          .map((msg) => ChatMessage.fromJson(msg as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Represents a single chat message
class ChatMessage {
  final int id;
  final int doubtId;
  final String senderId;
  final String? text;
  final String? imageUrl;
  final String? voiceNoteUrl;
  final DateTime sentAt;
  final MessageSender sender;

  ChatMessage({
    required this.id,
    required this.doubtId,
    required this.senderId,
    this.text,
    this.imageUrl,
    this.voiceNoteUrl,
    required this.sentAt,
    required this.sender,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      doubtId: json['doubtId'] as int,
      senderId: json['senderId'] as String,
      text: json['text'] as String?,
      imageUrl: json['imageUrl'] as String?,
      voiceNoteUrl: json['voiceNoteUrl'] as String?,
      sentAt: DateTime.parse(json['sentAt'] as String),
      sender: MessageSender.fromJson(json['sender'] as Map<String, dynamic>),
    );
  }

  /// Check if the sender is a teacher
  bool get isFromTeacher => sender.role.roleName.toLowerCase() == 'teacher';

  /// Check if the sender is a student
  bool get isFromStudent => sender.role.roleName.toLowerCase() == 'student';

  /// Get formatted time (e.g., "10:30 AM")
  String getFormattedTime() {
    final hour = sentAt.hour > 12
        ? sentAt.hour - 12
        : (sentAt.hour == 0 ? 12 : sentAt.hour);
    final minute = sentAt.minute.toString().padLeft(2, '0');
    final period = sentAt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Check if message has content
  bool get hasContent =>
      (text != null && text!.isNotEmpty) ||
          imageUrl != null ||
          voiceNoteUrl != null;
}

/// Represents the sender of a message
class MessageSender {
  final String fullName;
  final SenderRole role;

  MessageSender({
    required this.fullName,
    required this.role,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      fullName: json['fullName'] as String,
      role: SenderRole.fromJson(json['role'] as Map<String, dynamic>),
    );
  }

  String getInitials() {
    final names = fullName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}

/// Represents the role of a message sender
class SenderRole {
  final int id;
  final String roleName;

  SenderRole({
    required this.id,
    required this.roleName,
  });

  factory SenderRole.fromJson(Map<String, dynamic> json) {
    return SenderRole(
      id: json['id'] as int,
      roleName: json['roleName'] as String,
    );
  }
}