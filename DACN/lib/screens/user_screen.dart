import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'login_screen.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  String? _token;
  bool _loading = true;

  // Các trường thông tin người dùng
  String? _userId;
  String? _username;
  String? _email;
  String? _role;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      Map<String, dynamic> decoded = JwtDecoder.decode(token);
      print(decoded);
      setState(() {
        _token = token;
        _userId = decoded["_id"];
        _username = decoded["username"];
        _email = decoded["email"];
        _role = decoded["role"];
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
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
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Trang chủ',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: _token != null
            ? [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _logout,
                  tooltip: 'Đăng xuất',
                ),
              ]
            : null,
      ),
      body: Center(
        child: _token != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎵 Chào mừng đến Wave Music!',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),
                  Text('ID: $_userId'),
                  Text('Username: $_username'),
                  Text('Email: $_email'),
                  Text('Role: $_role'),
                ],
              )
            : ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('Đăng nhập'),
              ),
      ),
    );
  }
}
