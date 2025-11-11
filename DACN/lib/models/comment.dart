// models/comment.dart (Phiên bản đã sửa lỗi Type Casting)

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
    
    // Nếu userData là Map (Populated user object - từ GET request)
    final isPopulated = userData is Map<String, dynamic>;

    return Comment(
        id: (json['_id'] ?? json['id'])?.toString() ?? '',
        // Lấy User ID
        userId: isPopulated ? userData['_id']?.toString() ?? '' : userData?.toString() ?? '', 
        // Lấy Username: nếu populate, lấy từ Map; nếu không, lấy từ trường cấp cao nhất
        username: isPopulated ? userData['username']?.toString() ?? '' : json['username']?.toString() ?? 'Unknown',
        // Lấy Avatar: tương tự
        avatarUrl: isPopulated ? userData['avatar']?.toString() ?? 'default_avatar_url' : json['avatarUrl']?.toString() ?? 'default_avatar_url',
        content: json['content']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
}
}