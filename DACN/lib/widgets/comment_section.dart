
import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../services/api_comment.dart';
import '../services/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:developer';

class CommentSection extends StatefulWidget {
  final String songId;
  const CommentSection({super.key, required this.songId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final CommentService _commentService = CommentService();
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchComments();
    _setupSocketListener();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      _userId = JwtDecoder.decode(token)['_id'];
    }
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoading = true);
    try {
      final comments = await _commentService.fetchComments(widget.songId);
      setState(() {
        _comments = comments;
      });
    } catch (e) {
      log("Error fetching comments: $e", name: "CommentSection");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setupSocketListener() {
    SocketService().socket?.on('new_comment_song_${widget.songId}', (data) {
      if (data is Map<String, dynamic>) {
        try {
          final newComment = Comment.fromJson(data);
          if (mounted) {
            setState(() {
              _comments.insert(0, newComment);
            });
          }
        } catch (e) {
          log("Socket Data Error: $e", name: "CommentSection");
        }
      }
    });
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final content = _commentController.text.trim();
    _commentController.clear();

    try {
      await _commentService.addComment(
        songId: widget.songId,
        content: content,
      );
      await _fetchComments();
    } catch (e) {
      String displayError;
      try {
        if (e is Exception) {
          displayError = e.toString().replaceFirst('Exception: ', '');
        } else if (e is Error) {
          displayError = e.toString().replaceFirst('Error: ', '');
        } else if (e is String) {
          displayError = e;
        } else {
          displayError = 'Lỗi Runtime không xác định (Type: ${e.runtimeType})';
        }
      } catch (_) {
        displayError = 'Lỗi định dạng Exception nghiêm trọng.';
      }

      log("Error adding comment: $e", name: "CommentSection - FINAL FIX");
      log("LỖI GỐC CÓ DẠNG: ${e.runtimeType}", name: "DEBUG KEY");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể gửi bình luận: $displayError'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputWidget = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: "Viết bình luận của bạn...",
                hintStyle: const TextStyle(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _addComment,
            ),
          ),
        ],
      ),
    );
    final listWidget = _isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.white70))
        : _comments.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 50.0),
                  child: Text("Chưa có bình luận nào.",
                      style: TextStyle(color: Colors.white54)),
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(comment.avatarUrl),
                      backgroundColor: Colors.grey.shade800,
                    ),
                    title: Text(comment.username,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comment.content,
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(
                          '${comment.createdAt.hour}:${comment.createdAt.minute} - ${comment.createdAt.day}/${comment.createdAt.month}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ),
                  );
                },
              );

    return Column(
      children: [
        Expanded(child: listWidget),
        inputWidget,
      ],
    );
  }

  @override
  void dispose() {
    SocketService().socket?.off('new_comment_song_${widget.songId}');
    _commentController.dispose();
    super.dispose();
  }
}
