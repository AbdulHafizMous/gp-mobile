// lib/app/data/models/channel_model.dart
//
// Chaînes de créateurs : /channels, /channels/{id}, abonnements.

int _i(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

class ChannelPlanModel {
  final int id;
  final String name;
  final double price;
  final int durationMonths;

  const ChannelPlanModel({required this.id, required this.name, required this.price, required this.durationMonths});

  factory ChannelPlanModel.fromJson(Map<String, dynamic> j) => ChannelPlanModel(
    id: _i(j['id']),
    name: j['name']?.toString() ?? '',
    price: _d(j['price']),
    durationMonths: _i(j['duration_months']),
  );

  String get priceLabel => '${price.round()} F';
  String get durationLabel => durationMonths == 1 ? '1 mois' : '$durationMonths mois';
}

class ChannelSubscriptionModel {
  final int id;
  final int channelId;
  final ChannelPlanModel? plan;
  final DateTime? endsAt;
  final bool isActive;

  const ChannelSubscriptionModel({required this.id, required this.channelId, this.plan, this.endsAt, required this.isActive});

  factory ChannelSubscriptionModel.fromJson(Map<String, dynamic> j) => ChannelSubscriptionModel(
    id: _i(j['id']),
    channelId: _i(j['channel_id']),
    plan: j['plan'] is Map ? ChannelPlanModel.fromJson(Map<String, dynamic>.from(j['plan'])) : null,
    endsAt: j['ends_at'] != null ? DateTime.tryParse(j['ends_at'].toString())?.toLocal() : null,
    isActive: j['is_active'] == true,
  );

  /// Jours restants (0 si expiré).
  int get daysLeft => endsAt == null ? 0 : endsAt!.difference(DateTime.now()).inDays.clamp(0, 9999);
}

class ChannelModel {
  final int id;
  final String name;
  final String description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? videoUrl;
  final bool isSubscribed;
  final bool isOwner;
  final List<ChannelPlanModel> plans;
  final ChannelSubscriptionModel? subscription;

  const ChannelModel({
    required this.id,
    required this.name,
    this.description = '',
    this.logoUrl,
    this.bannerUrl,
    this.videoUrl,
    this.isSubscribed = false,
    this.isOwner = false,
    this.plans = const [],
    this.subscription,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> j) => ChannelModel(
    id: _i(j['id']),
    name: j['name']?.toString() ?? '',
    description: j['description']?.toString() ?? '',
    logoUrl: j['logo_url']?.toString(),
    bannerUrl: j['banner_url']?.toString(),
    videoUrl: j['video_url']?.toString(),
    isSubscribed: j['is_subscribed'] == true,
    isOwner: j['is_owner'] == true,
    plans: (j['plans'] as List<dynamic>? ?? [])
        .map((p) => ChannelPlanModel.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList(),
    subscription: j['subscription'] is Map
        ? ChannelSubscriptionModel.fromJson(Map<String, dynamic>.from(j['subscription']))
        : null,
  );
}
