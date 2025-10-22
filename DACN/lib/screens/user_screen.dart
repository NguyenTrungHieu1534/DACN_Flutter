import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import '../services/api_user.dart';
import '../screens/setting_screen.dart';
import '../models/ThemeProvider.dart';

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
  String? _email;
  String? _role;
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
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
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
    final stored = prefs.getString('token');

    // Guard: no token saved
    if (stored == null || stored.trim().isEmpty) {
      setState(() => _loading = false);
      return;
    }

    // Strip optional Bearer prefix and validate basic JWT structure
    final rawToken = stored.startsWith('Bearer ')
        ? stored.substring(7).trim()
        : stored.trim();
    final looksLikeJwt = rawToken.split('.').length == 3;

    if (!looksLikeJwt) {
      // Invalid format -> treat as logged out
      setState(() => _loading = false);
      return;
    }

    try {
      final Map<String, dynamic> decoded = JwtDecoder.decode(rawToken);
      setState(() {
        _token = rawToken;
        _userId = decoded["_id"];
        _username = decoded["username"];
        _email = decoded["email"];
        _role = decoded["role"];
        _avatar = decoded["ava"];
        _loading = false;
      });
      print('avatarUrl: $_avatar');
    } catch (e) {
      // Decoding failed -> consider token invalid
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Text(
              '🌤️ Wave Music',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
            ),
            IconButton(
              icon: Icon(Icons.settings, color: Theme.of(context).appBarTheme.foregroundColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
        centerTitle: true,
        actions: _token != null
            ? [
                IconButton(
                  icon: Icon(Icons.logout, color: Theme.of(context).appBarTheme.foregroundColor),
                  onPressed: _logout,
                ),
              ]
            : null,
      ),
      body: _token == null
          ? Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text('Đăng nhập'),
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
                          backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.6),
                          backgroundImage:
                              _avatar != null ? NetworkImage(_avatar!) : null,
                          child: _avatar == null
                              ? Icon(Icons.person,
                                  size: 40, color: Theme.of(context).colorScheme.onSurface)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _username?.toUpperCase() ?? 'USER',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
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
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    // child: Consumer<ThemeProvider>(
                    //   builder: (context, themeProvider, child) {
                    //     return Column(
                    //       children: [
                    //         // ListTile(
                    //         //   leading: Icon(Icons.palette, color: Theme.of(context).colorScheme.onSurface),
                    //         //   title: Text('Theme', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                    //         //   trailing: DropdownButton<bool>(
                    //         //     value: themeProvider.isDark,
                    //         //     dropdownColor: Theme.of(context).colorScheme.surface,
                    //         //     style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    //         //     items: const [
                    //         //       DropdownMenuItem(
                    //         //         value: false,
                    //         //         child: Text('Light Mode'),
                    //         //       ),
                    //         //       DropdownMenuItem(
                    //         //         value: true,
                    //         //         child: Text('Dark Mode'),
                    //         //       ),
                    //         //     ],
                    //         //     onChanged: (bool? value) {
                    //         //       if (value != null) {
                    //         //         themeProvider.setTheme(value);
                    //         //       }
                    //         //     },
                    //         //   ),
                    //         // ),
                    //       ],
                    //     );
                    //   },
                    // ),
                  ),
                ),
              ],
            ),
    );
  }
}
