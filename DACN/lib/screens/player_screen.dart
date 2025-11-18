import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/songs.dart';
import 'package:provider/provider.dart';
import '../models/AudioPlayerProvider.dart';
import 'dart:async';
import '../widgets/waveform_progress_bar.dart';
import '../services/api_lyrics.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import '../widgets/comment_section.dart'; 
import '../services/api_favsongs.dart';
import '../services/api_playlist.dart';
import '../services/api_repost.dart';
import '../services/share_intent_service.dart';
import '../services/api_songs.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
 
import '../constants/deep_link_config.dart';


class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    this.song,
    this.title,
    this.subtitle,
    this.imageUrl,
    this.heroTag,
    this.showBackButton = false,
  });

  final Songs? song;
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final Object? heroTag;
  final bool showBackButton;

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
  late TabController _tabController; 
  final FavoriteService favoriteService = FavoriteService();
  final ApiPlaylist apiPlaylist = ApiPlaylist();
  final RepostService repostService = RepostService();
  void _showPlaylistModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer<AudioPlayerProvider>(
          builder: (context, player, _) {
            final playlist = player.currentPlaylist;
            final currentIndex = player.currentIndex;

            return ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: _buildPlaylistContent(
                      context, player, playlist, currentIndex),
                ),
              ),
            );
          },
        );
      },
    );
  }

Future<void> _showAddToPlaylistDialog(Songs song) async {
    if (!mounted) return;
    final localContext = context;

    showDialog(
      context: localContext,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final playlists = await apiPlaylist.getPlaylistsByUser();

      if (!mounted) return;
      Navigator.of(localContext, rootNavigator: true).pop();

      if (!mounted) return;

      final result = await showDialog<String>(
        context: localContext,
        builder: (_) {
          return AlertDialog(
            backgroundColor: Theme.of(localContext).dialogBackgroundColor,
            title: Text(
              'Thêm vào Playlist',
              style: TextStyle(
                color: Theme.of(localContext).textTheme.titleLarge?.color,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (playlists.isEmpty)
                    const Text('Bạn chưa có playlist nào. Hãy tạo một cái mới!'),
                  ...playlists.map((p) => ListTile(
                        title: Text(p.name),
                        onTap: () async {
                          Navigator.of(localContext, rootNavigator: true).pop();
                          await _addSongToExistingPlaylist(song, p.id);
                        },
                      )),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(localContext, rootNavigator: true).pop(),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(localContext, rootNavigator: true)
                    .pop('new_playlist'),
                child: const Text('Tạo Playlist Mới'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      if (result == 'new_playlist') {
        await _handleCreateNewPlaylist(song);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(localContext, rootNavigator: true).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(localContext).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách playlist: $e')),
      );
    }
  }

Future<void> _addSongToExistingPlaylist(Songs song, String playlistId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final success =
        await ApiPlaylist.addSongToPlaylist(token, playlistId, song);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Đã thêm bài hát vào playlist!'
              : 'Thêm bài hát thất bại.'),
        ),
      );
    }
  }

  Future<void> _handleCreateNewPlaylist(Songs song) async {
    final nameController = TextEditingController();
    final newPlaylistName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        title: Text(
          'Tạo Playlist Mới',
          style:
              TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: "Tên playlist",
            hintStyle: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.6)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Tạo'),
          ),
        ],
      ),
    );

    if (newPlaylistName != null && newPlaylistName.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final newPlaylist =
          await ApiPlaylist.createPlaylist(token, newPlaylistName, '');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(newPlaylist != null
                  ? 'Đã tạo playlist "${newPlaylistName}"!'
                  : 'Tạo playlist mới thất bại.')),
        );
      }
      if (newPlaylist != null) {
        _showAddToPlaylistDialog(song);
      }
    }
  }

