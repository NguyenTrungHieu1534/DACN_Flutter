import 'package:flutter/material.dart';
import '../models/album.dart';
import 'player_screen.dart';
import '../theme/app_theme.dart';

class SectionListScreen extends StatelessWidget {
  const SectionListScreen({Key? key, required this.title, required this.items})
      : super(key: key);

  final String title;
  final List<Album> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title, style: const TextStyle(color: AppColors.retroWhite),), backgroundColor: AppColors.retroPrimary, iconTheme: const IconThemeData(color: AppColors.retroWhite),),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.retroPrimary,
              Color.fromARGB(255, 112, 150, 193),
              AppColors.retroWhite,
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final album = items[index];
            final tag = 'section-${album.url}-$index';
            return Material(
              color: AppColors.retroWhite,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(
                        title: album.name,
                        subtitle: album.artist,
                        imageUrl: album.url,
                        heroTag: tag,
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Hero(
                        tag: tag,
                        child: Ink.image(
                          image: NetworkImage(album.url),
                          fit: BoxFit.cover,
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                      child: Text(
                        album.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.retroAccent),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: Text(
                        album.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: AppColors.retroAccent.withOpacity(0.7), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
