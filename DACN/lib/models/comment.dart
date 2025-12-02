import 'package:flutter/material.dart';

class Comment {
  final String id;
  final String userId; 
  final String username; 
  final String avatarUrl; 
  final String content; 
  final DateTime createdAt; 

  Comment({
    required this.id,
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final userData = json['userId'];
    final isPopulated = userData is Map<String, dynamic>;

    return Comment(
        id: (json['_id'] ?? json['id'])?.toString() ?? '',
        userId: isPopulated ? userData['_id']?.toString() ?? '' : userData?.toString() ?? '',    
        username: isPopulated ? userData['username']?.toString() ?? '' : json['username']?.toString() ?? 'Unknown',
        avatarUrl: isPopulated ? userData['avatar']?.toString() ?? 'default_avatar_url' : json['avatarUrl']?.toString() ?? 'default_avatar_url',
        content: json['content']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
}
}