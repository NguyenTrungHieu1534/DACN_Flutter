import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../models/songs.dart';
import '../services/api_history.dart';
import '../models/audio_handler.dart';

class AudioPlayerProvider extends ChangeNotifier {
  final AudioHandler audioHandler;
  bool isPlaying = false;
  Songs? currentPlaying;

  final HistoryService _historyService = HistoryService();

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  AudioPlayerProvider({required this.audioHandler}) {
    // Nghe trạng thái phát nhạc từ AudioHandler
    audioHandler.playbackState.listen((state) {
      isPlaying = state.playing;
      notifyListeners();
    });

    // Nghe MediaItem để cập nhật duration
    audioHandler.mediaItem.listen((item) {
      _duration = item?.duration ?? Duration.zero;
      notifyListeners();
    });

    // Nghe progress từ AudioHandler
    audioHandler.playbackState.listen((state) {
      _position = state.position;
      notifyListeners();
    });
  }

  Duration get position => _position;
  Duration get duration => _duration;

  Future<void> playSong(Songs song) async {
    if (song.url.isEmpty) return;

    currentPlaying = song;

    final mediaItem = MediaItem(
      id: song.id.toString(),
      title: song.title,
      artist: song.artist,
      album: song.albuml,
      artUri: Uri.parse(song.thumbnail),
      // duration: song.duration ?? Duration.zero,
    );
    audioHandler.addQueueItem(mediaItem);
    // await audioHandler.setMediaItem(mediaItem);
    try {
      if (audioHandler.playbackState.value.playing) {
        await audioHandler.stop();
      }
      Uri? uriToPlay;
      String logMessage = '';
      if (uriToPlay == null && song.mp3Url.isNotEmpty) {
        try {
          uriToPlay = Uri.parse(song.mp3Url);
          logMessage = 'dang play mp3 url';
        } catch (_) {
          // Nếu MP3 URL cũng không hợp lệ
        }
      }

      // 2. XỬ LÝ KHI KHÔNG CÓ URI HỢP LỆ
      if (uriToPlay == null) {
        throw Exception("Tất cả các URL đều không hợp lệ");
      }
      await (audioHandler as MyAudioHandler)
          .setAudioSource(mediaItem, uriToPlay);
      try {
        await _historyService.addHistory(
            song.title, song.artist, song.albuml, song.id);
      } catch (_) {}
      await audioHandler.play();
    } catch (e) {
      debugPrint("Lỗi khi phát bài ${song.title}: $e");
    }
  }

  Future<void> pauseSong() async {
    await audioHandler.pause();
  }

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pauseSong();
    } else if (currentPlaying != null) {
      await audioHandler.play();
    }
  }

  Future<void> seek(Duration position) async {
    await audioHandler.seek(position);
  }

  Future<void> stopSong() async {
    await audioHandler.stop();
  }

  // Nếu muốn, có thể thêm next/previous logic
  void nextSong() {
    print("Next song");
  }

  void previousSong() {
    print("Previous song");
  }
}
