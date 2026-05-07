// lib/app/data/models/subscription.dart

// ── Plan d'abonnement (liste des plans disponibles) ───────────────────────────
class Subscription {
  final int id;
  final String name;
  final String shortDescription;
  final String duration;
  final double price;
  final int durationMonths;

  const Subscription({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.duration,
    required this.price,
    this.durationMonths = 1,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      shortDescription: json['description']?.toString() ?? '',
      duration: '${json['duration_months'] ?? 1} mois',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      durationMonths: _parseInt(json['duration_months']),
    );
  }

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

// ── Abonnement actif de l'utilisateur ────────────────────────────────────────
class ActiveSubscription {
  final int id;
  final String paymentRef;
  final DateTime startsAt;
  final DateTime endsAt;
  final DateTime? cancelledAt;
  final bool isActive;
  final SubscriptionPlan? plan;

  const ActiveSubscription({
    required this.id,
    required this.paymentRef,
    required this.startsAt,
    required this.endsAt,
    this.cancelledAt,
    required this.isActive,
    this.plan,
  });

  bool get isValid => isActive && endsAt.isAfter(DateTime.now());

  String get formattedExpiry {
    return '${endsAt.day}/${endsAt.month}/${endsAt.year}';
  }

  factory ActiveSubscription.fromJson(Map<String, dynamic> json) {
    return ActiveSubscription(
      id: _parseInt(json['id']),
      paymentRef: json['payment_ref']?.toString() ?? '',
      startsAt: _parseDate(json['starts_at']),
      endsAt: _parseDate(json['ends_at']),
      cancelledAt: json['cancelled_at'] != null
          ? _parseDate(json['cancelled_at'])
          : null,
      isActive: _parseBool(json['is_active']),
      plan: json['subscription_plan'] != null
          ? SubscriptionPlan.fromJson(
              json['subscription_plan'] as Map<String, dynamic>)
          : null,
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
    if (v == null) return DateTime.now();
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return DateTime.now();
    }
  }
}

// ── Plan de l'abonnement actif ────────────────────────────────────────────────
class SubscriptionPlan {
  final int id;
  final String name;
  final String description;
  final double price;
  final int durationMonths;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMonths,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      durationMonths: _parseInt(json['duration_months']),
    );
  }

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}