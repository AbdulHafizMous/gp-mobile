
class User {
  final int id;
  final String name;
  final String email;
  final String? username;
  final String? phone;
  final String? avatarUrl;
  final String? birthday;
  final String? city;
  final String? gender;
  final String? description;
  final String? lookingForGender;
  final String? fcmToken;
  final String? firebaseId;
  final String role;
  final String? countryCode;
  final bool isOtpVerified;
  final bool isActive;
  final bool needsCompletion;
  final String? emailVerifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.username,
    this.phone,
    this.avatarUrl,
    this.birthday,
    this.city,
    this.gender,
    this.description,
    this.lookingForGender,
    this.fcmToken,
    this.firebaseId,
    required this.role,
    this.countryCode,
    required this.isOtpVerified,
    required this.isActive,
    required this.needsCompletion,
    this.emailVerifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Getters utiles ─────────────────────────────────────────────────────────
  String get firstName {
    final parts = name.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : name;
  }

  String get lastName {
    return name.trim().split(' ').first;
  }

  bool get isAdmin => role == 'admin';
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  // ── Empty ──────────────────────────────────────────────────────────────────
  factory User.empty() {
    return User(
      id: 0,
      name: '',
      email: '',
      role: 'user',
      isOtpVerified: false,
      isActive: false,
      needsCompletion: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ── fromJson ───────────────────────────────────────────────────────────────
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString(),
      phone: json['phone']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      birthday: json['birthday']?.toString(),
      city: json['city']?.toString(),
      gender: json['gender']?.toString(),
      description: json['description']?.toString(),
      lookingForGender: json['looking_for_gender']?.toString(),
      fcmToken: json['fcm_token']?.toString(),
      firebaseId: json['firebase_id']?.toString(),
      role: json['role']?.toString() ?? 'user',
      countryCode: json['country_code']?.toString(),
      isOtpVerified: _parseBool(json['is_otp_verified']),
      isActive: _parseBool(json['is_active']),
      needsCompletion: _parseBool(json['needs_completion']),
      emailVerifiedAt: json['email_verified_at']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  // ── toJson ─────────────────────────────────────────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'phone': phone,
      'avatar_url': avatarUrl,
      'birthday': birthday,
      'city': city,
      'gender': gender,
      'description': description,
      'looking_for_gender': lookingForGender,
      'fcm_token': fcmToken,
      'firebase_id': firebaseId,
      'role': role,
      'country_code': countryCode,
      'is_otp_verified': isOtpVerified,
      'is_active': isActive,
      'needs_completion': needsCompletion,
      'email_verified_at': emailVerifiedAt,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ── copyWith ───────────────────────────────────────────────────────────────
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? username,
    String? phone,
    String? avatarUrl,
    String? birthday,
    String? city,
    String? gender,
    String? description,
    String? lookingForGender,
    String? fcmToken,
    String? firebaseId,
    String? role,
    String? countryCode,
    bool? isOtpVerified,
    bool? isActive,
    bool? needsCompletion,
    String? emailVerifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      birthday: birthday ?? this.birthday,
      city: city ?? this.city,
      gender: gender ?? this.gender,
      description: description ?? this.description,
      lookingForGender: lookingForGender ?? this.lookingForGender,
      fcmToken: fcmToken ?? this.fcmToken,
      firebaseId: firebaseId ?? this.firebaseId,
      role: role ?? this.role,
      countryCode: countryCode ?? this.countryCode,
      isOtpVerified: isOtpVerified ?? this.isOtpVerified,
      isActive: isActive ?? this.isActive,
      needsCompletion: needsCompletion ?? this.needsCompletion,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Helpers privés ─────────────────────────────────────────────────────────
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      return ['1', 'true', 'yes'].contains(value.toLowerCase());
    }
    return false;
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, phone: $phone, '
        'role: $role, isActive: $isActive, isOtpVerified: $isOtpVerified}';
  }
}
