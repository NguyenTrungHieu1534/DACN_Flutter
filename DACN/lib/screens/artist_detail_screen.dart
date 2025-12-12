import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/album.dart';
import '../models/songs.dart';
import '../services/api_artist.dart';
import '../services/api_album.dart';
import '../services/api_favsongs.dart';
import '../services/api_playlist.dart';
import '../services/api_repost.dart';
import '../services/api_follow.dart';
import '../models/AudioPlayerProvider.dart';
import '../widgets/shimmer_widgets.dart';
import 'album_detail_screen.dart';
import '../screens/login_screen.dart';
import 'dart:convert';

class ArtistDetailScreen extends StatefulWidget {
  final String artistName;

  const ArtistDetailScreen({super.key, required this.artistName});

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  late Future<Map<String, dynamic>> _artistDetailsFuture;
  final ArtistService _artistService = ArtistService();
  final FollowService _followService = FollowService();
  bool _isFollowing = false;
  bool _isFollowStatusLoading = true;
  String? _artistId;
  final FavoriteService favoriteService = FavoriteService();
  final RepostService repostService = RepostService();
  final ApiPlaylist apiPlaylist = ApiPlaylist();
  @override
  void initState() {
    super.initState();
    _artistDetailsFuture = _loadArtistData();
  }

  Future<void> _checkFollowStatus(String artistId) async {
    setState(() => _isFollowStatusLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() => _isFollowStatusLoading = false);
        return;
      }

      final id = JwtDecoder.decode(token)['_id'];
      final isFollow = await _followService.checkFollow(
        userId: id,
        targetType: "artist",
        targetId: artistId,
      );

