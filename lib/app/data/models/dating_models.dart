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
  final double? distance;

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
    // L'âge peut venir calculé depuis birthday
    int age = _i(json['age']);
    if (age == 0 && json['birthday'] != null) {
      try {
        final bday = DateTime.parse(json['birthday'].toString());
        age = DateTime.now().year - bday.year;
      } catch (_) {}
    }

    // Photos: l'avatar_url est toujours inclus
    final List<String> photos = (json['photos'] as List<dynamic>? ?? [])
        .map((p) => p.toString())
        .toList();
    final avatarUrl = json['avatar_url']?.toString();
    if (avatarUrl != null && avatarUrl.isNotEmpty && !photos.contains(avatarUrl)) {
      photos.insert(0, avatarUrl);
    }

    return DatingProfile(
      id:        _i(json['id']),
      name:      json['name']?.toString() ?? '',
      age:       age,
      city:      json['city']?.toString(),
      bio:       json['bio']?.toString() ?? json['description']?.toString(),
      avatarUrl: avatarUrl,
      photos:    photos,
      interests: (json['interests'] as List<dynamic>? ?? [])
          .map((i) => i.toString())
          .toList(),
      gender:    json['gender']?.toString(),
      distance:  (json['distance'] as num?)?.toDouble(),
    );
  }

  static int _i(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// DATING MATCH
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
    // Le profile peut venir sous 'other_user' ou 'profile'
    final profileData = (json['profile'] ?? json['other_user']) as Map<String, dynamic>?;
    return DatingMatch(
      id:             _i(json['id']),
      profile:        profileData != null
          ? DatingProfile.fromJson(profileData)
          : DatingProfile(id: 0, name: 'Inconnu', age: 0),
      matchedAt:      _d(json['matched_at'] ?? json['created_at']),
      conversationId: json['conversation_id'] != null ? _i(json['conversation_id']) : null,
    );
  }

  static int _i(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
  static DateTime _d(dynamic v) {
    try { return DateTime.parse(v.toString()); } catch (_) { return DateTime.now(); }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATING PREFERENCES
// ─────────────────────────────────────────────────────────────────────────────
class DatingPreferences {
  final String? lookingFor;
  final int? minAge;
  final int? maxAge;
  final double? maxDistance;
  final bool isActive;

  const DatingPreferences({
    this.lookingFor,
    this.minAge,
    this.maxAge,
    this.maxDistance,
    this.isActive = true,
  });

  bool get isConfigured => lookingFor != null && lookingFor!.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'looking_for':  lookingFor,
    'min_age':      minAge,
    'max_age':      maxAge,
    'max_distance': maxDistance,
    'is_active':    isActive,
  };

  factory DatingPreferences.fromJson(Map<String, dynamic> json) =>
      DatingPreferences(
        lookingFor:  json['looking_for']?.toString(),
        minAge:      json['min_age'] is int ? json['min_age'] as int : null,
        maxAge:      json['max_age'] is int ? json['max_age'] as int : null,
        maxDistance: (json['max_distance'] as num?)?.toDouble(),
        isActive:    json['is_active'] is bool ? json['is_active'] as bool : true,
      );
}