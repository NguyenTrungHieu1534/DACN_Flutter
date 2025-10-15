import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'login_screen.dart';
import '../services/api_user.dart';
import '../theme/app_theme.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  String? _token;
  bool _loading = true;

  String? _userId;
  String? _username;
  String? _avatar;
  final UserService userService = UserService();
  bool isUploading = false;
  String? avatarUrl;
  @override
  void initState() {
    _checkToken();
    super.initState();
  }

  Future<void> _showImagePicker(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.retroAccent),
              title: const Text('Chọn từ thư viện'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.retroAccent),
              title: const Text('Chụp ảnh'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      File image = File(pickedFile.path);

      setState(() => isUploading = true);

      final result = await userService.uploadAvatar(_userId.toString(), image);

      setState(() => isUploading = false);

      if (result['url'] != null) {
        setState(() => avatarUrl = result['url']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Upload thành công!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: ${result['details']}")),
        );
      }
    }
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      Map<String, dynamic> decoded = JwtDecoder.decode(token);
      setState(() {
        _token = token;
        _userId = decoded["_id"];
        _username = decoded["username"];
        _loading = false;
        _avatar = decoded["ava"];
      });
      print('avatarUrl: $_avatar');
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.retroAccent))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.retroWhite,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: AppColors.retroPrimary,
            foregroundColor: AppColors.retroWhite,
            title: const Text('🌤️ Wave Music'),
            centerTitle: true,
            pinned: true,
            actions: _token != null
                ? [
                    IconButton(
                      icon: const Icon(Icons.logout, color: AppColors.retroWhite),
                      onPressed: _logout,
                    ),
                  ]
                : null,
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: _token == null
                ? Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text('Đăng nhập', style: TextStyle(color: AppColors.retroWhite),),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => _showImagePicker(context),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: AppColors.retroWhite.withOpacity(0.6),
                                backgroundImage:
                                    _avatar != null ? NetworkImage(_avatar!) : null,
                                child: _avatar == null
                                    ? const Icon(Icons.person,
                                        size: 40, color: AppColors.retroAccent)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _username?.toUpperCase() ?? 'USER',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.retroAccent,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ---------- 2/3 DƯỚI: LIST NHẠC ----------
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.retroWhite,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: _buildMusicList(),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicList() {
    List<String> songs = [];

    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.music_note, size: 40, color: AppColors.retroAccent.withOpacity(0.7)),
            const SizedBox(height: 8),
            Text('Chưa có bài nhạc nào', style: TextStyle(color: AppColors.retroAccent.withOpacity(0.7))),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.play_circle_fill, color: AppColors.retroAccent),
          title: Text(songs[index], style: const TextStyle(color: AppColors.retroAccent)),
        );
      },
    );
  }
}