Future<void> _showPlayerOptions(BuildContext buttonContext, Songs song) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  // Lấy bài hát đang phát hiện tại
  final audioProvider = Provider.of<AudioPlayerProvider>(context, listen: false);
  final currentSong = audioProvider.currentPlaying;

  if (currentSong == null) return;
  final songWithFullData = currentSong.copyWith(thumbnail: song.thumbnail); // Đảm bảo có thumbnail

  // 1. KIỂM TRA ĐĂNG NHẬP
  if (token == null || token.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vui lòng đăng nhập để sử dụng tính năng này 🔒'), duration: Duration(seconds: 2)));
    // (Thêm logic điều hướng đến LoginScreen nếu cần)
    return;
  }
  
  // 2. HIỂN THỊ POPUP MENU
  final result = await showMenu<String>(
    context: buttonContext,
    position: RelativeRect.fromRect(
      const Rect.fromLTWH(1000, 0, 100, 100), // Vị trí tạm thời (sẽ được tự căn chỉnh bởi Flutter)
      Offset.zero & MediaQuery.of(context).size,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white,
    items: [
      // MỤC 1: Thêm vào Yêu thích
      PopupMenuItem(
        value: 'favorite',
        child: Row(children: [const Icon(Icons.favorite_border, color: Colors.redAccent), const SizedBox(width: 10), Text('Thêm vào yêu thích')]),
      ),
      // MỤC 2: Thêm vào Playlist
      PopupMenuItem(
        value: 'playlist',
        child: Row(children: [const Icon(Icons.playlist_add, color: Colors.blueAccent), const SizedBox(width: 10), Text('Thêm vào playlist khác')]),
      ),
      // MỤC 3: REPOST (Hiển thị trạng thái không đồng bộ)
      await _buildRepostMenuItem(songWithFullData),
    ],
  );

  // 3. XỬ LÝ KẾT QUẢ CHỌN
  if (result == 'favorite') {
    favoriteService.addFavorite(songWithFullData);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm vào yêu thích 💙'), duration: Duration(seconds: 1)));
  } else if (result == 'playlist') {
    _showAddToPlaylistDialog(songWithFullData);
  } else if (result == 'repost_toggle') {
    final bool currentlyReposted = await repostService.isSongReposted(songWithFullData.id);
    try {
      final newStatus = await repostService.toggleRepost(songWithFullData, currentlyReposted);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'Đã Repost lên Profile!' : 'Đã hủy Repost.'),
          backgroundColor: newStatus ? Colors.green : Colors.grey,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi Repost: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }
}

