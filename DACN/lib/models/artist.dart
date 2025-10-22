class Artist {
  final String? id; // MongoDB default _id
  final String? name;
  final String? bio;
  final String? fullbio;
  final String? genre;
  final String? filename;
  final String? avatarUrl;
  final String? avatarPublicId;

  Artist({
    this.id,
    this.name,
    this.bio,
    this.fullbio,
    this.genre,
    this.filename,
    this.avatarUrl,
    this.avatarPublicId,
  });
  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['_id'] as String?, 
      name: json['name'] as String?,
      bio: json['bio'] as String?,
      fullbio: json['fullbio'] as String?,
      genre: json['genre'] as String?,
      filename: json['filename'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      avatarPublicId: json['avatarPublicId'] as String?,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bio': bio,
      'fullbio': fullbio,
      'genre': genre,
      'filename': filename,
      'avatarUrl': avatarUrl,
      'avatarPublicId': avatarPublicId,
    };
  }
}