import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import '../screens/setting_screen.dart';
import '../models/ThemeProvider.dart';
import '../services/api_user.dart';
import '../screens/playlist_detail_screen.dart';
import '../screens/playlist_screen.dart';
import '../navigation/custom_page_route.dart';
import '../services/api_playlist.dart';
import '../services/api_history.dart';
import '../theme/app_theme.dart';
import '../models/playlist.dart';
import '../services/api_follow.dart';
import '../screens/artist_detail_screen.dart';
import 'notification_list_screen.dart';
import '../services/socket_service.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen>
    with SingleTickerProviderStateMixin {
  String? _token;
  bool _loading = true;

  String? _userId;
  String? _username;
  String? _email;
  String? _avatar;
  bool isUploading = false;
  List<Map<String, String>> _recentArtists = [];
  List<Map<String, dynamic>> _followedArtists = [];
  List<Playlist> _userPlaylists = [];
  final FollowService _followService = FollowService();
  bool _loadingData = false;
  int _notificationCount = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _setupSocketListener();
    _checkToken();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _setupSocketListener() {
    final socketService = SocketService();
    final events = ['nofiNewSongAritst', 'unartists', 'turnartists', 'newfollower'];
    for (final e in events) {
      socketService.registerEventHandler(e, (data) {
        if (mounted) {
          setState(() => _notificationCount++);
        }
      });
    }
  }
  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('token');

    if (stored == null || stored.trim().isEmpty) {
      setState(() => _loading = false);
      return;
    }

    final rawToken = stored.startsWith('Bearer ')
        ? stored.substring(7).trim()
        : stored.trim();
    final looksLikeJwt = rawToken.split('.').length == 3;

    if (!looksLikeJwt) {
      setState(() => _loading = false);
      return;
    }

    try {
      final Map<String, dynamic> decoded = JwtDecoder.decode(rawToken);
      setState(() {
        _token = rawToken;
        _userId = decoded["_id"];
        _username = decoded["username"];
        _email = decoded["email"];
        _avatar = decoded["ava"];
        _loading = false;
      });

      if (_userId != null) {
        _loadUserData();
        _loadNotificationCount();
        _fadeController.forward();
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadNotificationCount() async {
    if (_userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('thongBaoList');
    if (savedData != null && savedData.isNotEmpty) {
      final allNotifications = jsonDecode(savedData) as Map<String, dynamic>;
      if (allNotifications.containsKey(_userId)) {
        final userNotifications = allNotifications[_userId] as List;
        if (mounted) {
          setState(() {
            _notificationCount = userNotifications.length;
          });
        }
      } else {
        if (mounted) setState(() => _notificationCount = 0);
      }
    } else {
      if (mounted) setState(() => _notificationCount = 0);
    }
  }

  Future<void> _loadUserData() async {
    if (mounted) setState(() => _loadingData = true);

    try {
      final apiPlaylist = ApiPlaylist();
      final playlists = await apiPlaylist.getPlaylistsByUser();
      final historyService = HistoryService();
      final history = await historyService.getHistory();

      // Lấy danh sách nghệ sĩ đã follow
      final followedList = await _followService.getFollowList(_userId!);
      final List<Map<String, dynamic>> followedArtistsDetails = [];
      for (var followedItem in followedList) {
        if (followedItem['targetType'] == 'artist') {
          try {
            final artistInfo = await _followService.getFollowInfo(
              userId: _userId!,
              targetType: 'artist',
              targetId: followedItem['targetId'],
            );
            followedArtistsDetails.add(artistInfo);
          } catch (e) {
            debugPrint(
                'Error fetching follow info for ${followedItem['targetId']}: $e');
          }
        }
      }
      final Map<String, Map<String, String>> artistMap = {};
      for (var song in history.take(20)) {
        if (!artistMap.containsKey(song.artist)) {
          artistMap[song.artist] = {
            'name': song.artist,
            'imageUrl': '',
          };
        }
      }

      if (mounted) {
        setState(() {
          _recentArtists = artistMap.values.take(3).toList();
          _followedArtists = followedArtistsDetails;
          _userPlaylists = playlists;
          _loadingData = false;
        });
      }
      _loadNotificationCount();
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() => _loadingData = false);
      }
    }
  }

  Future<void> _showImagePicker(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Change Profile Picture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.oceanBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library,
                      color: AppColors.oceanBlue),
                ),
                title: const Text('Choose from library'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.oceanBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.camera_alt, color: AppColors.oceanBlue),
                ),
                title: const Text('Take photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);

    if (pickedFile != null) {
      File image = File(pickedFile.path);
      setState(() => isUploading = true);

      final result =
          await UserService().uploadAvatar(_userId.toString(), image);

      if (mounted) {
        setState(() => isUploading = false);

        if (result['url'] != null) {
          setState(() => _avatar = result['url']);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text("Profile picture updated!"),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text("Error: ${result['details']}")),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final avatarRadius = isTablet ? 80.0 : 60.0;

    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.oceanBlue),
              const SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_token == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 48 : 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 32 : 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.oceanBlue.withOpacity(0.1),
                        AppColors.skyBlue.withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: isTablet ? 120 : 80,
                    color: AppColors.oceanBlue,
                  ),
                ),
                SizedBox(height: isTablet ? 32 : 24),
                Text(
                  'Sign in to view your profile',
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Access your playlists and listening history',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isTablet ? 32 : 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 48 : 32,
                      vertical: isTablet ? 20 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: AppColors.oceanBlue,
        child: CustomScrollView(
          slivers: [
            // Custom App Bar với avatar
            SliverAppBar(
              expandedHeight: isTablet ? 320 : 260,
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors:
                              Theme.of(context).brightness == Brightness.dark
                                  ? [
                                      const Color(0xFF1A2332),
                                      const Color(0xFF0D1117),
                                    ]
                                  : [
                                      AppColors.skyBlue.withOpacity(0.4),
                                      AppColors.oceanBlue.withOpacity(0.2),
                                    ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.oceanBlue.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.skyBlue.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                height:
                                    MediaQuery.of(context).padding.top + 40),
                            GestureDetector(
                              onTap: () => _showImagePicker(context),
                              child: Hero(
                                tag: 'user_avatar',
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.oceanBlue
                                                .withOpacity(0.3),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: avatarRadius,
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        backgroundImage: _avatar != null &&
                                                _avatar!.isNotEmpty
                                            ? NetworkImage(_avatar!)
                                            : null,
                                        child:
                                            _avatar == null || _avatar!.isEmpty
                                                ? Icon(
                                                    Icons.person,
                                                    size: avatarRadius,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.3),
                                                  )
                                                : null,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding:
                                            EdgeInsets.all(isTablet ? 10 : 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.oceanBlue,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .scaffoldBackgroundColor,
                                            width: 3,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.camera_alt,
                                          size: isTablet ? 20 : 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (isUploading)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: isTablet ? 20 : 16),
                            // Username
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                _username ?? 'User',
                                style: TextStyle(
                                  fontSize: isTablet ? 32 : 26,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Email
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                _email ?? '',
                                style: TextStyle(
                                  fontSize: isTablet ? 16 : 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined),
                      if (_notificationCount > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$_notificationCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  tooltip: 'Notifications',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) {
                      return NotificationListScreen(onNotificationsCleared: () {
                        setState(() => _notificationCount = 0);
                      });
                    })).then((_) => _loadNotificationCount());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 24 : 16,
                isTablet ? 16 : 8,
                isTablet ? 24 : 16,
                isTablet ? 32 : 24,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isTablet ? 1.5 : 1.3,
                ),
                delegate: SliverChildListDelegate([
                  _buildStatCard(
                    icon: Icons.library_music,
                    label: 'Playlists',
                    value: '${_userPlaylists.length}',
                    color: AppColors.oceanBlue,
                    isTablet: isTablet,
                  ),
                  _buildStatCard(
                    icon: Icons.history,
                    label: 'Artists Played',
                    value: '${_recentArtists.length}',
                    color: AppColors.skyBlue,
                    isTablet: isTablet,
                  ),
                  if (isTablet)
                    _buildStatCard(
                      icon: Icons.music_note,
                      label: 'Total Songs',
                      value:
                          '${_userPlaylists.fold<int>(0, (sum, p) => sum + p.songs.length)}',
                      color: AppColors.oceanDeep,
                      isTablet: isTablet,
                    ),
                ]),
              ),
            ),
            if (_followedArtists.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 24 : 16,
                  isTablet ? 24 : 16,
                  isTablet ? 24 : 16,
                  isTablet ? 16 : 12,
                ),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Followed Artists',
                    style: TextStyle(
                      fontSize: isTablet ? 26 : 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            if (_followedArtists.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: isTablet ? 180 : 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding:
                        EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
                    itemCount: _followedArtists.length,
                    itemBuilder: (context, index) {
                      final artist = _followedArtists[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            FadePageRoute(
                              child: ArtistDetailScreen(
                                  artistName: artist['name'] ?? artist['username']?? 'N/A'),
                            ),
                          );
                        },
                        child: Container(
                          width: isTablet ? 120 : 100,
                          margin: const EdgeInsets.only(right: 16),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: isTablet ? 50 : 40,
                                backgroundImage: (artist['avatarUrl'] != null &&
                                        artist['avatarUrl'].isNotEmpty)
                                    ? NetworkImage(artist['avatarUrl'])
                                    : (artist['avatar'] != null &&
                                            artist['avatar'].isNotEmpty)
                                        ? NetworkImage(artist['avatar'])
                                        : null,
                                child: (artist['avatarUrl'] == null ||
                                            artist['avatarUrl'].isEmpty) &&
                                        (artist['avatar'] == null ||
                                            artist['avatar'].isEmpty)
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              Text(artist['name'] ?? artist['username'] ?? 'N/A',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 24 : 16,
                isTablet ? 16 : 8,
                isTablet ? 24 : 16,
                isTablet ? 16 : 12,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Playlists',
                      style: TextStyle(
                        fontSize: isTablet ? 26 : 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (_userPlaylists.length > 3)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            FadePageRoute(child: const PlaylistScreen()),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('See all'),
                      ),
                  ],
                ),
              ),
            ),
            if (_loadingData)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (_userPlaylists.isEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.all(isTablet ? 24 : 16),
                  padding: EdgeInsets.all(isTablet ? 48 : 32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.playlist_add,
                        size: isTablet ? 80 : 64,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.3),
                      ),
                      SizedBox(height: isTablet ? 24 : 16),
                      Text(
                        'No playlists yet',
                        style: TextStyle(
                          fontSize: isTablet ? 22 : 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: isTablet ? 12 : 8),
                      Text(
                        'Create your first playlist to organize your music',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                      SizedBox(height: isTablet ? 24 : 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            FadePageRoute(child: const PlaylistScreen()),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Playlist'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 32 : 24,
                            vertical: isTablet ? 16 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >=
                          (_userPlaylists.length > 3
                              ? 3
                              : _userPlaylists.length)) {
                        return const SizedBox.shrink();
                      }
                      final playlist = _userPlaylists[index];
                      return _buildPlaylistItem(playlist, isTablet);
                    },
                    childCount:
                        _userPlaylists.length > 3 ? 3 : _userPlaylists.length,
                  ),
                ),
              ),
            if (_recentArtists.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isTablet ? 24 : 16,
                  isTablet ? 32 : 24,
                  isTablet ? 24 : 16,
                  isTablet ? 16 : 12,
                ),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Recently Played Artists',
                    style: TextStyle(
                      fontSize: isTablet ? 26 : 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            if (_recentArtists.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final artist = _recentArtists[index];
                      return _buildArtistItem(artist, isTablet);
                    },
                    childCount: _recentArtists.length,
                  ),
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: isTablet ? 120 : 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: isTablet ? 36 : 28),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: isTablet ? 6 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistItem(Playlist playlist, bool isTablet) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 12 : 8,
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: playlist.picUrl.isNotEmpty
              ? Image.network(
                  playlist.picUrl,
                  width: isTablet ? 64 : 56,
                  height: isTablet ? 64 : 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: isTablet ? 64 : 56,
                    height: isTablet ? 64 : 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.oceanBlue.withOpacity(0.2),
                          AppColors.skyBlue.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.music_note,
                        color: AppColors.oceanBlue, size: isTablet ? 32 : 28),
                  ),
                )
              : Container(
                  width: isTablet ? 64 : 56,
                  height: isTablet ? 64 : 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.oceanBlue.withOpacity(0.2),
                        AppColors.skyBlue.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.music_note,
                      color: AppColors.oceanBlue, size: isTablet ? 32 : 28),
                ),
        ),
        title: Text(
          playlist.name,
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${playlist.songs.length} songs',
          style: TextStyle(
            fontSize: isTablet ? 15 : 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          size: isTablet ? 28 : 24,
        ),
        onTap: () {
          Navigator.push(
            context,
            FadePageRoute(child: PlaylistDetailScreen(playlist: playlist)),
          );
        },
      ),
    );
  }

  Widget _buildArtistItem(Map<String, String> artist, bool isTablet) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 16 : 12,
          vertical: isTablet ? 12 : 8,
        ),
        leading: CircleAvatar(
          radius: isTablet ? 32 : 28,
          backgroundColor: AppColors.skyBlue.withOpacity(0.2),
          backgroundImage: artist['imageUrl']?.isNotEmpty == true
              ? NetworkImage(artist['imageUrl']!)
              : null,
          child: artist['imageUrl']?.isEmpty ?? true
              ? Icon(
                  Icons.person,
                  color: AppColors.skyBlue,
                  size: isTablet ? 32 : 28,
                )
              : null,
        ),
        title: Text(
          artist['name'] ?? 'Unknown Artist',
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Artist',
          style: TextStyle(
            fontSize: isTablet ? 15 : 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          size: isTablet ? 28 : 24,
        ),
        onTap: () {
          Navigator.push(
            context,
            FadePageRoute(
              child: ArtistDetailScreen(artistName: artist['name'] ?? ''),
            ),
          );
        },
      ),
    );
  }
}
