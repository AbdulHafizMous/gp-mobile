// lib/app/data/models/chat_models.dart

// ─────────────────────────────────────────────────────────────────────────────
// CHAT CHANNEL (canal de discussion public/groupe)
// ─────────────────────────────────────────────────────────────────────────────
class ChatChannel {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int membersCount;
  final bool isJoined;
  final bool isOnline;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final List<String> tags;

  const ChatChannel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.membersCount = 0,
    this.isJoined = false,
    this.isOnline = false,
    this.lastMessage,
    this.unreadCount = 0,
    this.tags = const [],
  });

  factory ChatChannel.fromJson(Map<String, dynamic> json) {
    return ChatChannel(
      id: _i(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      membersCount: _i(json['members_count']),
      isJoined: _b(json['is_joined']),
      isOnline: _b(json['is_online']),
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'])
          : null,
      unreadCount: _i(json['unread_count']),
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((t) => t.toString())
          .toList(),
    );
  }

  ChatChannel copyWith({bool? isJoined, int? unreadCount, ChatMessage? lastMessage}) =>
      ChatChannel(
        id: id,
        name: name,
        description: description,
        imageUrl: imageUrl,
        membersCount: membersCount,
        isJoined: isJoined ?? this.isJoined,
        isOnline: isOnline,
        lastMessage: lastMessage ?? this.lastMessage,
        unreadCount: unreadCount ?? this.unreadCount,
        tags: tags,
      );

  static int _i(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
  static bool _b(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT MESSAGE
// ─────────────────────────────────────────────────────────────────────────────
class ChatMessage {
  final int id;
  final int channelId;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final DateTime sentAt;
  final bool isMe;
  final MessageType type;

  const ChatMessage({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.sentAt,
    this.isMe = false,
    this.type = MessageType.text,
  });

  String get timeLabel {
    final now = DateTime.now();
    final diff = now.difference(sentAt);
    if (diff.inDays == 0) {
      return '${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Hier';
    return '${sentAt.day}/${sentAt.month}';
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: _i(json['id']),
      channelId: _i(json['channel_id']),
      senderId: _i(json['sender_id'] ?? json['user_id']),
      senderName: json['sender_name']?.toString() ??
          json['user']?['name']?.toString() ?? 'Utilisateur',
      senderAvatar: json['sender_avatar']?.toString() ??
          json['user']?['avatar_url']?.toString(),
      content: json['content']?.toString() ?? '',
      sentAt: _d(json['sent_at'] ?? json['created_at']),
      isMe: _b(json['is_me']),
      type: MessageType.text,
    );
  }

  static int _i(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
  static bool _b(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    return false;
  }
  static DateTime _d(dynamic v) {
    if (v == null) return DateTime.now();
    try { return DateTime.parse(v.toString()); } catch (_) { return DateTime.now(); }
  }
}

enum MessageType { text, image, audio }

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE CONVERSATION (chat 1-to-1 dating)
// ─────────────────────────────────────────────────────────────────────────────
class PrivateConversation {
  final int id;
  final int otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final bool otherIsOnline;
  final ChatMessage? lastMessage;
  final int unreadCount;

  const PrivateConversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.otherIsOnline = false,
    this.lastMessage,
    this.unreadCount = 0,
  });

  factory PrivateConversation.fromJson(Map<String, dynamic> json) {
    return PrivateConversation(
      id: _i(json['id']),
      otherUserId: _i(json['other_user_id']),
      otherUserName: json['other_user_name']?.toString() ?? '',
      otherUserAvatar: json['other_user_avatar']?.toString(),
      otherIsOnline: _b(json['other_is_online']),
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'])
          : null,
      unreadCount: _i(json['unread_count']),
    );
  }

  static int _i(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
  static bool _b(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    return false;
  }
}