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
    final rawData = json['data'];

    Map<String, dynamic>? parsedData;

    if (rawData is Map) {
      parsedData = Map<String, dynamic>.from(rawData);
    } else {
      // Si l'API renvoie [] ou null,
      // on considère qu'il n'y a pas de data.
      parsedData = null;
    }

    return AppNotification(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,

      title: json['title']?.toString() ?? '',

      body: json['body']?.toString() ?? '',

      type: json['type']?.toString() ?? 'general',

      route: json['route']?.toString(),

      data: parsedData,

      isRead: json['is_read'] == true,

      readAt: json['read_at']?.toString(),

      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  AppNotification copyWith({bool? isRead, String? readAt}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      route: route,
      data: data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}
