import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_album.dart';
import '../models/songs.dart';
import '../models/AudioPlayerProvider.dart';
import '../widgets/shimmer_widgets.dart';
import '../screens/player_screen.dart';
import '../widgets/autoScroollerText.dart';
import '../services/api_favsongs.dart';
import '../services/api_playlist.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                automaticallyImplyLeading: false,
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.mist,
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
                          style: const TextStyle(
                            color: Colors.black87,
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
                                colors: [
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
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'Không có bài hát trong album này 😢',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                final songs = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.oceanBlue.withOpacity(0.08),
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
                                Provider.of<AudioPlayerProvider>(
                                    context,
                                    listen: false);

                            final updatedSong = Songs(
                              id: song.id,
                              title: song.title,
                              artist: song.artist,
                              albuml: song.albuml,
                              url: song.url,
                              thumbnail: widget.albumImage,
                              mp3Url: song.mp3Url,
                            );

                            audioProvider.playSong(updatedSong);
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
                                    borderRadius: BorderRadius.circular(16),
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
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.oceanDeep,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        song.artist,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.skyBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: Colors.white,
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    color: AppColors.skyBlue,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'favorite') {
                                      favoriteService.addFavorite(song);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Đã thêm vào yêu thích 💙'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );

                                    } else if (value == 'playlist') {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Đã thêm vào playlist khác 🎵'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'favorite',
                                      child: Row(
                                        children: [
                                          Icon(Icons.favorite_border,
                                              color: Colors.redAccent),
                                          SizedBox(width: 10),
                                          Text('Thêm vào yêu thích'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'playlist',
                                      child: Row(
                                        children: [
                                          Icon(Icons.playlist_add,
                                              color: AppColors.oceanBlue),
                                          SizedBox(width: 10),
                                          Text('Thêm vào playlist khác'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// 🎵 Mini Player ở cuối trang (giống nav)
          Align(
            alignment: Alignment.bottomCenter,
            child: Consumer<AudioPlayerProvider>(
              builder: (context, audioPlayerProvider, child) {
                final currentPlaying = audioPlayerProvider.currentPlaying;
                final isPlaying = audioPlayerProvider.isPlaying;

                if (currentPlaying == null) return const SizedBox.shrink();

                return Padding(
                  padding:
                      const EdgeInsets.only(left: 40, right: 40, bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(30),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PlayerScreen(song: currentPlaying),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  RotationTransition(
  turns: (_rotationController.isAnimating)
      ? _rotationController
      : const AlwaysStoppedAnimation(0),
  child: CircleAvatar(
    backgroundImage: NetworkImage(currentPlaying.thumbnail),
    radius: 20,
  ),
),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        0.5,
                                    child: autoTextScroller(
                                      currentPlaying.title,
                                      const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.black87,
                              ),
                              onPressed: () {
                                audioPlayerProvider.togglePlayPause();
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
      ),
    );
  }
}
