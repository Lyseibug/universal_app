/// Plain (non-freezed) models for the group chat feature -- hand-written,
/// not codegen'd, since this environment has no Dart toolchain to run
/// build_runner. Mirrors the WorkerPrompt pattern (core/models/worker_prompt.dart).

class ChatGroupSummary {
  final String name;
  final String groupName;
  final int unreadCount;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  const ChatGroupSummary({
    required this.name,
    required this.groupName,
    required this.unreadCount,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory ChatGroupSummary.fromJson(Map<String, dynamic> json) => ChatGroupSummary(
        name: json['name']?.toString() ?? '',
        groupName: json['group_name']?.toString() ?? '',
        unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
        lastMessage: json['last_message']?.toString(),
        lastMessageAt: json['last_message_at'] != null
            ? DateTime.tryParse(json['last_message_at'].toString())
            : null,
      );
}

class ChatGroupMessage {
  final String name;
  final String group;
  final String sender;
  final String senderName;
  final String message;
  final DateTime sentAt;

  const ChatGroupMessage({
    required this.name,
    required this.group,
    required this.sender,
    required this.senderName,
    required this.message,
    required this.sentAt,
  });

  factory ChatGroupMessage.fromJson(Map<String, dynamic> json) => ChatGroupMessage(
        name: json['name']?.toString() ?? '',
        group: json['group']?.toString() ?? '',
        sender: json['sender']?.toString() ?? '',
        senderName: json['sender_name']?.toString() ?? json['sender']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        sentAt: DateTime.tryParse(json['sent_at']?.toString() ?? '') ?? DateTime.now(),
      );
}
