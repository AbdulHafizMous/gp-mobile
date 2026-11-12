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
  final int? gcoinPrice; // prix en GCoin (null = gratuit)
  final PromotionPartner? partner;
  // Offre mise en avant par un sponsor (ex: MTN pendant sa semaine de
  // takeover) dans la section "Offres sponsorisées" du Club.
  final bool isFeatured;
  final String? sponsorName;

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
    this.gcoinPrice,
    this.partner,
    this.isFeatured = false,
    this.sponsorName,
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
      gcoinPrice:      (json['gcoin_price'] as num?)?.toInt(),
      partner:         json['partner'] != null
                         ? PromotionPartner.fromJson(json['partner'])
                         : null,
      isFeatured:      json['is_featured'] == true,
      sponsorName:     json['sponsor_name']?.toString(),
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
      isExpired: isExpired, isAvailable: isAvailable, imageUrl: imageUrl, gcoinPrice: gcoinPrice,
      partner: partner, isFeatured: isFeatured, sponsorName: sponsorName,
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
  final double? latitude;
  final double? longitude;

  const PromotionPartner({
    required this.id,
    required this.name,
    this.companyName,
    this.avatarUrl,
    this.logoUrl,
    this.bannerUrl,
    this.address,
    this.googleMapsLink,
    this.latitude,
    this.longitude,
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
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
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
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final List<NearbyOffer> offers;

  bool get hasPosition => latitude != null && longitude != null;

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
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.offers = const [],
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
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      offers: ((json['promotions'] as List?) ?? const [])
          .map((e) => NearbyOffer.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

/// Offre résumée renvoyée par /partners/nearby.
class NearbyOffer {
  final int id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? endsAt;
  final int? gcoinPrice;
  const NearbyOffer({required this.id, required this.title, this.description, this.imageUrl, this.endsAt, this.gcoinPrice});
  factory NearbyOffer.fromJson(Map<String, dynamic> j) => NearbyOffer(
    id: (j['id'] as num).toInt(),
    title: j['title']?.toString() ?? '',
    description: j['description']?.toString(),
    imageUrl: j['image_url']?.toString(),
    endsAt: j['ends_at']?.toString(),
    gcoinPrice: (j['gcoin_price'] as num?)?.toInt(),
  );
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