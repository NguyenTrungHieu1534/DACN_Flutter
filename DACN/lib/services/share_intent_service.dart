import 'package:flutter/services.dart';

class ShareIntentService {
  static const MethodChannel _channel = MethodChannel('com.musiclogin/share');

  static Future<void> shareText(String text, {String? subject}) async {
    if (text.isEmpty) return;
    await _channel.invokeMethod<void>('shareText', {
      'text': text,
      'subject': subject,
    });
  }
}





