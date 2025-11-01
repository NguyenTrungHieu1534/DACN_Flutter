import 'package:flutter/material.dart';
import '../models/album.dart';
import '../screens/album_detail_screen.dart';
import '../models/songs.dart';
import 'package:provider/provider.dart';
import '../models/AudioPlayerProvider.dart';
import 'shimmer_widgets.dart';
import '../navigation/custom_page_route.dart'; // Import custom page routes
import '../screens/player_screen.dart'; // Import PlayerScreen

class TrendingSong extends StatelessWidget {
  const TrendingSong(
      {super.key,
      required this.title,
      required this.itemsAlbum,
      required this.itemsSsongs,
      this.isLoading = false});

  final String title;
  final List<Album> itemsAlbum;
  final List<Songs> itemsSsongs;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isShowingSongs = itemsSsongs.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withOpacity(0.3),
                      Colors.pink.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  title.contains('Trending')
                      ? Icons.trending_up_rounded
                      : title.contains('New')
                          ? Icons.fiber_new_rounded
                          : Icons.music_note_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (_) => SectionListScreen(
                  //         title: title,
                  //         items: isShowingSongs ? [] : itemsAlbum),
                  //   ),
                  // );
                },
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                ),
                label: const Text(
                  'See all',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Hiển thị Songs hoặc Albums hoặc shimmer loading
        if (isLoading)
          _buildShimmerList(isShowingSongs)
        else if (isShowingSongs)
          _buildSongsList(context)
        else
          _buildAlbumsList(context),
      ],
    );
  }

  // Widget hiển thị shimmer loading
  Widget _buildShimmerList(bool isShowingSongs) {
    if (isShowingSongs) {
      return SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 20),
          itemBuilder: (context, index) => ShimmerWidgets.songCardShimmer(),
        ),
      );
    } else {
      return SizedBox(
        height: 250,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 4,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
            child: ShimmerWidgets.albumCardShimmer(),
          ),
        ),
      );
    }
  }

  // Widget hiển thị danh sách Albums
  Widget _buildAlbumsList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemsAlbum.length,
        itemBuilder: (context, index) {
          final album = itemsAlbum[index];
          final heroTag = 'hawai-album-${album.url}-$index';

          final gradientColors = isDark
              ? [
                  [
                    const Color(0xFF1A1A1A),
                    const Color(0xFF2D2D2D)
                  ], // dark gray gradient
                  [
                    const Color(0xFF0F0F0F),
                    const Color(0xFF1A1A1A)
                  ], // very dark gray
                  [
                    const Color(0xFF2C2C2C),
                    const Color(0xFF3A3A3A)
                  ], // medium dark gray
                  [
                    const Color(0xFF1F1F1F),
                    const Color(0xFF2A2A2A)
                  ], // dark charcoal
                ]
              : [
                  [
                    const Color(0xFFFFE7C2),
                    const Color(0xFFFBD2D7)
                  ], // peach sunset
                  [
                    const Color(0xFFC9F4F1),
                    const Color.fromARGB(255, 225, 230, 255)
                  ], // seafoam
                  [
                    const Color(0xFFF6D8B5),
                    const Color(0xFFFFE8D7)
                  ], // sand gold
                  [
                    const Color(0xFFE0E5FF),
                    const Color(0xFFD0F1FF)
                  ], // sky blue
                ];
          final colors = gradientColors[index % gradientColors.length];

          return Padding(
            padding: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  ScaleFadePageRoute(
                    child: AlbumDetailScreen(
                        albumName: album.name, albumImage: album.url),
                  ),
                );
              },
              child: Container(
                width: 190,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(3, 6),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Ảnh album nghiêng nhẹ
                    Positioned(
                      top: -10,
                      left: 18,
                      right: 18,
                      child: Hero(
                        tag: heroTag,
                        child: Transform.rotate(
                          angle: -0.05,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              album.url,
                              height: 130,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                height: 130,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.album, size: 40),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Nút Play bong bóng
                    Positioned(
                      bottom: 20,
                      right: 16,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 30,
                        ),
                      ),
                    ),

                    // Text info
                    Positioned(
                      bottom: 28,
                      left: 16,
                      right: 70,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album.name,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            album.artist,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Trang trí mặt trời 🌞 hoặc lá dừa 🌴
                    Positioned(
                      top: -4,
                      right: 12,
                      child: Transform.rotate(
                        angle: -0.4,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(1, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.attach_file,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.8),
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget hiển thị danh sách Songs
  Widget _buildSongsList(BuildContext context) {
    final audioProvider =
        Provider.of<AudioPlayerProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final playGradient = isDark
        ? LinearGradient(
            colors: [Colors.grey[700]!, Colors.grey[800]!],
          )
        : const LinearGradient(
            colors: [Colors.orangeAccent, Colors.deepOrange],
          );
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemsSsongs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final song = itemsSsongs[index];

          // Theme-based background colors that adapt to light/dark mode
          final themeColors = [
            Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(
                isDark ? 0.3 : 0.8), // lighter for light, darker for dark
            Theme.of(context)
                .colorScheme
                .secondaryContainer
                .withOpacity(isDark ? 0.4 : 0.7),
            Theme.of(context)
                .colorScheme
                .primaryContainer
                .withOpacity(isDark ? 0.3 : 0.8),
            Theme.of(context)
                .colorScheme
                .tertiaryContainer
                .withOpacity(isDark ? 0.4 : 0.7),
            Theme.of(context)
                .colorScheme
                .surface
                .withOpacity(isDark ? 0.5 : 0.9),
          ];
          final bgColor = themeColors[index % themeColors.length];

          return Container(
            width: 340,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                // Thêm onTap để mở PlayerScreen
                onTap: () {
                  Navigator.push(
                    context,
                    ModalSlideUpPageRoute(child: PlayerScreen(song: song)),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Positioned(
                            left: 30,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.8),
                              ),
                              child: Center(
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              song.thumbnail,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey.shade400,
                                child: const Icon(
                                  Icons.music_note_rounded,
                                  color: Colors.white70,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                          if (index < 3)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '#${index + 1}',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(width: 20),

                      // Thông tin bài hát
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              song.title,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Poppins',
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              song.artist,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.play_circle_outline_rounded,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.45),
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Now trending",
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          audioProvider.playSong(song);
                          debugPrint("Container được bấm!------${song.title}");
                        },
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: playGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.grey.withOpacity(0.4)
                                    : Colors.deepOrange.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 30,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
