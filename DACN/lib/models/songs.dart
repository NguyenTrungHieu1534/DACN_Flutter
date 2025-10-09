class Songs {
  final String id;
  final String title;
  final String artist;
  final String albuml;
  final String url;
  String thumbnail;

  Songs({
    required this.id,
    required this.title,
    required this.artist,
    required this.albuml,
    required this.url,
    required this.thumbnail,
  });

  factory Songs.fromJson(Map<String, dynamic> json) {
    return Songs(
      id: json['_id']?.toString() ?? '',
      title: json['title'] ?? '',
      albuml: json['album'] ?? '',
      artist: json['artist'] ?? '',
      url: json['url'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
    );
  }
  // @override
  // String toString() {
  //   return 'Song(id: $id, title: $title)';
  // }
}
