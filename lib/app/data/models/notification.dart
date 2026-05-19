class AppNotification {
  final int id;
  final String title;
  final String body;
  final String type;
  final String? route;
  final Map<String, dynamic>? data;
  final bool isRead;
  final String? readAt;
  final String createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.route,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id:        json['id'] as int,
      title:     json['title']?.toString() ?? '',
      body:      json['body']?.toString() ?? '',
      type:      json['type']?.toString() ?? 'general',
      route:     json['route']?.toString(),
      data:      json['data'] != null
                   ? Map<String, dynamic>.from(json['data'])
                   : null,
      isRead:    json['is_read'] == true,
      readAt:    json['read_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  AppNotification copyWith({bool? isRead, String? readAt}) {
    return AppNotification(
      id:        id,
      title:     title,
      body:      body,
      type:      type,
      route:     route,
      data:      data,
      isRead:    isRead ?? this.isRead,
      readAt:    readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}