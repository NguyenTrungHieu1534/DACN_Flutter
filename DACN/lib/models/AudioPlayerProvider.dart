import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../models/songs.dart';
import '../services/api_history.dart';
import '../models/audio_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' show window;

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

  Future<void> playSong(Songs song) async {
    if (song.url.isEmpty) return;

    currentPlaying = song;
    final mediaItem = _createMediaItem(song);

    try {
      final handler = audioHandler as MyAudioHandler;
      
      // Dừng bài hát đang phát nếu có
      if (handler.playbackState.value.playing) {
        await handler.stop();
      }

      // Thêm bài hát mới vào queue
      await handler.addQueueItem(mediaItem);

      // Tìm URL hợp lệ để phát nhạc
      Uri? uriToPlay;
      
      // Ưu tiên sử dụng mp3Url
      if (song.mp3Url.isNotEmpty) {
        try {
          uriToPlay = Uri.parse(song.mp3Url);
        } catch (e) {
          debugPrint('Không thể parse mp3Url: ${song.mp3Url}');
        }
      }
      
      // Thử dùng url thông thường nếu mp3Url không khả dụng
      if (uriToPlay == null && song.url.isNotEmpty) {
        try {
          uriToPlay = Uri.parse(song.url);
        } catch (e) {
          debugPrint('Không thể parse url: ${song.url}');
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
          song.title, 
          song.artist, 
          song.albuml, 
          song.id
        );
      } catch (e) {
        debugPrint('Lỗi khi thêm vào lịch sử: $e');
      }
      
      // Phát nhạc
      await handler.play();
    } catch (e) {
      debugPrint('Lỗi khi phát bài ${song.title}: $e');
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
