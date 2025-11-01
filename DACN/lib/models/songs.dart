class Songs {
  final String id;
  final String title;
  final String artist;
  final String albuml;
  final String url;
  String thumbnail;
  final String mp3Url;
  final String lyric;

  Songs({
    required this.id,
    required this.title,
    required this.artist,
    required this.albuml,
    required this.url,
    required this.thumbnail,
    required this.mp3Url,
    this.lyric = '',
  });
Songs copyWith({
    String? id,
    String? title,
    String? artist,
    String? albuml,
    String? url,
    String? thumbnail,
    String? mp3Url,
    String? lyric,
  }) {
    return Songs(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albuml: albuml ?? this.albuml,
      url: url ?? this.url,
      thumbnail: thumbnail ?? this.thumbnail,
      mp3Url: mp3Url ?? this.mp3Url,
      lyric: lyric ?? this.lyric,
    );
  }
  factory Songs.fromJson(Map<String, dynamic> json) {
    return Songs(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      title: json['title'] ?? '',
      albuml: json['album'] ?? '',
      artist: json['artist'] ?? '',
      url: json['url'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      mp3Url: json['mp3Url'] ?? '',
      lyric: json['lyric'] ?? 'Nah lyric',
    );
  }
  // @override
  // String toString() {
  //   return 'Song(id: $id, title: $title)';
  // }
}
