import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'album_detail_screen.dart';
import '../navigation/custom_page_route.dart';

class NotificationListScreen extends StatefulWidget {
  final VoidCallback onNotificationsCleared;
  const NotificationListScreen(
      {super.key, required this.onNotificationsCleared});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    final decodedToken = JwtDecoder.decode(token);
    final currentUserId = decodedToken['_id'];

    final savedData = prefs.getString('thongBaoList');
    if (savedData != null && savedData.isNotEmpty) {
      final allNotifications = jsonDecode(savedData) as Map<String, dynamic>;
      if (allNotifications.containsKey(currentUserId)) {
        setState(() {
          _notifications =
              List<Map<String, dynamic>>.from(allNotifications[currentUserId])
                  .reversed
                  .toList();
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final decodedToken = JwtDecoder.decode(token);
    final currentUserId = decodedToken['_id'];

    final savedData = prefs.getString('thongBaoList');
    if (savedData != null && savedData.isNotEmpty) {
      final allNotifications = jsonDecode(savedData) as Map<String, dynamic>;
      if (allNotifications.containsKey(currentUserId)) {
        allNotifications.remove(currentUserId);
        await prefs.setString('thongBaoList', jsonEncode(allNotifications));
        widget.onNotificationsCleared();
        setState(() {
          _notifications = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa tất cả thông báo')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Xóa tất cả',
              onPressed: _clearNotifications,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Text(
                    'Không có thông báo nào.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final time = DateTime.parse(notification['time']);
                    final albumData =
                        notification['album'] as Map<String, dynamic>?;
                    final albumImageUrl = albumData?['url'] as String?;

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundImage:
                            albumImageUrl != null && albumImageUrl.isNotEmpty
                                ? NetworkImage(albumImageUrl)
                                : null,
                        backgroundColor: Theme.of(context).hoverColor,
                        child: (albumImageUrl == null || albumImageUrl.isEmpty)
                            ? const Icon(Icons.album, size: 28)
                            : null,
                      ),
                      title: Text(notification['message'] ?? ''),
                      subtitle: Text(timeago.format(time)),
                      onTap: () {
                        if (albumData != null &&
                            albumData['name'] != null &&
                            albumData['url'] != null) {
                          Navigator.push(
                            context,
                            FadePageRoute(
                              child: AlbumDetailScreen(
                                albumName: albumData['name'],
                                albumImage: albumData['url'],
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
    );
  }
}
