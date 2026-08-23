// lib/app/data/models/chat_models.dart

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE TYPE
// ─────────────────────────────────────────────────────────────────────────────
enum MessageType { text, image, audio, video, file }

extension MessageTypeX on MessageType {
  static MessageType fromString(String? s) {
    switch (s) {
      case 'image': return MessageType.image;
      case 'audio': return MessageType.audio;
      case 'video': return MessageType.video;
      case 'file':  return MessageType.file;
      default:      return MessageType.text;
    }
  }

  String get label {
    switch (this) {
      case MessageType.image: return '📷 Photo';
      case MessageType.audio: return '🎤 Vocal';
      case MessageType.video: return '🎬 Vidéo';
      case MessageType.file:  return '📎 Fichier';
      default:                return '';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MESSAGE STATUS
// ─────────────────────────────────────────────────────────────────────────────
enum MessageStatus { sending, sent, delivered, read, failed }

// ─────────────────────────────────────────────────────────────────────────────
// CHAT MESSAGE
// ─────────────────────────────────────────────────────────────────────────────
class ChatMessage {
  final int id;
  final int channelId;
  final int? conversationId;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final String? senderRole;
  final String content;
  final String? mediaUrl;
  final String? localFilePath;
  final String? fileName;
  final int? fileSizeBytes;
  final int? audioDurationSec;
  final DateTime sentAt;
  final bool isMe;
  final MessageType type;
  final MessageStatus status;
  final bool isPending;

  // Reply
  final int? replyToId;
  final String? replyToSenderName;
  final String? replyToContent;
  final MessageType? replyToType;

  const ChatMessage({
    required this.id,
    required this.channelId,
    this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    this.senderRole,
    required this.content,
    this.mediaUrl,
    this.localFilePath,
    this.fileName,
    this.fileSizeBytes,
    this.audioDurationSec,
    required this.sentAt,
    this.isMe = false,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.isPending = false,
    this.replyToId,
    this.replyToSenderName,
    this.replyToContent,
    this.replyToType,
  });

  bool get isAdminSender {
    if (senderRole == null) return false;
    final r = senderRole!.toLowerCase();
    return r == 'admin' || r == 'super admin' || r == 'administrator';
  }

  bool get hasReply => replyToId != null;

  String get timeLabel {
    return '${sentAt.hour.toString().padLeft(2,'0')}:${sentAt.minute.toString().padLeft(2,'0')}';
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final replyTo = json['reply_to'] as Map<String, dynamic>?;
    return ChatMessage(
      id:              _i(json['id']),
      channelId:       _i(json['channel_id'] ?? 0),
      conversationId:  json['conversation_id'] != null ? _i(json['conversation_id']) : null,
      senderId:        _i(json['sender_id'] ?? json['user_id'] ?? 0),
      senderName:      json['sender_name']?.toString() ?? json['user']?['name']?.toString() ?? 'Utilisateur',
      senderAvatar:    json['sender_avatar']?.toString() ?? json['user']?['avatar_url']?.toString(),
      senderRole:      json['sender_role']?.toString() ?? json['user']?['role']?.toString(),
      content:         json['content']?.toString() ?? '',
      mediaUrl:        json['media_url']?.toString(),
      fileName:        json['file_name']?.toString(),
      fileSizeBytes:   json['file_size'] != null ? _i(json['file_size']) : null,
      audioDurationSec:json['audio_duration'] != null ? _i(json['audio_duration']) : null,
      sentAt:          _d(json['sent_at'] ?? json['created_at']),
      isMe:            _b(json['is_me']),
      type:            MessageTypeX.fromString(json['type']?.toString()),
      status:          MessageStatus.sent,
      replyToId:       replyTo != null ? _i(replyTo['id']) : null,
      replyToSenderName: replyTo?['sender_name']?.toString(),
      replyToContent:  replyTo?['content']?.toString(),
      replyToType:     replyTo != null ? MessageTypeX.fromString(replyTo['type']?.toString()) : null,
    );
  }

  ChatMessage copyWith({
    MessageStatus? status,
    bool? isPending,
    String? mediaUrl,
    int? replyToId,
    String? replyToSenderName,
    String? replyToContent,
    MessageType? replyToType,
  }) => ChatMessage(
    id: id, channelId: channelId, conversationId: conversationId,
    senderId: senderId, senderName: senderName, senderAvatar: senderAvatar,
    senderRole: senderRole, content: content,
    mediaUrl: mediaUrl ?? this.mediaUrl,
    localFilePath: localFilePath,
    fileName: fileName, fileSizeBytes: fileSizeBytes,
    audioDurationSec: audioDurationSec, sentAt: sentAt, isMe: isMe, type: type,
    status: status ?? this.status,
    isPending: isPending ?? this.isPending,
    replyToId: replyToId ?? this.replyToId,
    replyToSenderName: replyToSenderName ?? this.replyToSenderName,
    replyToContent: replyToContent ?? this.replyToContent,
    replyToType: replyToType ?? this.replyToType,
  );

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

// ─────────────────────────────────────────────────────────────────────────────
// CHAT CHANNEL
// ─────────────────────────────────────────────────────────────────────────────
class ChatChannel {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int membersCount;
  final bool isJoined;
  final bool isMine;
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
    this.isMine = false,
    this.isOnline = false,
    this.lastMessage,
    this.unreadCount = 0,
    this.tags = const [],
  });

  factory ChatChannel.fromJson(Map<String, dynamic> json) {
    return ChatChannel(
      id:           _i(json['id']),
      name:         json['name']?.toString() ?? '',
      description:  json['description']?.toString(),
      imageUrl:     json['image_url']?.toString(),
      membersCount: _i(json['members_count']),
      isJoined:     _b(json['is_joined']),
      isMine:       _b(json['is_mine']),
      isOnline:     _b(json['is_online']),
      lastMessage:  json['last_message'] != null ? ChatMessage.fromJson(json['last_message']) : null,
      unreadCount:  _i(json['unread_count']),
      tags:         (json['tags'] as List<dynamic>? ?? []).map((t) => t.toString()).toList(),
    );
  }

  ChatChannel copyWith({bool? isJoined, int? unreadCount, ChatMessage? lastMessage, String? name, String? description}) =>
      ChatChannel(
        id: id, name: name ?? this.name, description: description ?? this.description, imageUrl: imageUrl,
        membersCount: membersCount, isJoined: isJoined ?? this.isJoined, isMine: isMine,
        isOnline: isOnline, lastMessage: lastMessage ?? this.lastMessage,
        unreadCount: unreadCount ?? this.unreadCount, tags: tags,
      );

  static int _i(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
  static bool _b(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE CONVERSATION
// ─────────────────────────────────────────────────────────────────────────────
class PrivateConversation {
  final int id;
  final int otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final bool otherIsOnline;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime? lastMessageAt;

  const PrivateConversation({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.otherIsOnline = false,
    this.lastMessage,
    this.unreadCount = 0,
    this.lastMessageAt,
  });

  factory PrivateConversation.fromJson(Map<String, dynamic> json) {
    return PrivateConversation(
      id:              _i(json['id']),
      otherUserId:     _i(json['other_user_id']),
      otherUserName:   json['other_user_name']?.toString() ?? '',
      otherUserAvatar: json['other_user_avatar']?.toString(),
      otherIsOnline:   _b(json['other_is_online']),
      lastMessage:     json['last_message'] != null ? ChatMessage.fromJson(json['last_message']) : null,
      unreadCount:     _i(json['unread_count']),
      lastMessageAt:   json['last_message_at'] != null ? DateTime.tryParse(json['last_message_at'].toString()) : null,
    );
  }

  static int _i(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
  static bool _b(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    return false;
  }
}