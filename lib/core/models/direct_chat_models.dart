/// Plain (non-freezed) models for the 1:1 direct chat feature -- hand-written,
/// matching group_chat_models.dart's pattern (no codegen available here).

class PdtContact {
  final String email;
  final String fullName;

  const PdtContact({required this.email, required this.fullName});

  factory PdtContact.fromJson(Map<String, dynamic> json) => PdtContact(
        email: json['email']?.toString() ?? '',
        fullName: json['full_name']?.toString() ?? json['email']?.toString() ?? '',
      );
}

class DirectConversationSummary {
  final String otherUser;
  final String otherUserName;
  final int unreadCount;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  const DirectConversationSummary({
    required this.otherUser,
    required this.otherUserName,
    required this.unreadCount,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory DirectConversationSummary.fromJson(Map<String, dynamic> json) => DirectConversationSummary(
        otherUser: json['other_user']?.toString() ?? '',
        otherUserName: json['other_user_name']?.toString() ?? '',
        unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
        lastMessage: json['last_message']?.toString(),
        lastMessageAt: json['last_message_at'] != null
            ? DateTime.tryParse(json['last_message_at'].toString())
            : null,
      );
}

class DirectMessage {
  final String name;
  final String sender;
  final String recipient;
  final String senderName;
  final String message;
  final DateTime sentAt;

  const DirectMessage({
    required this.name,
    required this.sender,
    required this.recipient,
    required this.senderName,
    required this.message,
    required this.sentAt,
  });

  factory DirectMessage.fromJson(Map<String, dynamic> json) => DirectMessage(
        name: json['name']?.toString() ?? '',
        sender: json['sender']?.toString() ?? '',
        recipient: json['recipient']?.toString() ?? '',
        senderName: json['sender_name']?.toString() ?? json['sender']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? '') ?? DateTime.now(),
      );
}
