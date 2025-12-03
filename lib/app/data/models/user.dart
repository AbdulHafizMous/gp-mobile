class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? googleId;
  final String? facebookId;
  final bool termsAccepted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? emailVerifiedAt;
  final bool hasActiveSubscriptions;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.googleId,
    this.facebookId,
    required this.termsAccepted,
    required this.createdAt,
    required this.updatedAt,
    this.emailVerifiedAt,
    required this.hasActiveSubscriptions,
  });

  factory User.empty() {
    return User(
      id: 0,
      firstName: '',
      lastName: '',
      email: '',
      googleId: null,
      facebookId: null,
      termsAccepted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      emailVerifiedAt: null,
      hasActiveSubscriptions: false,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      googleId: json['google_id'],
      facebookId: json['facebook_id'],
      termsAccepted: json['terms_accepted'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'])
          : null,
      hasActiveSubscriptions: json['has_active_subscriptions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'google_id': googleId,
      'facebook_id': facebookId,
      'terms_accepted': termsAccepted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'has_active_subscriptions': hasActiveSubscriptions,
    };
  }

  @override
  String toString() {
    return 'User{id: $id, firstName: $firstName, lastName: $lastName, email: $email, googleId: $googleId, facebookId: $facebookId, termsAccepted: $termsAccepted, createdAt: $createdAt, updatedAt: $updatedAt, emailVerifiedAt: $emailVerifiedAt, hasActiveSubscriptions: $hasActiveSubscriptions}';
  }
}
