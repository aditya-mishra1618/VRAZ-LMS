// Model for Chat Message
class ChatMessage {
  final int id;
  final int ticketId;
  final String senderId;
  final String? text;
  final String? imageUrl;
  final String? voiceNoteUrl;
  final DateTime sentAt;
  final MessageSender? sender; // ✅ Made nullable

  ChatMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    this.text,
    this.imageUrl,
    this.voiceNoteUrl,
    required this.sentAt,
    this.sender, // ✅ Made nullable
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      ticketId: json['ticketId'] as int,
      senderId: json['senderId'] as String,
      text: json['text'] as String?,
      imageUrl: json['imageUrl'] as String?,
      voiceNoteUrl: json['voiceNoteUrl'] as String?,
      sentAt: DateTime.parse(json['sentAt'] as String),
      // ✅ Handle null sender gracefully
      sender: json['sender'] != null
          ? MessageSender.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get hasText => text != null && text!.isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasVoiceNote => voiceNoteUrl != null && voiceNoteUrl!.isNotEmpty;

  // ✅ Handle null sender - default to parent if sender is null
  bool get isParent => sender?.role.roleName == 'parent' || sender == null;
}

// Model for Message Sender
class MessageSender {
  final String fullName;
  final UserRole role;

  MessageSender({
    required this.fullName,
    required this.role,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      fullName: json['fullName'] as String,
      role: UserRole.fromJson(json['role'] as Map<String, dynamic>),
    );
  }
}

// Model for User Role
class UserRole {
  final int id;
  final String roleName;

  UserRole({
    required this.id,
    required this.roleName,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['id'] as int,
      roleName: json['roleName'] as String,
    );
  }
}

// Model for Chat Ticket Details
class ChatTicketDetails {
  final int id;
  final int parentId;
  final int? assignedToId;
  final String title;
  final String initialMessage;
  final String status;
  final List<ChatMessage> messages;

  ChatTicketDetails({
    required this.id,
    required this.parentId,
    this.assignedToId,
    required this.title,
    required this.initialMessage,
    required this.status,
    required this.messages,
  });

  factory ChatTicketDetails.fromJson(Map<String, dynamic> json) {
    return ChatTicketDetails(
      id: json['id'] as int,
      parentId: json['parentId'] as int,
      assignedToId: json['assignedToId'] as int?,
      title: json['title'] as String,
      initialMessage: json['initialMessage'] as String,
      status: json['status'] as String,
      messages: (json['messages'] as List)
          .map((msg) => ChatMessage.fromJson(msg as Map<String, dynamic>))
          .toList(),
    );
  }
}

// Request model for sending message
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
    final map = <String, dynamic>{};
    if (text != null) map['text'] = text;
    if (imageUrl != null) map['imageUrl'] = imageUrl;
    if (voiceNoteUrl != null) map['voiceNoteUrl'] = voiceNoteUrl;
    return map;
  }
}

// Response model for media upload
class MediaUploadResponse {
  final String url;

  MediaUploadResponse({required this.url});

  factory MediaUploadResponse.fromJson(Map<String, dynamic> json) {
    return MediaUploadResponse(
      url: json['url'] as String,
    );
  }
}