import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_album.dart';
import '../models/songs.dart';
import '../models/AudioPlayerProvider.dart';
// import '../navigation/bottom_nav.dart';
import '../widgets/shimmer_widgets.dart'; // ✅ thêm dòng này

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

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  late Future<List<Songs>> futureSongs;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    futureSongs = AlbumService.fetchSongsByAlbum(widget.albumName);
  }

  void _onItemSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF8FF),
      body: Column(
        children: [
          // 🔹 Banner Album
          Stack(
            children: [
              Container(
                height: 230,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFA7E6FF),
                      Color(0xFFEAF8FF),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 60,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          widget.albumImage,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.albumName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 🔹 Danh sách bài hát
          Expanded(
            child: FutureBuilder<List<Songs>>(
              future: futureSongs,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // ✅ Hiển thị shimmer khi đang tải
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                    itemCount: 5,
                    itemBuilder: (context, index) =>
                        Padding(
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
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
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
                            color: Colors.blueAccent.withOpacity(0.08),
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
                            final audioProvider = Provider.of<AudioPlayerProvider>(
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
                                // 🎵 Ảnh bài hát
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    image: DecorationImage(
                                      image: NetworkImage(widget.albumImage),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // 🔹 Thông tin bài hát
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
                                          color: Color(0xFF2D3748),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        song.artist,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF6BB6E8),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 🔹 Nút phát
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6BB6E8),
                                        Color(0xFFA7E6FF),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.blueAccent.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
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
        ],
      ),
    );
  }
}
