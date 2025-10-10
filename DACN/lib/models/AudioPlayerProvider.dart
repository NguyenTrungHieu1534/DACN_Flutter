import 'package:flutter/material.dart';

import 'package:just_audio/just_audio.dart';
import '../models/songs.dart';

class AudioPlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Songs? currentPlaying;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  AudioPlayerProvider() {
    _audioPlayer.positionStream.listen((p) {
      _position = p;
      notifyListeners();
    });
    _audioPlayer.durationStream.listen((d) {
      _duration = d ?? Duration.zero;
      notifyListeners();
    });
    _audioPlayer.playerStateStream.listen((playerState) {
      isPlaying = playerState.playing;
      notifyListeners();
    });
  }

  Duration get position => _position;
  Duration get duration => _duration;

  Future<void> playSong(Songs song) async {
    if (song.url == null || song.url!.isEmpty) {
      debugPrint("Lỗi: Bài hát ${song.title} không có URL để phát!");
      return;
    }

    currentPlaying = song;

    try {
      // Thử phát mp3Url trước
      if (song.mp3Url != null) {
        await _audioPlayer.setUrl(Uri.encodeFull(song.mp3Url!));
        _audioPlayer.play();
        debugPrint("Đang phát MP3: ${song.mp3Url}");
      } else {
        // mp3Url null → fallback
        await _audioPlayer.setUrl(Uri.encodeFull(song.url));
        _audioPlayer.play();
        debugPrint("Đang phát FLAC gốc: ${song.url}");
      }
      isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Lỗi khi phát bài ${song.title}: $e");
      if (song.mp3Url != null) {
        print("Thử fallback sang FLAC gốc...");
        try {
          await _audioPlayer.setUrl(Uri.encodeFull(song.url));
          _audioPlayer.play();
          debugPrint("Fallback sang FLAC gốc: ${song.url}");
        } catch (e2) {
          debugPrint("url ngu: ${song.url}");
          debugPrint("Vẫn lỗi khi phát FLAC: $e2");
        }
      }
    }
  }

  void pauseSong() {
    _audioPlayer.pause();
    isPlaying = false;
    notifyListeners();
  }

  void togglePlayPause() {
    if (isPlaying)
      pauseSong();
    else if (currentPlaying != null) _audioPlayer.play();
    notifyListeners();
  }

  void seek(Duration position) {
    _audioPlayer.seek(position);
  }

  void nextSong() {
    // TODO: Implement next song logic
    print("Next song");
  }

  void previousSong() {
    // TODO: Implement previous song logic
    print("Previous song");
  }
}
