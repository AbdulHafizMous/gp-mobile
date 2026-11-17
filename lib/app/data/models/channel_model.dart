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

/// Ligne de la fiche d'information d'un média (ex. « Fréquence : 106.0 FM »).
class ChannelInfoRow {
  final String label;
  final String value;
  final String? url;
  const ChannelInfoRow({required this.label, required this.value, this.url});

  factory ChannelInfoRow.fromJson(Map<String, dynamic> j) =>
      ChannelInfoRow(label: j['label']?.toString() ?? '', value: j['value']?.toString() ?? '', url: j['url']?.toString());
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
  final int? featuredRank; // 1..10 = dans le TOP 10 (classé par l'admin)
  final String? shareUrl;
  final String mediaKind; // creator | press | web_tv | web_radio | other
  final bool liveOnly; // média « direct uniquement » (web radio / web TV sans catalogue)
  final bool audioOnly;
  final String? streamUrl;
  final String? websiteUrl;
  final String? frequency; // ex. « FM 106.0 »
  final String? city;
  final List<ChannelInfoRow> info;
  // Direct payant (radio / TV « direct seulement ») : renvoyé par le serveur.
  final bool liveIsPaid;
  final int livePrice;
  final bool liveHasAccess;
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
    this.featuredRank,
    this.shareUrl,
    this.mediaKind = 'creator',
    this.liveOnly = false,
    this.audioOnly = false,
    this.streamUrl,
    this.websiteUrl,
    this.frequency,
    this.city,
    this.info = const [],
    this.liveIsPaid = false,
    this.livePrice = 0,
    this.liveHasAccess = true,
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
    featuredRank: j['featured_rank'] == null ? null : _i(j['featured_rank']),
    shareUrl: j['share_url']?.toString(),
    mediaKind: j['media_kind']?.toString() ?? 'creator',
    liveOnly: j['live_only'] == true || j['live_only'] == 1,
    audioOnly: j['audio_only'] == true || j['audio_only'] == 1,
    streamUrl: j['stream_url']?.toString(),
    websiteUrl: j['website_url']?.toString(),
    frequency: j['frequency']?.toString(),
    city: j['city']?.toString(),
    info: (j['info'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => ChannelInfoRow.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    liveIsPaid: j['live'] is Map && (j['live']['is_paid'] == true || j['live']['is_paid'] == 1),
    livePrice: j['live'] is Map ? int.tryParse('${j['live']['price']}') ?? 0 : 0,
    liveHasAccess: !(j['live'] is Map) || (j['live']['has_access'] != false && j['live']['has_access'] != 0),
    plans: (j['plans'] as List<dynamic>? ?? [])
        .map((p) => ChannelPlanModel.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList(),
    subscription: j['subscription'] is Map
        ? ChannelSubscriptionModel.fromJson(Map<String, dynamic>.from(j['subscription']))
        : null,
  );

  String get kindLabel => switch (mediaKind) {
        'press' => 'Presse en ligne',
        'web_tv' => 'Web TV',
        'web_radio' => 'Web radio',
        'creator' => 'Créateur',
        _ => 'Média',
      };
}
