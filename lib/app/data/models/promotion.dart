class Promotion {
  final int id;
  final String title;
  final String description;
  final String type;
  final String target;
  final int maxUsesPerUser;
  final int? totalMaxUses;
  final int usedCount;
  final String startsAt;
  final String endsAt;
  final bool isActive;
  final bool isExpired;
  final bool isAvailable;
  final String? imageUrl;
  final PromotionPartner? partner;

  // Infos du user connecté
  final int userUsageCount;
  final bool userCanClaim;
  final String? userPendingQr;
  final PromotionUsage? userPendingUsage;

  const Promotion({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    required this.maxUsesPerUser,
    this.totalMaxUses,
    required this.usedCount,
    required this.startsAt,
    required this.endsAt,
    required this.isActive,
    required this.isExpired,
    required this.isAvailable,
    this.imageUrl,
    this.partner,
    this.userUsageCount = 0,
    this.userCanClaim = false,
    this.userPendingQr,
    this.userPendingUsage,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id:              json['id'] as int,
      title:           json['title']?.toString() ?? '',
      description:     json['description']?.toString() ?? '',
      type:            json['type']?.toString() ?? 'general',
      target:          json['target']?.toString() ?? 'all',
      maxUsesPerUser:  (json['max_uses_per_user'] as num?)?.toInt() ?? 1,
      totalMaxUses:    (json['total_max_uses'] as num?)?.toInt(),
      usedCount:       (json['used_count'] as num?)?.toInt() ?? 0,
      startsAt:        json['starts_at']?.toString() ?? '',
      endsAt:          json['ends_at']?.toString() ?? '',
      isActive:        json['is_active'] == true,
      isExpired:       json['is_expired'] == true,
      isAvailable:     json['is_available'] == true,
      imageUrl:        json['image_url']?.toString(),
      partner:         json['partner'] != null
                         ? PromotionPartner.fromJson(json['partner'])
                         : null,
      userUsageCount:  (json['user_usage_count'] as num?)?.toInt() ?? 0,
      userCanClaim:    json['user_can_claim'] == true,
      userPendingQr:   json['user_pending_qr']?.toString(),
      userPendingUsage: json['user_pending_usage'] != null
                          ? PromotionUsage.fromJson(json['user_pending_usage'])
                          : null,
    );
  }

  Promotion copyWith({
    bool? userCanClaim,
    int? userUsageCount,
    String? userPendingQr,
    PromotionUsage? userPendingUsage,
  }) {
    return Promotion(
      id: id, title: title, description: description, type: type,
      target: target, maxUsesPerUser: maxUsesPerUser,
      totalMaxUses: totalMaxUses, usedCount: usedCount,
      startsAt: startsAt, endsAt: endsAt, isActive: isActive,
      isExpired: isExpired, isAvailable: isAvailable, imageUrl: imageUrl,
      partner: partner,
      userUsageCount:  userUsageCount  ?? this.userUsageCount,
      userCanClaim:    userCanClaim    ?? this.userCanClaim,
      userPendingQr:   userPendingQr   ?? this.userPendingQr,
      userPendingUsage: userPendingUsage ?? this.userPendingUsage,
    );
  }
}

class PromotionPartner {
  final int id;
  final String name;
  final String? companyName;
  final String? avatarUrl;
  final String? logoUrl;
  final String? bannerUrl;
  final String? address;
  final String? googleMapsLink;

  const PromotionPartner({
    required this.id,
    required this.name,
    this.companyName,
    this.avatarUrl,
    this.logoUrl,
    this.bannerUrl,
    this.address,
    this.googleMapsLink,
  });

  factory PromotionPartner.fromJson(Map<String, dynamic> json) {
    return PromotionPartner(
      id:        json['id'] as int,
      name:      json['name']?.toString() ?? '',
      companyName: json['company_name']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      logoUrl:   json['logo_url']?.toString(),
      bannerUrl: json['banner_url']?.toString(),
      address:   json['address']?.toString(),
      googleMapsLink: json['google_maps_link']?.toString(),
    );
  }
}

/// Fiche partenaire complète (tab "Partenaires" du Club).
class PartnerFiche {
  final int id;
  final String name;
  final String companyName;
  final String? description;
  final String? phone;
  final String? address;
  final String? googleMapsLink;
  final String? logoUrl;
  final String? bannerUrl;
  final int? activeOffersCount;

  const PartnerFiche({
    required this.id,
    required this.name,
    required this.companyName,
    this.description,
    this.phone,
    this.address,
    this.googleMapsLink,
    this.logoUrl,
    this.bannerUrl,
    this.activeOffersCount,
  });

  factory PartnerFiche.fromJson(Map<String, dynamic> json) {
    return PartnerFiche(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      googleMapsLink: json['google_maps_link']?.toString(),
      logoUrl: json['logo_url']?.toString(),
      bannerUrl: json['banner_url']?.toString(),
      activeOffersCount: (json['active_promotions_count'] as num?)?.toInt(),
    );
  }
}

class PromotionUsage {
  final int id;
  final String qrCode;
  final String status; // pending | used | expired
  final String? generatedAt;
  final String? usedAt;
  final String? validatorName;

  const PromotionUsage({
    required this.id,
    required this.qrCode,
    required this.status,
    this.generatedAt,
    this.usedAt,
    this.validatorName,
  });

  factory PromotionUsage.fromJson(Map<String, dynamic> json) {
    return PromotionUsage(
      id:            json['id'] as int,
      qrCode:        json['qr_code']?.toString() ?? '',
      status:        json['status']?.toString() ?? 'pending',
      generatedAt:   json['generated_at']?.toString(),
      usedAt:        json['used_at']?.toString(),
      validatorName: json['validator']?['name']?.toString(),
    );
  }
}