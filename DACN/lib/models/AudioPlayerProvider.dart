import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:music_login/screens/home_screen.dart';
import 'package:music_login/screens/login_screen.dart';
import 'package:music_login/screens/forgot_password_screen.dart';
import 'package:music_login/screens/verify_otp_screen.dart';
import 'package:music_login/screens/reset_password_screen.dart';
import 'package:music_login/screens/search_screen.dart';
import 'package:music_login/screens/fav_screen.dart';
import 'package:music_login/screens/user_screen.dart';
import 'package:just_audio/just_audio.dart';
import '../models/songs.dart';

class AudioPlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Songs? currentPlaying;

  Future<void> playSong(Songs song) async {
    currentPlaying = song;
    await _audioPlayer.setUrl(song.url);
    _audioPlayer.play();
    isPlaying = true;
    notifyListeners();
  }

  void pauseSong() {
    _audioPlayer.pause();
    isPlaying = false;
    notifyListeners();
  }

  void togglePlayPause() {
    if (isPlaying)
      pauseSong();
    else
      _audioPlayer.play();
    notifyListeners();
  }
}
