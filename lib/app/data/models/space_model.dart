// lib/app/data/models/space_model.dart

// ─────────────────────────────────────────────────────────────────────────────
// SpaceVideo — "medias" renvoyés par /media-categories/{id}
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/rendering.dart';

class SpaceVideo {
  final int id;
  final String title;
  final String? description;
  final String thumbnail; // thumbnail_url
  final String videoUrl; // youtube_url
  final String youtubeId; // youtube_id (pour YoutubePlayerFlutter)
  final int views;
  final int likesCount;
  final int dislikesCount;
  final int commentsCount;
  final String publicationDate; // created_at brut
  final bool isPremium; // is_premium
  final double? ppvPrice; // price (nullable)
  final bool canRead; // calculé côté backend (fallback : !isPremium)
  final bool isLiked;
  final bool isDisliked;
  final bool isSaved;
  final bool isLive;
  final DateTime? liveStartsAt;
  final DateTime? liveEndsAt;
  final String? spaceName;
  final String? spaceLogoUrl;
  final String? categoryName;

  const SpaceVideo({
    required this.id,
    required this.title,
    this.description,
    required this.thumbnail,
    required this.videoUrl,
    required this.youtubeId,
    this.views = 0,
    this.likesCount = 0,
    this.dislikesCount = 0,
    this.commentsCount = 0,
    this.publicationDate = '',
    this.isPremium = false,
    this.ppvPrice,
    this.canRead = true,
    this.isLiked = false,
    this.isDisliked = false,
    this.isSaved = false,
    this.isLive = false,
    this.liveStartsAt,
    this.liveEndsAt,
    this.spaceName,
    this.spaceLogoUrl,
    this.categoryName,
  });

  /// Le live est-il actif en ce moment ?
  bool get isLiveNow {
    if (!isLive) return false;
    final now = DateTime.now();
    if (liveStartsAt != null && liveEndsAt != null) {
      return now.isAfter(liveStartsAt!) && now.isBefore(liveEndsAt!);
    }
    return isLive;
  }

  factory SpaceVideo.fromJson(Map<String, dynamic> json) {
    debugPrint("Git Json : $json");
    final ytId = json['youtube_id']?.toString() ?? '';
    final thumbnail =
        json['thumbnail_url']?.toString() ??
        (ytId.isNotEmpty
            ? 'https://img.youtube.com/vi/$ytId/hqdefault.jpg'
            : '');
    final videoUrl =
        json['youtube_url']?.toString() ??
        (ytId.isNotEmpty ? 'https://www.youtube.com/watch?v=$ytId' : '');
    final premium = _parseBool(json['is_premium'] ?? json['premium_video']);

    return SpaceVideo(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      thumbnail: thumbnail,
      videoUrl: videoUrl,
      youtubeId: ytId,
      views: _parseInt(json['views'] ?? json['views_count']),
      likesCount: _parseInt(json['likes_count']),
      dislikesCount: _parseInt(json['dislikes_count']),
      commentsCount: _parseInt(json['comments_count']),
      publicationDate: json['created_at']?.toString() ?? '',
      isPremium: premium,
      ppvPrice: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      // Si le backend ne renvoie pas encore can_read, fallback : pas premium = lisible
      canRead: json.containsKey('can_read')
          ? _parseBool(json['can_read'])
          : !premium,
      isLiked: _parseBool(json['is_liked']),
      isDisliked: _parseBool(json['is_disliked']),
      isSaved: _parseBool(json['is_saved']),
      isLive: _parseBool(json['is_live']),
      liveStartsAt: json['live_starts_at'] != null
          ? _parseDate(json['live_starts_at'])
          : null,
      liveEndsAt: json['live_ends_at'] != null
          ? _parseDate(json['live_ends_at'])
          : null,
      spaceName: json['space_name']?.toString() ?? '',
      spaceLogoUrl: json['space_logo_url']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
    );
  }

  SpaceVideo copyWith({
    bool? canRead,
    bool? isLiked,
    bool? isDisliked,
    bool? isSaved,
    int? likesCount,
    int? dislikesCount,
    int? commentsCount,
    int? views,
  }) {
    return SpaceVideo(
      id: id,
      title: title,
      description: description,
      thumbnail: thumbnail,
      videoUrl: videoUrl,
      youtubeId: youtubeId,
      views: views ?? this.views,
      likesCount: likesCount ?? this.likesCount,
      dislikesCount: dislikesCount ?? this.dislikesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      publicationDate: publicationDate,
      isPremium: isPremium,
      ppvPrice: ppvPrice,
      canRead: canRead ?? this.canRead,
      isLiked: isLiked ?? this.isLiked,
      isDisliked: isDisliked ?? this.isDisliked,
      isSaved: isSaved ?? this.isSaved,
      isLive: isLive,
      liveStartsAt: liveStartsAt,
      liveEndsAt: liveEndsAt,
      spaceName: spaceName,
      spaceLogoUrl: spaceLogoUrl,
      categoryName: categoryName,
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

  static DateTime _parseDate(dynamic v) {
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return DateTime.now();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SpaceCategory — vient de /spaces (sans médias)
// Les médias sont peuplés après via /media-categories/{id}
// ─────────────────────────────────────────────────────────────────────────────
class SpaceCategory {
  final int id;
  final String title;
  final String description;
  final List<SpaceVideo> videos; // vide au départ, chargé à la demande

  const SpaceCategory({
    required this.id,
    required this.title,
    required this.description,
    this.videos = const [],
  });

  factory SpaceCategory.fromJson(Map<String, dynamic> json) {
    return SpaceCategory(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      videos: const [],
    );
  }

  SpaceCategory copyWithVideos(List<SpaceVideo> newVideos) => SpaceCategory(
    id: id,
    title: title,
    description: description,
    videos: newVideos,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SpaceModel — vient de /spaces
// ─────────────────────────────────────────────────────────────────────────────
class SpaceModel {
  final int id;
  final String title;
  final String description;
  final String? logoUrl;
  final String? previewVideoUrl;
  final bool isActive;
  final List<SpaceCategory> categories;

  const SpaceModel({
    required this.id,
    required this.title,
    required this.description,
    this.logoUrl,
    this.previewVideoUrl,
    required this.isActive,
    this.categories = const [],
  });

  String? get displayImage => logoUrl;
  bool get hasPreviewVideo =>
      previewVideoUrl != null && previewVideoUrl!.isNotEmpty;

  factory SpaceModel.fromJson(Map<String, dynamic> json) {
    final cats = (json['categories'] as List<dynamic>? ?? [])
        .map((c) => SpaceCategory.fromJson(c as Map<String, dynamic>))
        .toList();

    return SpaceModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      logoUrl: json['logo_url']?.toString(),
      previewVideoUrl: json['video_url']?.toString(),
      isActive: json['is_active'] ?? true,
      categories: cats,
    );
  }

  /// Retourne une copie du SpaceModel avec une catégorie mise à jour (médias chargés)
  SpaceModel withUpdatedCategory(SpaceCategory updated) {
    return SpaceModel(
      id: id,
      title: title,
      description: description,
      logoUrl: logoUrl,
      previewVideoUrl: previewVideoUrl,
      isActive: isActive,
      categories: categories
          .map((c) => c.id == updated.id ? updated : c)
          .toList(),
    );
  }
}
