class Subscription {
  final int id;
  final String name;
  final String shortDescription;
  final String duration;
  final int price;

  Subscription({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.duration,
    required this.price,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    // Defensive parsing: some APIs return numeric fields as strings.
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Subscription(
      id: parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      shortDescription: json['short_description']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      price: parseInt(json['price']),
    );
  }
}