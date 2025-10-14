class SongInPlaylist {
  final String title;
  final String artist;
  final String filename;
  final String album;
  final String songId;

  SongInPlaylist({
    required this.title,
    required this.artist,
    required this.filename,
    required this.album,
    required this.songId,
  });

  factory SongInPlaylist.fromJson(Map<String, dynamic> json) {
    return SongInPlaylist(
      title: json['title'] ?? '',
      artist: json['artist'] ?? 'Unknown Artist',
      filename: json['filename'] ?? '',
      album: json['album'] ?? 'Unknown Album',
      songId: json['songId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'filename': filename,
      'album': album,
      'songId': songId,
    };
  }
}

class Playlist {
  final String id;
  final String username;
  final String name;
  final String description;
  final List<SongInPlaylist> songs;

  Playlist({
    required this.id,
    required this.username,
    required this.name,
    required this.description,
    required this.songs,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      songs: (json['songs'] as List<dynamic>?)
              ?.map((e) => SongInPlaylist.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'name': name,
      'description': description,
      'songs': songs.map((e) => e.toJson()).toList(),
    };
  }
}
