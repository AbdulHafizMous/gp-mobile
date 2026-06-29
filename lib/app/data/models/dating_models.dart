// lib/app/data/models/dating_models.dart

// ─────────────────────────────────────────────────────────────────────────────
// DATING PROFILE
// ─────────────────────────────────────────────────────────────────────────────
class DatingProfile {
  final int id;
  final String name;
  final int age;
  final String? city;
  final String? bio;
  final String? avatarUrl;
  final List<String> photos;
  final List<String> interests;
  final String? gender;
  final double? distance; // km

  const DatingProfile({
    required this.id,
    required this.name,
    required this.age,
    this.city,
    this.bio,
    this.avatarUrl,
    this.photos = const [],
    this.interests = const [],
    this.gender,
    this.distance,
  });

  String get displayPhoto =>
      photos.isNotEmpty ? photos.first : (avatarUrl ?? '');

  String get locationLabel => city ?? 'Bénin';

  factory DatingProfile.fromJson(Map<String, dynamic> json) {
    return DatingProfile(
      id: _i(json['id']),
      name: json['name']?.toString() ?? '',
      age: _i(json['age']),
      city: json['city']?.toString(),
      bio: json['bio']?.toString() ?? json['description']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      photos: (json['photos'] as List<dynamic>? ?? [])
          .map((p) => p.toString())
          .toList(),
      interests: (json['interests'] as List<dynamic>? ?? [])
          .map((i) => i.toString())
          .toList(),
      gender: json['gender']?.toString(),
      distance: (json['distance'] as num?)?.toDouble(),
    );
  }

  static int _i(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// DATING MATCH (profil liké mutuellement)
// ─────────────────────────────────────────────────────────────────────────────
class DatingMatch {
  final int id;
  final DatingProfile profile;
  final DateTime matchedAt;
  final int? conversationId;

  const DatingMatch({
    required this.id,
    required this.profile,
    required this.matchedAt,
    this.conversationId,
  });

  factory DatingMatch.fromJson(Map<String, dynamic> json) {
    return DatingMatch(
      id: _i(json['id']),
      profile: DatingProfile.fromJson(json['profile'] as Map<String, dynamic>),
      matchedAt: _d(json['matched_at'] ?? json['created_at']),
      conversationId: json['conversation_id'] != null
          ? _i(json['conversation_id'])
          : null,
    );
  }

  static int _i(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
  static DateTime _d(dynamic v) {
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return DateTime.now();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATING PREFERENCES
// ─────────────────────────────────────────────────────────────────────────────
class DatingPreferences {
  final String? lookingFor; // 'male' | 'female' | 'both'
  final int? minAge;
  final int? maxAge;
  final double? maxDistance;
  final bool? isActive;

  const DatingPreferences({
    this.lookingFor,
    this.minAge,
    this.maxAge,
    this.maxDistance,
    this.isActive,
  });

  bool get isConfigured => lookingFor != null;

  Map<String, dynamic> toJson() => {
    'looking_for': lookingFor,
    'min_age': minAge,
    'max_age': maxAge,
    'max_distance': maxDistance,
    'is_active': isActive,
  };

  factory DatingPreferences.fromJson(Map<String, dynamic> json) =>
      DatingPreferences(
        lookingFor: json['looking_for']?.toString(),
        minAge: json['min_age'] is int ? json['min_age'] : null,
        maxAge: json['max_age'] is int ? json['max_age'] : null,
        maxDistance: (json['max_distance'] as num?)?.toDouble(),
        isActive: json['is_active'] is bool ? json['is_active'] : null,
      );
}
