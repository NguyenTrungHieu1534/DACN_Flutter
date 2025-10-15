import 'package:flutter/material.dart';

import 'package:just_audio/just_audio.dart';
import '../models/songs.dart';
import '../services/api_history.dart';

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

  final HistoryService _historyService = HistoryService();

  Duration get position => _position;
  Duration get duration => _duration;

  Future<void> playSong(Songs song) async {
    if (song.url.isEmpty) {
      debugPrint("Lỗi: Bài hát ${song.title} không có URL để phát!");
      return;
    }

    currentPlaying = song;

    try {
      // Thử phát mp3Url trước
      await _audioPlayer.setUrl(Uri.encodeFull(song.mp3Url));
      // Lưu vào lịch sử trước khi phát (không block nếu lỗi)
      try {
        await _historyService.addHistory(song.title, song.artist, song.id);
        debugPrint("Đã lưu lịch sử: ${song.title}");
      } catch (historyError) {
        debugPrint("Không thể lưu lịch sử: $historyError");
      }
      _audioPlayer.play();
      debugPrint("Đang phát MP3: ${song.mp3Url}");
      isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Lỗi khi phát bài ${song.title}: $e");
      print("Thử fallback sang FLAC gốc...");
      try {
        await _audioPlayer.setUrl(Uri.encodeFull(song.url));
        // Lưu vào lịch sử trước khi phát (không block nếu lỗi)
        try {
          await _historyService.addHistory(song.title, song.artist, song.id);
          debugPrint("Đã lưu lịch sử (fallback): ${song.title}");
        } catch (historyError) {
          debugPrint("Không thể lưu lịch sử (fallback): $historyError");
        }
        _audioPlayer.play();
        debugPrint("Fallback sang FLAC gốc: ${song.url}");
      } catch (e2) {
        debugPrint("url ngu: ${song.url}");
        debugPrint("Vẫn lỗi khi phát FLAC: $e2");
      }
    }
  }

  void pauseSong() {
    _audioPlayer.pause();
    isPlaying = false;
    notifyListeners();
  }

  void togglePlayPause() {
    if (isPlaying) {
      pauseSong();
    } else if (currentPlaying != null) {
      // Lưu lịch sử trước khi phát (không chặn)
      _historyService
          .addHistory(currentPlaying!.title, currentPlaying!.artist, currentPlaying!.id)
          .catchError((e) {
        debugPrint("Không thể lưu lịch sử khi toggle: $e");
      });
      _audioPlayer.play();
      isPlaying = true;
    }
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