      setState(() {
        _isFollowing = isFollow; // true / false
        _isFollowStatusLoading = false;
      });
    } catch (e) {
      setState(() => _isFollowStatusLoading = false);
    }
  }

  Future<Map<String, dynamic>> _loadArtistData() async {
    try {
      final results = await Future.wait([
        _artistService.fetchSongsByArtist(widget.artistName),
        _artistService.fetchArtistPhotoUrl(widget.artistName),
        AlbumService.fetchAlbumsByArtist(widget.artistName),
        _artistService.fetchArtistDetails(widget.artistName),
      ]);

      final songs = results[0] as List<Songs>;
      final photoUrl = results[1] as String;
      final albums = results[2] as List<Album>;
      final artistDetails = results[3] as Map<String, dynamic>;
      _artistId = artistDetails['id'];
      if (_artistId != null) {
        _checkFollowStatus(_artistId!);
      }
      final Map<String, String?> albumCoverCache = {};
      final updatedSongs = await Future.wait(
        songs.map((song) async {
          if (song.thumbnail.isNotEmpty) return song;

          final albumName = song.album ?? 'Unknown';
          if (!albumCoverCache.containsKey(albumName)) {
            albumCoverCache[albumName] =
                await AlbumService.fetchAlbumCover(albumName);
          }
          return song.copyWith(thumbnail: albumCoverCache[albumName]);
        }),
      );
      return {
        'songs': updatedSongs,
        'photoUrl': photoUrl,
        'albums': albums,
        'artistDetails': artistDetails,
      };
    } catch (e) {
      throw Exception('Failed to load artist details: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_artistId != null) {
      _checkFollowStatus(_artistId!);
    }
  }

  Future<void> _toggleFollow() async {
    if (_artistId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to log in to follow.')),
      );
      return;
    }
    final userId = JwtDecoder.decode(token)['_id'];

    setState(() => _isFollowStatusLoading = true);

    bool success;
    if (_isFollowing) {
      success = await _followService.unfollow(
          userId: userId, targetType: 'artist', targetId: _artistId!);
    } else {
      success = await _followService.addFollow(
          userId: userId, targetType: 'artist', targetId: _artistId!);
    }

    if (success && mounted) _checkFollowStatus(_artistId!);
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
              'Add to Playlist',
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
                    const Text('You don''t have any playlists yet. Let''s create a new one!'),
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
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(localContext, rootNavigator: true)
                    .pop('new_playlist'),
                child: const Text('Create New Playlist'),
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
        SnackBar(content: Text('Error loading playlists: $e')),
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
              ? 'Song added to playlist!'
              : 'Failed to add song to playlist.'),
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
          'Create New Playlist',
          style:
              TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: "Playlist name",
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
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Create'),
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
                  ? 'Playlist "$newPlaylistName" created!'
                  : 'Failed to create new playlist.')),
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _artistDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ShimmerWidgets.albumCardShimmer();
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading artist data: ${snapshot.error}'));
          }

          final songs = snapshot.data?['songs'] as List<Songs>? ?? [];
          final photoUrl = snapshot.data?['photoUrl'] as String? ?? '';
          final albums = snapshot.data?['albums'] as List<Album>? ?? [];
          final popularSongs = (songs..shuffle()).take(5).toList();

          return _buildArtistPage(context, photoUrl, popularSongs, albums);
        },
      ),
    );
  }

  Widget _buildArtistPage(BuildContext context, String photoUrl,
      List<Songs> popularSongs, List<Album> albums) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final double extraBottomPadding =
        MediaQuery.of(context).padding.bottom + 80;

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context, photoUrl, isDark),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              extraBottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nút Follow và Shuffle
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _isFollowStatusLoading ? null : _toggleFollow,
                        icon: _isFollowStatusLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : Icon(_isFollowing
                                ? Icons.check_circle_outline
                                : Icons.person_add_alt_1_rounded),
                        label: Text(_isFollowing ? 'Following' : 'Follow'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          backgroundColor: _isFollowing
                              ? Colors.green.shade600
                              : theme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (popularSongs.isNotEmpty) {
                            Provider.of<AudioPlayerProvider>(context,
                                    listen: false)
                                .setNewPlaylist(popularSongs, 0);
                          }
                        },
                        icon: const Icon(Icons.shuffle_rounded),
                        label: const Text('Shuffle'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSectionHeader(context, 'Popular Songs'),
                const SizedBox(height: 8),
                if (popularSongs.isEmpty)
                  const Text('No featured songs.')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: popularSongs.length,
                    itemBuilder: (context, index) {
                      return _buildSongTile(
                          context, popularSongs[index], index + 1, photoUrl,popularSongs);
                    },
                  ),

                const SizedBox(height: 10),
                _buildSectionHeader(context, 'Albums'),
                const SizedBox(height: 10),
                if (albums.isEmpty)
                  const Text('No albums found.')
                else
                  _buildAlbumList(context, albums),
              ],
            ),
          ),
        ),
      ],
    );
  }

  SliverAppBar _buildSliverAppBar(
      BuildContext context, String photoUrl, bool isDark) {
    return SliverAppBar(
      expandedHeight: 320.0,
      pinned: true,
      elevation: 2,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: isDark ? Colors.white : Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16, left: 50, right: 50),
        title: Text(
          widget.artistName,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey.shade400),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  CircleAvatar(
                    radius: 70,
                    backgroundImage:
                        photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    onBackgroundImageError: (_, __) {},
                    child: photoUrl.isEmpty
                        ? const Icon(Icons.person, size: 70)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '1.2M Listeners',
                    style: TextStyle(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildSongTile(
      BuildContext context, Songs song, int rank, String artistPhotoUrl,List<Songs> playlist) {
    final audioProvider =
        Provider.of<AudioPlayerProvider>(context, listen: false);
        final songWithThumbnail = song.copyWith(
      thumbnail: song.thumbnail.isNotEmpty ? song.thumbnail : artistPhotoUrl,
    );
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDark ? Colors.white : Colors.black;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              song.thumbnail.isNotEmpty ? song.thumbnail : artistPhotoUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 50,
                height: 50,
                color: Colors.grey.shade300,
                child: const Icon(Icons.music_note, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),

      trailing: FutureBuilder<bool>(
        future: repostService.isSongReposted(songWithThumbnail.id),
        builder: (context, snapshot) {
          final currentlyReposted = snapshot.data ?? false;
          final isRepostCheckLoading = snapshot.connectionState == ConnectionState.waiting;

          return PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            onSelected: (value) async {
                                              final prefs = await SharedPreferences.getInstance();
                                              final token = prefs.getString('token');

                                              if (token == null || token.isEmpty) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Please log in to use this feature 🔒'), duration: Duration(seconds: 2)));
                                                Future.delayed(const Duration(seconds: 1), () {
                                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                                                });
                                                return;
                                              }
                                  
                                              if (value == 'favorite') {
                                                favoriteService.addFavorite(songWithThumbnail);
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to favorites 💙'), duration: Duration(seconds: 1)));
                                                
                                              } else if (value == 'playlist') {
                                                _showAddToPlaylistDialog(songWithThumbnail);
                                                
                                              } else if (value == 'repost_toggle') {
                                    
                                                final bool currentlyReposted = await repostService.isSongReposted(songWithThumbnail.id);
                                                try {
                                                  final newStatus = await repostService.toggleRepost(songWithThumbnail, currentlyReposted);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(newStatus ? 'Reposted to Profile!' : 'Repost cancelled.'),
                                                      backgroundColor: newStatus ? Colors.green : Colors.grey,
                                                    ),
                                                  );
                                                 
                                                } catch (e) {
                                                     ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Repost Error: ${e.toString().replaceFirst('Exception: ', '')}')),
                                                  );
                                                }
                                              }
                                            },
            color: isDark ? const Color(0xFF2E2E2E) : Colors.white,
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'favorite',
                child: Row(
                  children: [
                    Icon(Icons.favorite_border, color: Colors.red),
                    const SizedBox(width: 10),
                    Text('Add to favorites', style: TextStyle(color: color)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'playlist',
                child: Row(
                  children: [
                    Icon(Icons.playlist_add, color: color),
                    const SizedBox(width: 10),
                    Text('Add to another playlist', style: TextStyle(color: color)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'repost_toggle',
                child: isRepostCheckLoading
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Loading status...'),
                        ],
                      )
                    : Row(
                        children: [
                          Icon(
                            Icons.repeat,
                            color: currentlyReposted
                                ? theme.primaryColor
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            currentlyReposted ? 'Cancel Repost' : 'Repost to Profile',
                            style: TextStyle(
                              color: currentlyReposted
                                  ? theme.primaryColor
                                  : color,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
      onTap: () {
        if (song.thumbnail.isEmpty) {
          song.thumbnail = artistPhotoUrl;
        }
        final indexToPlay = playlist.indexOf(song);
        if (indexToPlay != -1) {
          Provider.of<AudioPlayerProvider>(context, listen: false)
              .setNewPlaylist(playlist, indexToPlay);
        } else {
          audioProvider.playSong(song);
        }
      },
    );
  }

  Widget _buildAlbumList(BuildContext context, List<Album> albums) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlbumDetailScreen(
                    albumName: album.name,
                    albumImage: album.url,
                  ),
                ),
              );
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      album.url,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 140,
                        height: 140,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.album, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
