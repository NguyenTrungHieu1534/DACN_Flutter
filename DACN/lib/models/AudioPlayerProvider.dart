import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../models/songs.dart';
import '../services/api_history.dart';
import '../models/audio_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' show window;
import 'dart:async';

class AudioPlayerProvider extends ChangeNotifier {
  MediaItem _createMediaItem(Songs song) {
    return MediaItem(
      id: song.id.toString(),
      title: song.title,
      artist: song.artist,
      album: song.albuml,
      artUri: Uri.parse(song.thumbnail),
      extras: {
        'displayTitle': song.title,
        'displaySubtitle': song.artist,
        'artworkType': 'GRADIENT',
        'backgroundColor': '#121212',    // Material dark theme background
        'gradientStart': '#1E1E1E',      // Slightly lighter than background
        'gradientEnd': '#2D2D2D',        // Creates depth
        'accentColor': '#EF6C00',        // Deep Orange - matches app theme
        'secondaryColor': '#FF9800',     // Orange
        'displayDescription': song.albuml,
        'textColor': '#FAFAFA',          // Slightly off-white for less eye strain
        'artworkRadius': '8.0',          // Rounded corners for artwork
        'elevation': '2.0',              // Subtle shadow
      },
    );
  }
  final AudioHandler audioHandler;
  bool isPlaying = false;
  Songs? currentPlaying;
  bool isDarkMode = false;

  final HistoryService _historyService = HistoryService();

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  AudioPlayerProvider({required this.audioHandler}) {
    _loadThemeSettings(); // Khởi tạo theme
    
    // Nghe trạng thái phát nhạc từ AudioHandler
    audioHandler.playbackState.listen((state) {
      debugPrint('[Provider] playbackState: playing=${state.playing}, processing=${state.processingState}, position=${state.position.inMilliseconds}');
      isPlaying = state.playing;
      notifyListeners();
    });

    // Nghe MediaItem để cập nhật duration
    audioHandler.mediaItem.listen((item) {
      debugPrint('[Provider] mediaItem: id=${item?.id}, duration=${item?.duration}');
      _duration = item?.duration ?? Duration.zero;
      notifyListeners();
    });

    // Nghe progress từ AudioHandler
    // ✅ FIX 🔹 Lắng nghe tiến trình phát nhạc chính xác, không reset sai
audioHandler.playbackState.listen((state) {
  // Cập nhật vị trí phát nhạc thực
  if (state.playing || state.processingState == AudioProcessingState.ready) {
    _position = state.position;
  }

  // Chỉ reset khi bài hát kết thúc hoàn toàn
  if (state.processingState == AudioProcessingState.completed) {
    _position = Duration.zero;
    isPlaying = false;
  }

  // ⚠️ KHÔNG reset ở trạng thái idle (vì stop/pause cũng dùng idle)
  notifyListeners();
});

  }

  Duration get position => _position;
  Duration get duration => _duration;

  void initState() {
    _loadThemeSettings();
    window.onPlatformBrightnessChanged = _loadThemeSettings;
  }

  Future<void> _loadThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _updateTheme(prefs.getBool('isDarkMode') ?? false);
    } catch (e) {
      debugPrint('Lỗi khi tải cài đặt theme: $e');
    }
  }

  void _updateTheme(bool isDark) {
    isDarkMode = isDark;
    if (currentPlaying != null) {
      final mediaItem = _createMediaItem(currentPlaying!);
      audioHandler.addQueueItem(mediaItem);
    }
    notifyListeners();
  }

  Future<void> playSong([Songs? song]) async {
  // Nếu không truyền tham số, dùng bài hiện tại
  final selectedSong = song ?? currentPlaying;

  if (selectedSong == null || selectedSong.url.isEmpty) return;

  currentPlaying = selectedSong;
  final mediaItem = _createMediaItem(selectedSong);

  try {
    final handler = audioHandler as MyAudioHandler;

    // Dừng bài hát đang phát nếu có
    if (handler.playbackState.value.playing &&
    currentPlaying?.id != selectedSong.id) {
  await handler.stop();
}
    await handler.addQueueItem(mediaItem);
    Uri? uriToPlay;

    // Ưu tiên sử dụng mp3Url
    if (selectedSong.mp3Url.isNotEmpty) {
      try {
        uriToPlay = Uri.parse(selectedSong.mp3Url);
      } catch (e) {
        debugPrint('Không thể parse mp3Url: ${selectedSong.mp3Url}');
      }
    }

    // Thử dùng url thông thường nếu mp3Url không khả dụng
    if (uriToPlay == null && selectedSong.url.isNotEmpty) {
      try {
        uriToPlay = Uri.parse(selectedSong.url);
      } catch (e) {
        debugPrint('Không thể parse url: ${selectedSong.url}');
      }
    }

    if (uriToPlay == null) {
      throw Exception('Không có URL hợp lệ để phát nhạc');
    }

    // Cài đặt nguồn audio
    await handler.setAudioSource(mediaItem, uriToPlay);

    // Thêm vào lịch sử
    try {
      await _historyService.addHistory(
        selectedSong.title,
        selectedSong.artist,
        selectedSong.albuml,
        selectedSong.id,
      );
    } catch (e) {
      debugPrint('Lỗi khi thêm vào lịch sử: $e');
    }

    // Phát nhạc
    if (_position > Duration.zero && _position < _duration) {
  await handler.seek(_position);
}
    await handler.play();
  } catch (e) {
    debugPrint('Lỗi khi phát bài ${selectedSong.title}: $e');
  }
}




  Future<void> pauseSong() async {
    await audioHandler.pause();
  }

  Future<void> togglePlayPause() async {
  if (isPlaying) {
    await pauseSong();
  } else if (currentPlaying != null) {
    // 🔹 Nếu đang dừng giữa chừng, seek lại vị trí cũ
    if (_position > Duration.zero) {
      await audioHandler.seek(_position);
    }
    await audioHandler.play();
  }
}

  Future<void> seek(Duration position) async {
  _position = position;
  notifyListeners();
  await audioHandler.seek(position);
}

  Future<void> stopSong() async {
  await audioHandler.stop();
  isPlaying = false;
  notifyListeners();
}
  void nextSong() {
    print("Next song");
  }

  void previousSong() {
    print("Previous song");
  }
  Stream<Duration> get positionStream {
  return audioHandler.playbackState
      .map((state) => state.position)
      .distinct();
}

Stream<Duration?> get durationStream {
  return audioHandler.mediaItem.map((item) => item?.duration).distinct();
}
}
