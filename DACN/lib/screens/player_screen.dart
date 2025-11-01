import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/songs.dart';
import 'package:provider/provider.dart';
import '../models/AudioPlayerProvider.dart';
import 'dart:math' as math;
import 'dart:async';
import '../widgets/waveform_progress_bar.dart';
import '../services/api_lyrics.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    this.song,
    this.title,
    this.subtitle,
    this.imageUrl,
    this.heroTag,
  });

  final Songs? song;
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final Object? heroTag;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  Timer? _seekIgnoreTimer;
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<Duration?> _durationSub;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _lyrics;
  String? _lyricsUrl;
  bool _isLoadingLyrics = true;
  String? _lyricsError;
  WebViewController? _webController;
void _showPlaylistModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Cho phép modal Sheet tràn màn hình
      backgroundColor: Colors.transparent, // Nền trong suốt để hiển thị Blur
      builder: (context) {
        // Sử dụng Consumer để lắng nghe cập nhật Playlist (vd: khi Next/Previous)
        return Consumer<AudioPlayerProvider>(
          builder: (context, player, _) {
            final playlist = player.currentPlaylist;
            final currentIndex = player.currentIndex;

            return ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Áp dụng hiệu ứng làm mờ
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.85, // Chiếm 85% màn hình
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7), // Màu nền tối mờ
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: _buildPlaylistContent(context, player, playlist, currentIndex),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // === 🆕 WIDGET HIỂN THỊ NỘI DUNG PLAYLIST ===
  Widget _buildPlaylistContent(
    BuildContext context,
    AudioPlayerProvider player,
    List<Songs> playlist,
    int currentIndex,
  ) {
    if (playlist.isEmpty) {
      return Center(
        child: Text(
          'Danh sách phát rỗng.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Danh sách đang phát (${playlist.length} bài)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: playlist.length,
            itemBuilder: (context, index) {
              final song = playlist[index];
              final isCurrent = index == currentIndex;

              return ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(song.thumbnail),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: isCurrent
                      ? const Center(
                          child: Icon(Icons.music_note, color: Colors.white, size: 28),
                        )
                      : null,
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrent ? Theme.of(context).colorScheme.primary : Colors.white,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  song.artist,
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w300,
                  ),
                ),
                trailing: isCurrent ? const Icon(Icons.bar_chart, color: Colors.white) : null,
                onTap: () {
                  // Chơi bài hát được chọn từ Playlist
                  player.setNewPlaylist(playlist, index);
                  Navigator.pop(context); // Đóng modal
                },
              );
            },
          ),
        ),
      ],
    );
  }
  @override
  void initState() {
    super.initState();
    final player = Provider.of<AudioPlayerProvider>(context, listen: false);

    LyricsService lyricsService = LyricsService();
    _positionSub = player.positionStream.listen((pos) {
      if (_seekIgnoreTimer?.isActive == true) return;
      if (mounted) setState(() => _currentPosition = pos);
    });

    _durationSub = player.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _totalDuration = dur);
    });

    _loadLyrics(lyricsService);
  }

  Future<void> _loadLyrics(LyricsService lyricsService) async {
    setState(() {
      _isLoadingLyrics = true;
      _lyricsError = null;
    });

    try {
      int attempts = 0;
      const maxAttempts = 10;
      const delaySeconds = 3;

      Map<String, dynamic>? data;

      while (attempts < maxAttempts) {
        data = await lyricsService.fetchLyrics(
          songId: widget.song?.id ?? '',
          artist: widget.song?.artist ?? '',
          title: widget.song?.title ?? '',
        );

        if (!mounted) return;

        final lyrics = data?["lyrics"]?.toString().trim();

        if (lyrics != null && lyrics.isNotEmpty && lyrics.length > 20) {
          setState(() {
            _lyrics = lyrics;
          });
          break;
        }

        if (data?["processing"] == true) {
          await Future.delayed(const Duration(seconds: delaySeconds));
          attempts++;
        } else {
          break;
        }
      }

      if (_lyrics == null || _lyrics!.trim().length <= 20 || data == false) {
        final urlData = await lyricsService.fetchLyricsURL(
          artist: widget.song?.artist ?? '',
          title: widget.song?.title ?? '',
        );

        if (!mounted) return;

        if (urlData != null && urlData["url"] != null) {
          _lyricsUrl = urlData["url"];
          await _initWebController(_lyricsUrl!);
        } else {
          setState(() {
            _lyricsError = "Không tìm thấy lời bài hát.";
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _lyricsError = "Lỗi khi tải lyric: $error";
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingLyrics = false);
    }
  }

  // PlayerScreen.dart
// Thay thế TOÀN BỘ nội dung của hàm build hiện tại

@override
Widget build(BuildContext context) {
  // 🚨 BỌC TOÀN BỘ UI BẰNG CONSUMER
  return Consumer<AudioPlayerProvider>(
    builder: (context, player, child) {
      // 1. LẤY DỮ LIỆU BÀI HÁT TỪ PROVIDER
      final song = player.currentPlaying ?? widget.song;

      if (song == null) {
        return const Scaffold(
          body: Center(
            child: Text("Không có bài hát nào đang phát", style: TextStyle(color: Colors.white)),
          ),
        );
      }
      
      // 2. KHAI BÁO BIẾN HIỂN THỊ (SỬ DỤNG DỮ LIỆU TỪ 'song' MỚI)
      final displayImage = song.thumbnail ?? widget.imageUrl;
      final displayTitle = song.title ?? widget.title ?? 'Unknown Title';
      final displaySubtitle = song.artist ?? widget.subtitle ?? '';

      // 3. CẤU TRÚC UI
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: (displayImage != null && displayImage.isNotEmpty)
                  ? Image.network(
                      displayImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.black),
                    )
                  : Container(color: Colors.black),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: Colors.white, size: 30),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.queue_music_rounded,
                                color: Colors.white, size: 24),
                            onPressed: () => _showPlaylistModal(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_horiz, color: Colors.white),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 🚨 Hiển thị Ảnh/Hero Art
                    (displayImage != null && displayImage.isNotEmpty)
                        ? Hero(
                            tag: song.id ?? widget.heroTag ?? displayImage, // Dùng ID mới
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.7,
                              height: MediaQuery.of(context).size.width * 0.7,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 25,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(displayImage, fit: BoxFit.cover),
                              ),
                            ),
                          )
                        : Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: MediaQuery.of(context).size.width * 0.7,
                            decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.album, size: 80, color: Colors.white54),
                          ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🚨 Tiêu đề (Updated)
                          Text(
                            displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  shadows: const [
                                    Shadow(
                                      offset: Offset(0, 4),
                                      blurRadius: 8,
                                      color: Colors.black45,
                                    ),
                                  ],
                                ),
                          ),
                          const SizedBox(height: 8),
                          // 🚨 Nghệ sĩ (Updated)
                          Text(
                            displaySubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.95),
                                  fontWeight: FontWeight.w600,
                                  shadows: const [
                                    Shadow(
                                      offset: Offset(0, 3),
                                      blurRadius: 6,
                                      color: Colors.black38,
                                    ),
                                  ],
                                ),
                          ),
                          const SizedBox(height: 24),

                          // Waveform + time row (Giữ nguyên)
                          Column(
                            children: [
                              WaveformProgressBar(
                                progress: _currentPosition,
                                total: _totalDuration,
                                onSeek: (duration) async {
                                  final player = Provider.of<AudioPlayerProvider>(context, listen: false);
                                  await player.seek(duration);
                                  _seekIgnoreTimer?.cancel();
                                  _seekIgnoreTimer = Timer(const Duration(milliseconds: 400), () {});
                                },
                                waveColor: Colors.white38,
                                progressColor: Colors.white,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatTime(_currentPosition),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                    Text(_formatTime(_totalDuration),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          // Controls row (Đã được sửa lỗi và cập nhật)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Nút SHUFFLE
                              IconButton(
                                icon: Icon(
                                  Icons.shuffle,
                                  color: player.isShuffleEnabled
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white70,
                                ),
                                onPressed: player.toggleShuffle,
                              ),

                              // Nút PREVIOUS
                              IconButton(
                                icon: const Icon(Icons.skip_previous_rounded),
                                color: Colors.white.withOpacity(0.9),
                                iconSize: 48,
                                onPressed: player.previousSong,
                              ),

                              // Nút Play/Pause lớn
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.95),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.9),
                                      blurRadius: 30,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(player.isPlaying ? Icons.pause : Icons.play_arrow),
                                  color: Colors.black87,
                                  iconSize: 54,
                                  onPressed: () async {
                                    // Nếu đã có playlist, phát theo thứ tự từ đầu
                                    if (player.currentPlaylist.isNotEmpty) {
                                      if (!player.isPlaying || player.currentIndex != 0) {
                                        await player.setNewPlaylist(player.currentPlaylist, 0);
                                      } else {
                                        await player.togglePlayPause();
                                      }
                                    } else {
                                      await player.togglePlayPause();
                                    }
                                  },
                                ),
                              ),

                              // Nút NEXT
                              IconButton(
                                icon: const Icon(Icons.skip_next_rounded),
                                color: Colors.white.withOpacity(0.9),
                                iconSize: 48,
                                onPressed: player.nextSong,
                              ),

                              // Nút REPEAT
                              IconButton(
                                icon: Icon(
                                  player.repeatMode == RepeatMode.repeatSong
                                      ? Icons.repeat_one
                                      : Icons.repeat,
                                  color: player.repeatMode != RepeatMode.off
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.white70,
                                ),
                                onPressed: player.toggleRepeat,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: _buildLyricsWidget(),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  Future<void> _initWebController(String url) async {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            await _webController?.runJavaScript(r'''
              // Tìm container chính chứa lời bài hát
              const lyricsContainer = document.querySelector('[data-lyrics-container]');

              if (lyricsContainer) {
                // Lấy nội dung HTML của container lời bài hát
                const lyricsHtml = lyricsContainer.innerHTML;

                // Thay thế toàn bộ nội dung của <body> bằng lời bài hát
                document.body.innerHTML = lyricsHtml;

                // Áp dụng style cho body để có nền đen, chữ trắng và cuộn được
                document.body.style.backgroundColor = '#000000';
                document.body.style.color = '#ffffff';
                document.body.style.fontSize = '16px';
                document.body.style.lineHeight = '1.6';
                document.body.style.padding = '16px';
                document.body.style.margin = '0';
                document.body.style.overflowX = 'hidden';
                document.body.style.overflowY = 'scroll';

                // Thêm style cho thanh cuộn để dễ nhìn hơn trên nền tối
                const style = document.createElement('style');
                style.innerHTML = `
                  ::-webkit-scrollbar {
                    width: 10px;
                  }
                  ::-webkit-scrollbar-thumb {
                    background: #666;
                    border-radius: 5px;
                  }
                  ::-webkit-scrollbar-thumb:hover {
                    background: #aaa;
                  }
                  ::-webkit-scrollbar-track {
                    background: #111;
                  }
                `;
                document.head.appendChild(style);
              } else {
                // Fallback: nếu không tìm thấy, ẩn các phần tử không cần thiết
                document.querySelectorAll('header, footer, .Header, .Footer, .RightSidebar, .ad_unit').forEach(e => e.remove());
              }
            ''');

            if (mounted) {
              setState(() => _isLoadingLyrics = false);
            }
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _lyricsError = "Không thể tải lời bài hát.";
                _isLoadingLyrics = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  Widget _buildLyricsWidget() {
    if (_isLoadingLyrics) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white70));
    } else if (_lyricsUrl != null && _webController != null) {
      return SizedBox(
        height: 400,
        child: WebViewWidget(
          controller: _webController!,
          gestureRecognizers: {
            Factory<VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer(),
            ),
          },
        ),
      );
    } else if (_lyricsError != null) {
      return Text(
        _lyricsError!,
        style:
            const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      );
    } else if (_lyrics == null || _lyrics!.isEmpty) {
      return const Text(
        'Chưa có lời bài hát cho bài này.',
        style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      );
    } else {
      return Text(
        _lyrics!,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
      );
    }
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _positionSub.cancel();
    _durationSub.cancel();
    _seekIgnoreTimer?.cancel();
    super.dispose();
  }
}
