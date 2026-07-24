// lib/app/data/models/shop_models.dart

class ShopCategory {
  final int id;
  final String name;
  final String slug;
  final String? icon;

  const ShopCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  factory ShopCategory.fromJson(Map<String, dynamic> json) {
    return ShopCategory(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      icon: json['icon']?.toString(),
    );
  }
}

class ShopListingMedia {
  final int id;
  final String type; // 'image' | 'video'
  final String url;

  const ShopListingMedia({required this.id, required this.type, required this.url});

  factory ShopListingMedia.fromJson(Map<String, dynamic> json) {
    return ShopListingMedia(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      type: json['type']?.toString() ?? 'image',
      url: json['url']?.toString() ?? '',
    );
  }
}

class ShopSeller {
  final int id;
  final String name;
  final String? avatarUrl;

  const ShopSeller({required this.id, required this.name, this.avatarUrl});

  factory ShopSeller.fromJson(Map<String, dynamic> json) {
    return ShopSeller(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
    );
  }
}

class ShopListing {
  final int id;
  final String title;
  final String description;
  final double? price;
  final String? city;
  final String status;
  final ShopCategory? category;
  final ShopSeller? seller;
  final bool isOwnListing;
  final List<ShopListingMedia> media;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final int contactsCount;
  final bool isLiked;
  final String? createdAt;

  const ShopListing({
    required this.id,
    required this.title,
    required this.description,
    this.price,
    this.city,
    this.status = 'active',
    this.category,
    this.seller,
    this.isOwnListing = false,
    this.media = const [],
    this.viewsCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.contactsCount = 0,
    this.isLiked = false,
    this.createdAt,
  });

  String get coverImageUrl =>
      media.firstWhere(
        (m) => m.type == 'image',
        orElse: () => media.isNotEmpty ? media.first : const ShopListingMedia(id: 0, type: 'image', url: ''),
      ).url;

  factory ShopListing.fromJson(Map<String, dynamic> json) {
    return ShopListing(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: json['price'] == null ? null : double.tryParse('${json['price']}'),
      city: json['city']?.toString(),
      status: json['status']?.toString() ?? 'active',
      category: json['category'] != null && json['category']['id'] != null
          ? ShopCategory.fromJson(json['category'])
          : null,
      seller: json['seller'] != null && json['seller']['id'] != null
          ? ShopSeller.fromJson(json['seller'])
          : null,
      isOwnListing: json['is_own_listing'] == true,
      media: (json['media'] as List<dynamic>? ?? [])
          .map((e) => ShopListingMedia.fromJson(e as Map<String, dynamic>))
          .toList(),
      viewsCount: json['views_count'] is int ? json['views_count'] : int.tryParse('${json['views_count']}') ?? 0,
      likesCount: json['likes_count'] is int ? json['likes_count'] : int.tryParse('${json['likes_count']}') ?? 0,
      commentsCount: json['comments_count'] is int ? json['comments_count'] : int.tryParse('${json['comments_count']}') ?? 0,
      contactsCount: json['contacts_count'] is int ? json['contacts_count'] : int.tryParse('${json['contacts_count']}') ?? 0,
      isLiked: json['is_liked'] == true,
      createdAt: json['created_at']?.toString(),
    );
  }

  ShopListing copyWith({bool? isLiked, int? likesCount, int? commentsCount, String? status}) {
    return ShopListing(
      id: id,
      title: title,
      description: description,
      price: price,
      city: city,
      status: status ?? this.status,
      category: category,
      seller: seller,
      isOwnListing: isOwnListing,
      media: media,
      viewsCount: viewsCount,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      contactsCount: contactsCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
    );
  }
}

class ShopComment {
  final int id;
  final String content;
  final ShopSeller user;
  final String createdAt;
  final List<ShopComment> replies;

  const ShopComment({
    required this.id,
    required this.content,
    required this.user,
    required this.createdAt,
    this.replies = const [],
  });

  factory ShopComment.fromJson(Map<String, dynamic> json) {
    return ShopComment(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      content: json['content']?.toString() ?? '',
      user: ShopSeller.fromJson(json['user'] ?? {}),
      createdAt: json['created_at']?.toString() ?? '',
      replies: (json['replies'] as List<dynamic>? ?? [])
          .map((e) => ShopComment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
