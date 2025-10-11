import 'package:flutter/material.dart';
import '../models/album.dart';
import '../screens/album_detail_screen.dart';
import 'shimmer_widgets.dart';

class TrendingAlbum extends StatelessWidget {
  final String title;
  final List<Album> itemsAlbum;
  final bool isLoading;

  const TrendingAlbum({
    required this.title,
    required this.itemsAlbum,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          SizedBox(
            height: 320,
            child: isLoading
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: List.generate(4, (index) => Padding(
                        padding: const EdgeInsets.only(right: 280),
                        child: ShimmerWidgets.trendingAlbumCardShimmer(),
                      )),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const double cardWidth = 200;
                        const double spacing = 280;

                        final double totalWidth =
                            cardWidth + (itemsAlbum.length - 1) * spacing;
                        final List<Widget> stackedAlbums = [];

                        for (int i = 0; i < itemsAlbum.length; i++) {
                          stackedAlbums.add(
                            Positioned(
                              left: i * spacing,
                              child: _buildAlbumCard(context, itemsAlbum[i], i + 1),
                            ),
                          );
                        }

                        return SizedBox(
                          width: totalWidth,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: stackedAlbums.reversed.toList(),
                          ),
                        );
                      },
                    ),
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildAlbumCard(BuildContext context, Album album, int rank) {
    final cardColor = [
      const Color(0xFFC4E9F5),
      const Color(0xFFFFF2BE),
      const Color(0xFFF6C7D4),
    ][(rank - 1) % 3];

    final heroTag = 'album-pixel-$rank';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ĐĨA VINYL — nằm dưới, thò ra bên phải
        Positioned(
          right: -65,
          top: 70,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Colors.black, Colors.black87, Colors.black54],
                center: Alignment(-0.4, -0.3),
                radius: 0.95,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(6, 8),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.redAccent.shade700,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
              ),
            ),
          ),
        ),

        // Bìa album
        InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AlbumDetailScreen(
                  albumName: album.name,
                  albumImage: album.url, // ✅ Truyền thêm ảnh album
                ),
              ),
            );
          },
          child: Container(
            width: 240,
            height: 280,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(6, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'PressStart2P',
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Hero(
                    tag: heroTag,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        album.url,
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (context, _, __) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    album.name.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    album.artist,
                    style: const TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 10,
                      color: Colors.black54,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
