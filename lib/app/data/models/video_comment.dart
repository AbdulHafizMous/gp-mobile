// lib/app/data/models/video_comment.dart

class VideoComment {
  final int id;
  final int videoId;
  final int userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final int likesCount;
  final bool isLiked;
  final String createdAt;
  final List<VideoComment> replies;

  const VideoComment({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    this.likesCount = 0,
    this.isLiked = false,
    required this.createdAt,
    this.replies = const [],
  });

  factory VideoComment.fromJson(Map<String, dynamic> json) {
    final repliesList = (json['replies'] as List<dynamic>? ?? [])
        .map((r) => VideoComment.fromJson(r as Map<String, dynamic>))
        .toList();

    return VideoComment(
      id: _parseInt(json['id']),
      videoId: _parseInt(json['video_id']),
      userId: _parseInt(json['user_id']),
      userName: json['user_name']?.toString() ?? 'Utilisateur',
      userAvatar: json['user_avatar']?.toString(),
      content: json['content']?.toString() ?? '',
      likesCount: _parseInt(json['likes_count']),
      isLiked: _parseBool(json['is_liked']),
      createdAt: json['created_at']?.toString() ?? '',
      replies: repliesList,
    );
  }

  VideoComment copyWith({bool? isLiked, int? likesCount}) {
    return VideoComment(
      id: id,
      videoId: videoId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      content: content,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
      replies: replies,
    );
  }

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static bool _parseBool(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) return ['1', 'true', 'yes'].contains(v.toLowerCase());
    return false;
  }
}