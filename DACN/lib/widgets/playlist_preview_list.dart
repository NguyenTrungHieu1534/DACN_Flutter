import 'package:flutter/material.dart';
import '../models/playlist.dart';

class PlaylistPreviewList extends StatelessWidget {
  final List<Playlist> playlists;
  final Function(Playlist) onTapPlaylist;
  final Widget Function(Playlist) buildPlaylistMenu;

  const PlaylistPreviewList(
    this.playlists, {
    super.key,
    required this.onTapPlaylist,
    required this.buildPlaylistMenu,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: playlists.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return Card(
          margin: EdgeInsets.zero, // Loại bỏ margin của Card
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FadeInImage.assetNetwork(
                placeholder: 'default_pic/default_playlistPic.png',
                image: playlist.picUrl,
                fit: BoxFit.cover,
                width: 50,
                height: 50,
                imageErrorBuilder: (_, __, ___) => Image.asset(
                  'default_pic/default_playlistPic.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            title: Text(
              playlist.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${playlist.songs.length} songs',
              style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.7)),
            ),
            trailing: buildPlaylistMenu(playlist),
            onTap: () => onTapPlaylist(playlist),
          ),
        );
      },
    );
  }
}