import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/songs.dart';
import 'package:provider/provider.dart';
import '../models/AudioPlayerProvider.dart';
import 'dart:math' as math;
import 'dart:async';
import '../widgets/waveform_progress_bar.dart'; // Import widget mới

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
  @override
  void initState() {
    super.initState();
    final player = Provider.of<AudioPlayerProvider>(context, listen: false);

// Lắng nghe stream thời gian phát nhạc
    _positionSub = player.positionStream.listen((pos) {
      if (_seekIgnoreTimer?.isActive == true) return;
      if (mounted) setState(() => _currentPosition = pos);
    });

// Lắng nghe stream tổng thời lượng bài hát
    _durationSub = player.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _totalDuration = dur);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Resolve display fields (supports either passing a Songs object or individual fields)
    final displayImage = widget.song?.thumbnail ?? widget.imageUrl;
    final displayTitle = widget.song?.title ?? widget.title ?? 'Unknown Title';
    final displaySubtitle = widget.song?.artist ?? widget.subtitle ?? '';

    return Scaffold(
      body: Stack(
        children: [
          // Nền blur từ ảnh bìa
          Positioned.fill(
            child: (displayImage != null && displayImage.isNotEmpty)
                ? Image.network(
                    displayImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
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
                        icon: const Icon(Icons.more_horiz, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 1),

                // Ảnh bìa album lớn ở giữa
                if (displayImage != null && displayImage.isNotEmpty)
                  Hero(
                    tag: widget.song?.id ?? widget.heroTag ?? displayImage,
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
                else
                  Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.width * 0.7,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.album,
                        size: 80, color: Colors.white54),
                  ),

                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                      Text(
                        displaySubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      // Thanh tiến trình dạng sóng
                      Column(
                        children: [
                          WaveformProgressBar(
                            progress: _currentPosition,
                            total: _totalDuration,
                            onSeek: (duration) async {
                              final player = Provider.of<AudioPlayerProvider>(
                                  context,
                                  listen: false);
                              await player.seek(duration);
                              // Tạm thời bỏ qua các update từ stream để tránh thanh trượt "nhảy"
                              _seekIgnoreTimer?.cancel();
                              _seekIgnoreTimer = Timer(
                                  const Duration(milliseconds: 400), () {});
                            },
                            waveColor: Colors.white38,
                            progressColor: Colors.white,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
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

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shuffle),
                            color: Colors.white70,
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded),
                            color: Colors.white.withOpacity(0.9),
                            iconSize: 48,
                            onPressed: () {},
                          ),

                          // Nút Play/Pause lớn hơn
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
                            child: Consumer<AudioPlayerProvider>(
                              builder: (context, player, _) {
                                final isPlaying = player.isPlaying;
                                return IconButton(
                                  icon: Icon(isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow),
                                  color: Colors.black87,
                                  iconSize: 54,
                                  onPressed: () async {
                                    final currentSong = widget.song;
                                    // Nếu chưa có bài hát nào đang phát
                                    if (currentSong == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Không có bài hát để phát')),
                                      );
                                      return;
                                    }
                                    // Nếu đã có bài đang phát, toggle Play/Pause
                                    if (player.currentPlaying != null &&
                                        player.currentPlaying!.id ==
                                            currentSong.id) {
                                      await player.togglePlayPause();
                                    } else {
                                      // Nếu là bài mới → phát bài đó
                                      await player.playSong(currentSong);
                                    }
                                  },
                                );
                              },
                            ),
                          ),

                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded),
                            color: Colors.white.withOpacity(0.9),
                            iconSize: 48,
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.repeat),
                            color: Colors.white70,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          )
        ],
      ),
    );
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
