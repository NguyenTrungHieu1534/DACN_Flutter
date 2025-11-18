import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_album.dart';
import '../models/songs.dart';
import '../widgets/repost_button.dart'; // Import này có thể bị loại bỏ sau khi chuyển sang logic cũ
import '../services/api_repost.dart';
import '../models/AudioPlayerProvider.dart';
import '../widgets/shimmer_widgets.dart';
import '../screens/player_screen.dart';
import '../widgets/autoScroollerText.dart';
import '../services/api_favsongs.dart';
import '../services/api_playlist.dart';
import '../widgets/mini_player_widget.dart';
import 'artist_detail_screen.dart';
import '../navigation/custom_page_route.dart';
import '../screens/login_screen.dart';

class AlbumDetailScreen extends StatefulWidget {
  final String albumName;
  final String albumImage;

  const AlbumDetailScreen({
    super.key,
    required this.albumName,
    required this.albumImage,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Songs>> futureSongs;
  late AnimationController _rotationController;
  final FavoriteService favoriteService = FavoriteService();
  final ApiPlaylist apiPlaylist = ApiPlaylist();
  final RepostService repostService = RepostService();

  @override
  void initState() {
    super.initState();
    futureSongs = AlbumService.fetchSongsByAlbum(widget.albumName);
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _playEntireAlbum(List<Songs> songs, BuildContext context) {
    if (songs.isEmpty) return;
    final audioProvider =
        Provider.of<AudioPlayerProvider>(context, listen: false);
    final playlistToPlay =
        songs.map((s) => s.copyWith(thumbnail: widget.albumImage)).toList();
    audioProvider.setNewPlaylist(playlistToPlay, 0);
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
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
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
                  ? 'Đã tạo playlist "$newPlaylistName"!'
                  : 'Tạo playlist mới thất bại.')),
        );
      }
      if (newPlaylist != null) {
        _showAddToPlaylistDialog(song);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                automaticallyImplyLeading: false,
                expandedHeight: 300,
                pinned: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: 0,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final percent = (constraints.maxHeight - kToolbarHeight) /
                        (260 - kToolbarHeight);
                    return FlexibleSpaceBar(
                      centerTitle: true,
                      title: AnimatedOpacity(
                        opacity: percent < 0.3 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          widget.albumName,
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            widget.albumImage,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? [
                                        Colors.black.withOpacity(0.5),
                                        Colors.black.withOpacity(0.8),
                                      ]
                                    : [
                                        Colors.black.withOpacity(0.2),
                                        Colors.black.withOpacity(0.5),
                                      ],
                              ),
                            ),
                          ),
                          BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              color: Colors.black.withOpacity(0.15),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              width: 200 * percent.clamp(0.6, 1.0),
                              height: 200 * percent.clamp(0.6, 1.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: Stack(
                                  children: [
                                    Image.network(
                                      widget.albumImage,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        height: 100,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.55),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 40,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: AnimatedOpacity(
                                opacity: percent > 0.3 ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 250),
                                child: Text(
                                  widget.albumName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        blurRadius: 10,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 6,
                            left: 8,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            body: FutureBuilder<List<Songs>>(
              future: futureSongs,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                    itemCount: 5,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ShimmerWidgets.songCardShimmer(),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Lỗi: ${snapshot.error}',
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'Không có bài hát trong album này 😢',
                      style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.6),
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                final songs = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FloatingActionButton(
                            heroTag: 'Play Album',
                            onPressed: () => _playEntireAlbum(songs, context),
                            shape: const CircleBorder(),
                            child:
                                const Icon(Icons.play_arrow_rounded, size: 28),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                        itemCount: songs.length,
                        itemBuilder: (context, index) {
                          final song = songs[index];

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Theme.of(context).cardColor.withOpacity(0.9)
                                  : Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.black.withOpacity(0.2)
                                      : AppColors.oceanBlue.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () {
                                  final audioProvider =
                                      Provider.of<AudioPlayerProvider>(context,
                                          listen: false);
                                  final playlistToPlay = songs
                                      .map((s) => s.copyWith(
                                          thumbnail: widget.albumImage))
                                      .toList();
                                  audioProvider.setNewPlaylist(
                                      playlistToPlay, index);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          image: DecorationImage(
                                            image:
                                                NetworkImage(widget.albumImage),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              song.title,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.color
                                                    : AppColors.oceanDeep,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  FadePageRoute(
                                                      child: ArtistDetailScreen(
                                                          artistName:
                                                              song.artist)),
                                                );
                                              },
                                              child: Text(
                                                song.artist,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Theme.of(context)
                                                          .primaryColor
                                                      : AppColors.oceanBlue,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // BẮT ĐẦU VỊ TRÍ SỬA ĐỔI NÚT 3 CHẤM
                                      Builder(
                                        builder: (context) {
                                          final songWithThumbnail = song.copyWith(
                                              thumbnail: widget.albumImage); 

                                          return PopupMenuButton<String>(
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16)),
                                            color: Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Theme.of(context).cardColor
                                                : Colors.white,
                                            icon: Icon(
                                              Icons.more_vert_rounded,
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Theme.of(context).primaryColor
                                                  : AppColors.oceanBlue,
                                            ),
                                            onSelected: (value) async {
                                              // LOGIC KIỂM TRA ĐĂNG NHẬP (Giữ nguyên)
                                              final prefs = await SharedPreferences.getInstance();
                                              final token = prefs.getString('token');

                                              if (token == null || token.isEmpty) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Vui lòng đăng nhập để sử dụng tính năng này 🔒'), duration: Duration(seconds: 2)));
                                                Future.delayed(const Duration(seconds: 1), () {
                                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                                                });
                                                return;
                                              }
                                              
                                              // XỬ LÝ CÁC HÀNH ĐỘNG
                                              if (value == 'favorite') {
                                                favoriteService.addFavorite(songWithThumbnail);
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm vào yêu thích 💙'), duration: Duration(seconds: 1)));
                                                
                                              } else if (value == 'playlist') {
                                                _showAddToPlaylistDialog(songWithThumbnail);
                                                
                                              } else if (value == 'repost_toggle') {
                                                // XỬ LÝ REPOST/HỦY REPOST TRỰC TIẾP
                                                final bool currentlyReposted = await repostService.isSongReposted(songWithThumbnail.id);
                                                try {
                                                  final newStatus = await repostService.toggleRepost(songWithThumbnail, currentlyReposted);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(newStatus ? 'Đã Repost lên Profile!' : 'Đã hủy Repost.'),
                                                      backgroundColor: newStatus ? Colors.green : Colors.grey,
                                                    ),
                                                  );
                                                  // Cần gọi setState để buộc ListViewBuilder xây dựng lại và cập nhật trạng thái Repost
                                                  setState(() {}); 
                                                } catch (e) {
                                                     ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Lỗi Repost: ${e.toString().replaceFirst('Exception: ', '')}')),
                                                  );
                                                }
                                              }
                                            },
                                            itemBuilder: (context) {
                                              // SỬ DỤNG FUTUREBUILDER ĐỂ LẤY TRẠNG THÁI REPOST KHI MENU MỞ

                                              return [
                                                // Thêm các mục đã có (Yêu thích, Playlist)
                                                PopupMenuItem(
                                                  value: 'favorite',
                                                  // XÓA const trong Row/SizedBox
                                                  child: Row(children: [const Icon(Icons.favorite_border, color: Colors.redAccent), const SizedBox(width: 10), Text('Thêm vào yêu thích', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))]),
                                                ),
                                                PopupMenuItem(
                                                  value: 'playlist',
                                                  // XÓA const trong Row/SizedBox
                                                  child: Row(children: [Icon(Icons.playlist_add, color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).primaryColor : AppColors.oceanBlue), const SizedBox(width: 10), Text('Thêm vào playlist khác', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color))]),
                                                ),
                                                
                                                // ⭐️ MỤC MỚI: REPOST (hiển thị trạng thái với FutureBuilder bên trong PopupMenuItem)
                                                PopupMenuItem<String>(
                                                  value: 'repost_toggle',
                                                  child: FutureBuilder<bool>(
                                                    future: repostService.isSongReposted(songWithThumbnail.id),
                                                    builder: (context, snapshot) {
                                                      final isReposted = snapshot.data ?? false;
                                                      final String label = isReposted ? 'Hủy Repost' : 'Repost lên Profile';
                                                      final Color iconColor = isReposted ? Theme.of(context).primaryColor : Colors.grey;
                                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                                        return Row(
                                                          children: [
                                                            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.0)),
                                                            const SizedBox(width: 10),
                                                            Text('Đang kiểm tra Repost...', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.5))),
                                                          ],
                                                        );
                                                      }
                                                      return Row(
                                                        children: [
                                                          Icon(Icons.repeat, color: iconColor),
                                                          const SizedBox(width: 10),
                                                          Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ];
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const MiniPlayerWidget(),
        ],
      ),
    );
  }
}