// HÀM HỖ TRỢ XÂY DỰNG MỤC REPOST BẤT ĐỒNG BỘ
Future<PopupMenuItem<String>> _buildRepostMenuItem(Songs song) async {
  final isReposted = await repostService.isSongReposted(song.id);
  final String label = isReposted ? 'Hủy Repost' : 'Repost lên Profile';
  final Color iconColor = isReposted ? Theme.of(context).colorScheme.primary : Colors.white70;

  return PopupMenuItem<String>(
    value: 'repost_toggle',
    child: Row(
      children: [
        Icon(Icons.repeat, color: iconColor),
        const SizedBox(width: 10),
        Text(label),
      ],
    ),
  );
}
  // === PLAYLIST CONTENT === (Giữ nguyên)
  Widget _buildPlaylistContent(
    BuildContext context,
    AudioPlayerProvider player,
    List<Songs> playlist,
    int currentIndex,
  ) {
    if (playlist.isEmpty) {
      return const Center(
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
                          child:
                              Icon(Icons.music_note, color: Colors.white, size: 28),
                        )
                      : null,
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  song.artist,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                trailing:
                    isCurrent ? const Icon(Icons.bar_chart, color: Colors.white) : null,
                onTap: () {
                  player.setNewPlaylist(playlist, index);
                  Navigator.pop(context);
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
    
    _tabController = TabController(length: 2, vsync: this);
    _loadLyrics(lyricsService);
  }

  // Phương thức _loadLyrics (Giữ nguyên)
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

  Widget _buildPlayerHeader(Songs song, AudioPlayerProvider player, BuildContext context) {
    final displayImage = song.thumbnail.isNotEmpty ? song.thumbnail : (widget.imageUrl ?? '');
    final displayTitle = song.title.isNotEmpty ? song.title : (widget.title ?? 'Unknown Title');
    final displaySubtitle = song.artist.isNotEmpty ? song.artist : (widget.subtitle ?? '');
    final tagValue = widget.heroTag ?? (song.id.isNotEmpty ? song.id : displayImage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              widget.showBackButton
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                    )
                  : IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.queue_music_rounded,
                    color: Colors.white, size: 24),
                onPressed: () => _showPlaylistModal(context),
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () => _shareSong(song),
              ),
              IconButton(
                icon: const Icon(Icons.flag_outlined, color: Colors.white),
                onPressed: () => _reportSong(song),
              ),
              Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.white),
                    onPressed: () => _showPlayerOptions(context, song), // GỌI HÀM MỚI
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // === B. COVER IMAGE ===
    (displayImage.isNotEmpty)
      ? Hero(
        tag: tagValue,
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
                child:
                    const Icon(Icons.album, size: 80, color: Colors.white54),
              ),
        const SizedBox(height: 30),

        // === C. INFO & CONTROLS ===
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tên bài hát
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
              // Tên nghệ sĩ
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
              // Progress Bar & Time
              Column(
                children: [
                  WaveformProgressBar(
                    progress: _currentPosition,
                    total: _totalDuration,
                    onSeek: (duration) async {
                      final playerProvider =
                          Provider.of<AudioPlayerProvider>(context, listen: false);
                      await playerProvider.seek(duration);
                      _seekIgnoreTimer?.cancel();
                      _seekIgnoreTimer =
                          Timer(const Duration(milliseconds: 400), () {});
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
              // Playback Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Nút SHUF
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: player.isShuffleEnabled
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white70,
                    ),
                    onPressed: player.toggleShuffle,
                  ),
                  // Nút PRE
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    color: Colors.white.withOpacity(0.9),
                    iconSize: 48,
                    onPressed: player.previousSong,
                  ),
                  // Nút Play/Pause
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
                      icon: Icon(
                          player.isPlaying ? Icons.pause : Icons.play_arrow),
                      color: Colors.black87,
                      iconSize: 54,
                      onPressed: () async {
                        if (player.currentPlaylist.isNotEmpty) {
                          if (!player.isPlaying || player.currentIndex != 0) {
                            await player.setNewPlaylist(
                                player.currentPlaylist, 0);
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerProvider>(
      builder: (context, player, child) {
        final song = player.currentPlaying ?? widget.song;

        if (song == null) {
          return const Scaffold(
            body: Center(
              child:
                  Text("Không có bài hát nào đang phát", style: TextStyle(color: Colors.white)),
            ),
          );
        }
        const double tabBarHeight = 48.0; 

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: (song.thumbnail.isNotEmpty)
                    ? Image.network(
                        song.thumbnail,
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
                child: NestedScrollView(

                  headerSliverBuilder: 
                      (BuildContext context, bool innerBoxIsScrolled) {
                    return <Widget>[

                      SliverList(
                        delegate: SliverChildListDelegate([
                          _buildPlayerHeader(song, player, context),
                        ]),
                      ),

                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          minHeight: tabBarHeight,
                          maxHeight: tabBarHeight,
                          child: Container(
                            color: Colors.black.withOpacity(0.8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: TabBar(
                                controller: _tabController,
                                tabs: const [
                                  Tab(text: 'Lời bài hát'),
                                  Tab(text: 'Bình luận'), 
                                ],
                                indicatorColor: Theme.of(context).colorScheme.primary, 
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.white54,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      SingleChildScrollView(
                        physics: const BouncingScrollPhysics(), 
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: _buildLyricsWidget(),
                        ),
                      ),
                      CommentSection(songId: song.id),
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
              const lyricsContainer = document.querySelector('[data-lyrics-container]');

              if (lyricsContainer) {
                const lyricsHtml = lyricsContainer.innerHTML;
                document.body.innerHTML = lyricsHtml;
                document.body.style.backgroundColor = '#000000';
                document.body.style.color = '#ffffff';
                document.body.style.fontSize = '16px';
                document.body.style.lineHeight = '1.6';
                document.body.style.padding = '16px';
                document.body.style.margin = '0';
                document.body.style.overflowX = 'hidden';
                document.body.style.overflowY = 'scroll';
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
        height: MediaQuery.of(context).size.height * 0.7, 
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
    _tabController.dispose();
    _positionSub.cancel();
    _durationSub.cancel();
    _seekIgnoreTimer?.cancel();
    super.dispose();
  }

  Future<void> _shareSong(Songs song) async {
    final link = buildSongDeepLink(song.id).toString();
    try {
      await ShareIntentService.shareText(
        link,
        subject: song.title,
      );
    } on PlatformException catch (error) {
      debugPrint('Share failed: $error');
      await _fallbackCopyLink(link);
    } catch (error) {
      debugPrint('Unexpected share error: $error');
      await _fallbackCopyLink(link);
    }
  }

  Future<void> _fallbackCopyLink(String link) async {
    if (!mounted) return;
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Không mở được share sheet. Link đã copy vào clipboard.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _reportSong(Songs song) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để báo cáo bài hát.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final List<String> reportReasons = [
      'Nội dung không phù hợp',
      'Vi phạm bản quyền',
      'Chất lượng âm thanh kém',
      'Thông tin bài hát sai',
      'Lý do khác',
    ];

    if (!mounted) return;
    final String? selectedReason = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Báo cáo bài hát'),
          content: SizedBox(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: reportReasons.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(reportReasons[index]),
                  onTap: () {
                    Navigator.pop(context, reportReasons[index]);
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    if (selectedReason != null && selectedReason.isNotEmpty) {
      try {
        await SongService().reportSong(
          songId: song.id,
          reason: selectedReason,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bài hát đã được báo cáo thành công.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi báo cáo bài hát: $e')),
        );
      }
    }
  }
}
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}