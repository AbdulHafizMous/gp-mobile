// lib/app/data/models/message_credit_pack_model.dart
//
// Pack de messages Crush achetable (monétisation désactivée par défaut,
// voir CrushQuotaService.isEnabled). Correspond à App\Models\MessageCreditPack
// côté backend.

class MessageCreditPack {
  final int id;
  final String name;
  final int credits;
  final double price;
  final String? appleProductId;

  const MessageCreditPack({
    required this.id,
    required this.name,
    required this.credits,
    required this.price,
    this.appleProductId,
  });

  /// Sur iOS, un pack sans identifiant produit Apple/RevenueCat ne peut pas
  /// être vendu (Apple Guideline 3.1.1) : on ne l'affiche pas.
  bool get isPurchasableOnCurrentPlatform =>
      appleProductId != null && appleProductId!.isNotEmpty;

  factory MessageCreditPack.fromJson(Map<String, dynamic> json) {
    return MessageCreditPack(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      credits: json['credits'] is int
          ? json['credits']
          : int.tryParse('${json['credits']}') ?? 0,
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse('${json['price']}') ?? 0,
      appleProductId: json['apple_product_id']?.toString(),
    );
  }
}

/// État courant du quota de messages Crush de l'utilisateur — voir
/// CrushQuotaService et App\Services\CrushMessageQuotaService côté backend.
class CrushQuotaStatus {
  final bool enabled;
  final int dailyLimit;
  final int usedToday;
  final int remainingToday;
  final int bonusCredits;

  const CrushQuotaStatus({
    required this.enabled,
    this.dailyLimit = 0,
    this.usedToday = 0,
    this.remainingToday = 0,
    this.bonusCredits = 0,
  });

  /// Aucune limite tant que la fonctionnalité est désactivée, ou tant qu'il
  /// reste des messages gratuits/bonus.
  bool get canSendMessage =>
      !enabled || remainingToday > 0 || bonusCredits > 0;

  factory CrushQuotaStatus.fromJson(Map<String, dynamic> json) {
    if (json['enabled'] != true) {
      return const CrushQuotaStatus(enabled: false);
    }
    return CrushQuotaStatus(
      enabled: true,
      dailyLimit: json['daily_limit'] ?? 0,
      usedToday: json['used_today'] ?? 0,
      remainingToday: json['remaining_today'] ?? 0,
      bonusCredits: json['bonus_credits'] ?? 0,
    );
  }
}
