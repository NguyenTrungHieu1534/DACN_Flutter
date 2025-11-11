import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../screens/block_screen.dart';
import '../screens/album_detail_screen.dart';
import '../widgets/notificationWG.dart';
import '/main.dart';
import '../screens/user_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  IO.Socket? get socket => _socket;
  final Map<String, List<Function(dynamic)>> _eventHandlers = {};

  void connect(String userId) {
    // Nếu đã connect, không kết nối lại
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(
      'https://backend-dacn-9l4w.onrender.com',
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      },
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Socket connected: ${_socket!.id}');
      _socket!.emit('register', userId);

      _eventHandlers.forEach((event, handlers) {
        for (var handler in handlers) {
          _socket!.on(event, handler);
        }
      });
    });
    _socket!.onDisconnect((_) {
      print('Socket disconnected');
    });

    _registerDefaultHandlers();
  }

  void _registerDefaultHandlers() {
    // Event blocked
    registerEventHandler('blocked', (data) {
      print('Bị chặn: ${data['message']}');
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushAndRemoveUntil(
            ctx,
            MaterialPageRoute(
                builder: (_) => BlockedScreen(message: data['message'])),
            (_) => false,
          );
        });
      }
    });

    registerEventHandler('nofiNewSongAritst', (data) async {
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> allNotifications = {};
      final savedData = prefs.getString('thongBaoList');
      if (savedData != null && savedData.isNotEmpty) {
        allNotifications = jsonDecode(savedData);
      }
      String? currentUserId;
      try {
        final token = prefs.getString('token');
        if (token != null) {
          final decodedToken = JwtDecoder.decode(token);
          currentUserId = decodedToken['_id'];
        }
      } catch (err) {
        print('Không lấy được token: $err');
        return;
      }

      if (currentUserId == null) return;
      if (!allNotifications.containsKey(currentUserId)) {
        allNotifications[currentUserId] = [];
      }
      allNotifications[currentUserId].add({
        'message': data['message'],
        'album': data['albumExist'] ?? {},
        'time': DateTime.now().toIso8601String(),
      });
      await prefs.setString('thongBaoList', jsonEncode(allNotifications));
      print(
          'Thông báo mới được thêm cho user $currentUserId: ${data['message']}');
    });
    registerEventHandler('turnartists', (data) async {
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> allNotifications = {};
      final savedData = prefs.getString('thongBaoList');
      if (savedData != null && savedData.isNotEmpty) {
        allNotifications = jsonDecode(savedData);
      }
      String? currentUserId;
      try {
        final token = prefs.getString('token');
        if (token != null) {
          final decodedToken = JwtDecoder.decode(token);
          currentUserId = decodedToken['_id'];
        }
      } catch (err) {
        print('Không lấy được token: $err');
        return;
      }

      if (currentUserId == null) return;
      if (!allNotifications.containsKey(currentUserId)) {
        allNotifications[currentUserId] = [];
      }
      allNotifications[currentUserId].add({
        'message': data['message'],
        'album': data['albumExist'] ?? {},
        'time': DateTime.now().toIso8601String(),
      });
      await prefs.setString('thongBaoList', jsonEncode(allNotifications));
      print(
          'Thông báo mới được thêm cho user $currentUserId: ${data['message']}');
    });
    registerEventHandler('unartists', (data) async {
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> allNotifications = {};
      final savedData = prefs.getString('thongBaoList');
      if (savedData != null && savedData.isNotEmpty) {
        allNotifications = jsonDecode(savedData);
      }
      String? currentUserId;
      try {
        final token = prefs.getString('token');
        if (token != null) {
          final decodedToken = JwtDecoder.decode(token);
          currentUserId = decodedToken['_id'];
        }
      } catch (err) {
        print('Không lấy được token: $err');
        return;
      }

      if (currentUserId == null) return;
      if (!allNotifications.containsKey(currentUserId)) {
        allNotifications[currentUserId] = [];
      }
      allNotifications[currentUserId].add({
        'message': data['message'],
        'album': data['albumExist'] ?? {},
        'time': DateTime.now().toIso8601String(),
      });
      await prefs.setString('thongBaoList', jsonEncode(allNotifications));
      print(
          'Thông báo mới được thêm cho user $currentUserId: ${data['message']}');
    });
  }

  // ================= Event Management =================
  void registerEventHandler(String event, Function(dynamic) handler) {
    _eventHandlers.putIfAbsent(event, () => []);
    _eventHandlers[event]!.add(handler);

    if (_socket != null && _socket!.connected) {
      _socket!.on(event, handler);
    }
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _eventHandlers.clear();
  }
}
