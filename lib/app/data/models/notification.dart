class CustomNotification {
  String title;
  String description;

  CustomNotification({required this.title, required this.description});

  factory CustomNotification.fromJson(Map<String, dynamic> json) {
    return CustomNotification(
        title: json['title'], description: json['short_description']);
  }
}
