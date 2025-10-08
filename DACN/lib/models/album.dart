class Album {
  final String id;
  final String name;
  final String artist;
  final String url;

  Album({
    required this.id,
    required this.name,
    required this.artist,
    required this.url,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      artist: json['artist'] ?? '',
      url: json['url'] ?? '',
    );
  }
}
