class Comment {
  final int id;
  final bool isAuthor;
  final String authorName;
  final int videoId;
  final String content;
  final int? parentCommentId;
  final bool liked;
  final int likeCount;

  Comment({
    required this.id,
    required this.isAuthor,
    required this.authorName,
    required this.videoId,
    required this.content,
    this.parentCommentId,
    required this.liked,
    required this.likeCount,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      isAuthor: json['is_author'],
      authorName: json['author_name'],
      videoId: json['video_id'],
      content: json['content'],
      parentCommentId: json['parent_comment_id'],
      liked: json['liked'],
      likeCount: json['like_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'is_author': isAuthor,
      'author_name': authorName,
      'video_id': videoId,
      'content': content,
      'parent_comment_id': parentCommentId,
      'liked': liked,
      'like_count': likeCount,
    };
  }
}
