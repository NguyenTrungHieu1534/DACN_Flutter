import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../services/socket_service.dart';
import 'package:flutter/material.dart';
import '../screens/block_screen.dart';
import '/main.dart';
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;

  void connect(String userId) {
    if (socket != null && socket!.connected) return;

    socket = IO.io('https://backend-dacn-9l4w.onrender.com', {
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket!.connect();

    socket!.onConnect((_) {
      print('Socket connected: ${socket!.id}');
      socket!.emit('register', userId);
    });

    socket!.on('blocked', (data) {
      print('🚫 Bị chặn: ${data['message']}');
      Navigator.pushAndRemoveUntil(
        navigatorKey.currentContext!,
        MaterialPageRoute(
          builder: (_) => BlockedScreen(message: data['message']),
        ),
        (_) => false,
      );
    });

    socket!.onDisconnect((_) {
      print('Socket disconnected');
    });
  }

  void emit(String event, dynamic data) {
    socket?.emit(event, data);
  }

  void on(String event, Function(dynamic) handler) {
    socket?.on(event, handler);
  }

  void disconnect() {
    socket?.disconnect();
    socket = null;
  }
}
