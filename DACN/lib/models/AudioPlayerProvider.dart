import 'package:flutter/material.dart';

import 'package:just_audio/just_audio.dart';
import '../models/songs.dart';
import '../services/api_history.dart';
import 'package:audio_service/audio_service.dart';

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
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(song.mp3Url),
          tag: MediaItem(
            id: song.id.toString(),
            title: song.title,
            artist: song.artist,
            artUri: Uri.parse(song.thumbnail),
          ),
        ),
      );
      try {
        await _historyService.addHistory(
            song.title, song.artist, song.albuml, song.id);
      } catch (_) {}

      await _audioPlayer.play();
      isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Lỗi khi phát MP3, thử sang FLAC...");

      try {
        await _audioPlayer.setAudioSource(
          AudioSource.uri(
            Uri.parse(song.url),
            tag: MediaItem(
              id: song.id.toString(),
              title: song.title,
              artist: song.artist,
              artUri: Uri.parse(song.thumbnail),
            ),
          ),
        );

        await _audioPlayer.play();
        isPlaying = true;
        notifyListeners();
      } catch (e2) {
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
          .addHistory(currentPlaying!.title, currentPlaying!.artist,
              currentPlaying!.id, currentPlaying!.albuml)
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
