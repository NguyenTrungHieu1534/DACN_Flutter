import 'package:flutter/material.dart';
import '../models/playlist.dart';

class PlaylistPreviewGrid extends StatelessWidget {
  final List<Playlist> playlists;
  final Function(Playlist) onTapPlaylist;
  final Widget Function(Playlist) buildPlaylistMenu;

  const PlaylistPreviewGrid(
    this.playlists, {
    super.key,
    required this.onTapPlaylist,
    required this.buildPlaylistMenu,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return GestureDetector(
          onTap: () => onTapPlaylist(playlist),
          child: Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FadeInImage.assetNetwork(
                    placeholder: 'default_pic/default_playlistPic.png',
                    image: playlist.picUrl,
                    fit: BoxFit.cover,
                    imageErrorBuilder: (_, __, ___) => Image.asset(
                      'default_pic/default_playlistPic.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(color: Colors.black.withOpacity(0.35)),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Text(playlist.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Positioned(top: 4, right: 4, child: buildPlaylistMenu(playlist)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}