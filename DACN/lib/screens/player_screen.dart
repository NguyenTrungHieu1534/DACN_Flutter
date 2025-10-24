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

  @override
  Widget build(BuildContext context) {
    final displayImage = widget.song?.thumbnail ?? widget.imageUrl;
    final displayTitle = widget.song?.title ?? widget.title ?? 'Unknown Title';
    final displaySubtitle = widget.song?.artist ?? widget.subtitle ?? '';

    return Scaffold(
      body: Stack(
        children: [
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
                          icon:
                              const Icon(Icons.more_horiz, color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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

                        // 🔹 Dãy nút điều khiển nhạc
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
                                      if (currentSong == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Không có bài hát để phát')));
                                        return;
                                      }
                                      if (player.currentPlaying != null &&
                                          player.currentPlaying!.id ==
                                              currentSong.id) {
                                        await player.togglePlayPause();
                                      } else {
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
                  const SizedBox(height: 25),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
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
  }

  Future<void> _initWebController(String url) async {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));
  }

  Widget _buildLyricsWidget() {
    if (_isLoadingLyrics) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white70));
    } else if (_lyricsUrl != null && _webController != null) {
      return Expanded(
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: WebViewWidget(controller: _webController!),
          ),
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
