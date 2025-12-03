class Video {
  final int id;
  final String youtubeId;
  final String title;
  final String? description;
  final String publicationDate;
  final String videoThumbnail;
  final int views;
  final String category;

  Video({
    required this.id,
    required this.youtubeId,
    required this.title,
    this.description,
    required this.publicationDate,
    required this.videoThumbnail,
    required this.views,
    required this.category,
  });

  factory Video.empty() {
    return Video(
      id: 0,
      youtubeId: '',
      title: '',
      publicationDate: '',
      videoThumbnail: '',
      views: 0,
      category: '',
    );
  }

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      youtubeId: json['youtube_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description'] ?? json['short_description'],
      publicationDate: json['publication_date']?.toString() ?? '',
      videoThumbnail: json['video_thumbnail']?.toString() ?? '',
      views: json['views'] is int
          ? json['views']
          : int.tryParse(json['views']?.toString().replaceAll(',', '') ?? '') ??
              0,
      category: json['category']?.toString() ?? '',
    );
  }

  @override
  String toString() {
    return 'Video{id: $id, youtubeId: $youtubeId, title: $title, description: $description, publicationDate: $publicationDate, videoThumbnail: $videoThumbnail, views: $views, category: $category}';
  }
}
