import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import '../models/songs.dart';
import '../services/api_history.dart';
import '../services/api_songs.dart';
import '../models/audio_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' show window;
import 'dart:async';
import 'dart:math';

enum RepeatMode { off, repeatSong, repeatPlaylist }

class AudioPlayerProvider extends ChangeNotifier {
  List<Songs> _currentPlaylist = [];
  int _currentIndex = -1;
  bool _isShuffleEnabled = false;
  RepeatMode _repeatMode = RepeatMode.off;
  List<Songs> get currentPlaylist => _currentPlaylist;
  int get currentIndex => _currentIndex;
  bool get isShuffleEnabled => _isShuffleEnabled;
  RepeatMode get repeatMode => _repeatMode;
  Songs? get currentPlaying =>
      (_currentIndex >= 0 && _currentIndex < _currentPlaylist.length)
          ? _currentPlaylist[_currentIndex]
          : null;
  final AudioHandler audioHandler;
  bool isPlaying = false;
  
  final HistoryService _historyService = HistoryService();
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero; 
  bool isDarkMode = false; 

  AudioPlayerProvider({required this.audioHandler}) {
    _loadThemeSettings();
    audioHandler.playbackState.listen((state) {
      debugPrint(
          '[Provider] playbackState: playing=${state.playing}, processing=${state.processingState}, position=${state.position.inMilliseconds}');
      isPlaying = state.playing;
      if (state.processingState == AudioProcessingState.completed) {
        _position = Duration.zero;
        nextSong(isAutoAdvance: true); 
      } else if (state.processingState == AudioProcessingState.ready) {
        _position = state.position;
      }
      notifyListeners();
    });
    audioHandler.mediaItem.listen((item) {
      debugPrint('[Provider] mediaItem: id=${item?.id}, duration=${item?.duration}');
      _duration = item?.duration ?? Duration.zero;
      notifyListeners();
    });
    audioHandler.playbackState.listen((state) {
      if (state.playing || state.processingState == AudioProcessingState.ready) {
        _position = state.position;
      }
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
  MediaItem _createMediaItem(Songs song) {
    return MediaItem(
      id: song.id.toString(),
      title: song.title,
      artist: song.artist,
      album: song.album,
      artUri: Uri.parse(song.thumbnail),
      extras: {
        'displayTitle': song.title,
        'displaySubtitle': song.artist,
        'artworkType': 'GRADIENT',
        'backgroundColor': '#121212',
        'gradientStart': '#1E1E1E',
        'gradientEnd': '#2D2D2D',
        'accentColor': '#EF6C00',
        'secondaryColor': '#FF9800',
        'displayDescription': song.album,
        'textColor': '#FAFAFA',
        'artworkRadius': '8.0',
        'elevation': '2.0',
      },
    );
  }
  Stream<Duration> get positionStream {
    return audioHandler.playbackState.map((state) => state.position).distinct();
  }

  Stream<Duration?> get durationStream {
    return audioHandler.mediaItem.map((item) => item?.duration).distinct();
  }

  Future<void> setNewPlaylist(List<Songs> newPlaylist, int startIndex) async {
    if (newPlaylist.isEmpty || startIndex < 0 || startIndex >= newPlaylist.length) return;

    _currentPlaylist = newPlaylist;
    _currentIndex = startIndex;
    notifyListeners();

    await _playCurrentSong();
  }
  Future<void> _playCurrentSong() async {
    var selectedSong = currentPlaying;
    if (selectedSong == null) return;
    if (selectedSong.url.isEmpty && selectedSong.mp3Url.isEmpty) {
      try {
        final songUrl = await SongService.fetchSongUrl(selectedSong.id);
        selectedSong = selectedSong.copyWith(url: songUrl);
        _currentPlaylist[_currentIndex] = selectedSong;
        notifyListeners();
      } catch (e) {
        debugPrint('Lỗi khi lấy URL bài hát: $e');
        return;
      }
    }

    final mediaItem = _createMediaItem(selectedSong);

    try {
      final handler = audioHandler as MyAudioHandler;
      await handler.setMediaItem(mediaItem);
      
      Uri? uriToPlay;
      if (selectedSong.mp3Url.isNotEmpty) {
        try {
          uriToPlay = Uri.parse(selectedSong.mp3Url);
        } catch (e) {
          debugPrint('Không thể parse mp3Url: ${selectedSong.mp3Url}');
        }
      }
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
      await handler.setAudioSource(mediaItem, uriToPlay);
      _position = Duration.zero; 
      await handler.seek(Duration.zero);
      await handler.play();
      try {
        await _historyService.addHistory(
          selectedSong.title,
          selectedSong.artist,
          selectedSong.album,
          selectedSong.id,
        );
      } catch (e) {
        debugPrint('Lỗi khi thêm vào lịch sử: $e');
      }

    } catch (e) {
      debugPrint('Lỗi khi phát bài ${selectedSong.title}: $e');
    }
  }
  @override
  Future<void> playSong([Songs? song]) async {
    final selectedSong = song ?? currentPlaying;

    if (selectedSong == null || selectedSong.url.isEmpty) return;
    if (currentPlaying?.id != selectedSong.id || _currentPlaylist.isEmpty) {
      _currentPlaylist = [selectedSong];
      _currentIndex = 0;
      notifyListeners();
    }
    if (currentPlaying?.id == selectedSong.id && isPlaying) {
      return;
    }
    
    await _playCurrentSong();

  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    notifyListeners();
  }

  void toggleRepeat() {
    _repeatMode = RepeatMode.values[
        (_repeatMode.index + 1) % RepeatMode.values.length];
    _updateAudioHandlerRepeatMode();
    
    notifyListeners();
  }
  
  void _updateAudioHandlerRepeatMode() {
    if (_repeatMode == RepeatMode.repeatSong) {
      (audioHandler as MyAudioHandler).player.setLoopMode(LoopMode.one);
    } else if (_repeatMode == RepeatMode.repeatPlaylist) {
      (audioHandler as MyAudioHandler).player.setLoopMode(LoopMode.all);
    } else {
      (audioHandler as MyAudioHandler).player.setLoopMode(LoopMode.off);
    }
  }

  void nextSong({bool isAutoAdvance = false}) async {
    if (_currentPlaylist.isEmpty) return;

    int nextIndex = _currentIndex;
    if (isAutoAdvance) {
      if (_repeatMode == RepeatMode.repeatSong) {
        await _playCurrentSong();
        return;
      }
    }

    if (_isShuffleEnabled) {
      final random = Random();
      nextIndex = random.nextInt(_currentPlaylist.length);
      if (nextIndex == _currentIndex && _currentPlaylist.length > 1) {
          nextIndex = (nextIndex + 1) % _currentPlaylist.length;
      }

    } else {
      nextIndex = (_currentIndex + 1) % _currentPlaylist.length;
    }
    if (nextIndex == 0 && _currentIndex == _currentPlaylist.length - 1) {
      if (_repeatMode == RepeatMode.off) {
        _currentIndex = nextIndex;
        await stopSong();
        return;
      } 
    }
    
    _currentIndex = nextIndex;
    notifyListeners();
    await _playCurrentSong();
  }

  void previousSong() async {
    if (_currentPlaylist.isEmpty) return;
    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    int previousIndex = _currentIndex - 1;

    if (previousIndex < 0) {
      if (_repeatMode == RepeatMode.repeatPlaylist) {
        previousIndex = _currentPlaylist.length - 1;
      } else {
        previousIndex = 0;
        await seek(Duration.zero);
        return;
      }
    }
    
    _currentIndex = previousIndex;
    notifyListeners();
    await _playCurrentSong();
  }
  @override
  Future<void> pauseSong() async {
    await audioHandler.pause();
  }

  @override
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pauseSong();
    } else if (currentPlaying != null) {
      if (_position > Duration.zero) {
        await audioHandler.seek(_position);
      }
      await audioHandler.play();
    }
  }

  @override
  Future<void> seek(Duration position) async {
    _position = position;
    notifyListeners();
    await audioHandler.seek(position);
  }

  @override
  Future<void> stopSong() async {
    await audioHandler.stop();
    isPlaying = false;
    _position = Duration.zero;
    notifyListeners();
  }
}