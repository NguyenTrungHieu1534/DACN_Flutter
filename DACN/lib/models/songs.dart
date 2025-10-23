class Songs {
  final String id;
  final String title;
  final String artist;
  final String albuml;
  final String url;
  String thumbnail;
  final String mp3Url;

  Songs({
    required this.id,
    required this.title,
    required this.artist,
    required this.albuml,
    required this.url,
    required this.thumbnail,
    required this.mp3Url,
  });

  factory Songs.fromJson(Map<String, dynamic> json) {
    return Songs(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      title: json['title'] ?? '',
      albuml: json['album'] ?? '',
      artist: json['artist'] ?? '',
      url: json['url'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      mp3Url: json['mp3Url'] ?? '',
    );
  }
  // @override
  // String toString() {
  //   return 'Song(id: $id, title: $title)';
  // }
}
