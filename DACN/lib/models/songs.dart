class Songs {
  final String id;
  final String title;
  final String artist;
  final String albuml;
  final String url;

  Songs({
    required this.id,
    required this.title,
    required this.artist,
    required this.albuml,
    required this.url,
  });

  factory Songs.fromJson(Map<String, dynamic> json) {
    return Songs(
      id: json['_id']?.toString() ?? '',
      title: json['name'] ?? '',
      albuml: json['album'] ?? '',
      artist: json['artist'] ?? '',
      url: json['url'] ?? '',
    );
  }
}