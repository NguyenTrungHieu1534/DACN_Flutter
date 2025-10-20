import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../theme/app_theme.dart';
import '../models/AudioPlayerProvider.dart'; // Import AudioPlayerProvider
import '../widgets/autoScroollerText.dart';
import '../screens/player_screen.dart';
import '../models/songs.dart';

class BuildNaviBot extends StatefulWidget {
  final int currentIndex;
  final Function(int) onItemSelected;
  final bool hasInternet;
  final VoidCallback? onRetry;

  const BuildNaviBot({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    this.hasInternet = true,
    this.onRetry,
  });
  @override
  State<BuildNaviBot> createState() => BuildNaviBotState();
}

class BuildNaviBotState extends State<BuildNaviBot>
    with SingleTickerProviderStateMixin {
  Songs? currentPlaying; // Managed by AudioPlayerProvider
  late AnimationController
      _rotationController; // Reintroduce rotation controller
  // late AudioPlayer _audioPlayer; // Managed by AudioPlayerProvider
  // bool isPlaying = false; // Managed by AudioPlayerProvider

  // bool _playerExpanded = false; // Removed

  // void _togglePlayerExpanded() { // Removed
  //   setState(() {
  //     _playerExpanded = !_playerExpanded;
  //   });
  // }

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // _rotationController = AnimationController(
    //   vsync: this,
    //   duration: const Duration(seconds: 10),
    // );
    // _audioPlayer = AudioPlayer();
    // _audioPlayer.playerStateStream.listen((state) {
    //   setState(() {
    //     isPlaying = state.playing;
    //   });

    //   if (state.processingState == ProcessingState.completed) {
    //     _rotationController.stop();
    //   }
    // });
  }

  @override
  void dispose() {
    _rotationController.dispose(); // Dispose the rotation controller
    // _audioPlayer.dispose(); // No longer managed here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerProvider>(
      builder: (context, audioPlayerProvider, child) {
        final isPlaying = audioPlayerProvider.isPlaying;
        final currentPlaying = audioPlayerProvider.currentPlaying;

        if (isPlaying) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Non-blocking small offline banner shown above the bottom dock
            if (!widget.hasInternet)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.transparent,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Text('Không có kết nối',
                            style: TextStyle(color: Colors.white)),
                        const SizedBox(width: 12),
                        if (widget.onRetry != null)
                          GestureDetector(
                            onTap: widget.onRetry,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.refresh,
                                  color: Colors.white, size: 16),
                            ),
                          )
                      ],
                    ),
                  ),
                ),
              ),
            if (currentPlaying != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: Container(
                  height: 60,
                  margin:
                      const EdgeInsets.only(left: 40, right: 40, bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255)
                        .withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
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
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            RotationTransition(
                              turns: _rotationController,
                              child: CircleAvatar(
                                backgroundImage:
                                    NetworkImage(currentPlaying.thumbnail),
                                radius: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.51,
                              child: autoTextScroller(
                                currentPlaying.title,
                                const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () {
                          audioPlayerProvider.togglePlayPause();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            Container(
              margin: const EdgeInsets.only(bottom: 16, left: 40, right: 40),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color:
                    const Color.fromARGB(255, 255, 255, 255).withOpacity(0.8),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 112, 110, 110)
                        .withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _dockItem(Icons.home_rounded, "Home", 0, widget.currentIndex,
                      widget.onItemSelected),
                  _dockItem(Icons.search_rounded, "Search", 1,
                      widget.currentIndex, widget.onItemSelected),
                  _dockItem(Icons.category_sharp, "Library", 2,
                      widget.currentIndex, widget.onItemSelected),
                  _dockItem(Icons.person_rounded, "Profile", 3,
                      widget.currentIndex, widget.onItemSelected),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dockItem(
    IconData icon,
    String label,
    int index,
    int currentIndex,
    Function(int) onTap,
  ) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: isActive ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: Icon(
              icon,
              size: 24,
              color: isActive ? AppColors.oceanBlue : Colors.grey[600],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: isActive
                ? Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
