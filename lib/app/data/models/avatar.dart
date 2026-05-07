class Avatar {
  final int id;
  final String name;
  final String url;

  Avatar({
    required this.id,
    required this.name,
    required this.url,
  });

  factory Avatar.fromJson(Map<String, dynamic> json) {
    return Avatar(
      id: json['id'],
      name: json['name'],
      url: json['url'],
    );
  }
}