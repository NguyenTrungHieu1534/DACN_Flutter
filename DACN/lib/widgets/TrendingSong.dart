import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/album.dart';
import '../services/api_album.dart';
import '/screens/login_screen.dart';
import '/screens/player_screen.dart';
import '/screens/search_screen.dart';
import '/screens/library_screen.dart';
import '/screens/section_list_screen.dart';
import '../theme/app_theme.dart';
import '../models/songs.dart';
import '../services/api_songs.dart';
import 'dart:math';

class TrendingSong extends StatelessWidget {
  const TrendingSong(
      {required this.title,
      required this.itemsAlbum,
      required this.itemsSsongs});

  final String title;
  final List<Album> itemsAlbum;
  final List<Songs> itemsSsongs;

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem hiển thị albums hay songs
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
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SectionListScreen(
                          title: title,
                          items: isShowingSongs ? [] : itemsAlbum),
                    ),
                  );
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

        // Hiển thị Songs hoặc Albums
        if (isShowingSongs) _buildSongsList() else _buildAlbumsList(),
      ],
    );
  }

  // Widget hiển thị danh sách Albums
  Widget _buildAlbumsList() {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemsAlbum.length,
        itemBuilder: (context, index) {
          final album = itemsAlbum[index];
          final heroTag = 'hawai-album-${album.url}-$index';

          final gradientColors = [
            [const Color(0xFFFFE7C2), const Color(0xFFFBD2D7)], // peach sunset
            [const Color(0xFFC9F4F1), const Color(0xFFE8FFE1)], // seafoam
            [const Color(0xFFF6D8B5), const Color(0xFFFFE8D7)], // sand gold
            [const Color(0xFFE0E5FF), const Color(0xFFD0F1FF)], // sky blue
          ];
          final colors = gradientColors[index % gradientColors.length];

          return Padding(
            padding: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayerScreen(
                      title: album.name,
                      subtitle: album.artist,
                      imageUrl: album.url,
                      heroTag: heroTag,
                    ),
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
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.black87,
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
                            style: const TextStyle(
                              color: Colors.black87,
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
                            style: const TextStyle(
                              color: Colors.black54,
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
                          child: const Icon(
                            Icons.attach_file,
                            color: Colors.black87,
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
  Widget _buildSongsList() {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemsSsongs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final song = itemsSsongs[index];

          // Màu pastel ngẫu nhiên nhẹ nhàng cho mỗi thẻ
          final retroColors = [
            const Color(0xFFFFE5B4), // peach
            const Color(0xFFB5EAD7), // mint
            const Color(0xFFFFC8A2), // coral
            const Color(0xFFD4A5A5), // rose
            const Color(0xFFF7E8D0), // beige
          ];
          final bgColor = retroColors[index % retroColors.length];

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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(
                        title: song.title,
                        subtitle: song.artist,
                        imageUrl: song.thumbnail,
                        heroTag: 'retro-song-${song.id}-$index',
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Hình album và vinyl
                      Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Positioned(
                            left: 30,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black87,
                              ),
                              child: Center(
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.redAccent,
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
                                  color: Colors.black87.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '#${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
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
                              style: const TextStyle(
                                color: Colors.black87,
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
                              style: const TextStyle(
                                color: Colors.black54,
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
                                const Icon(
                                  Icons.play_circle_outline_rounded,
                                  color: Colors.black45,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Now trending",
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Nút play retro
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.orangeAccent, Colors.deepOrange],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepOrange.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
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
