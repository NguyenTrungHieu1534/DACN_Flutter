import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/AudioPlayerProvider.dart';
import '../screens/player_screen.dart';
import 'autoScroollerText.dart';
import '../navigation/custom_page_route.dart';

class MiniPlayerWidget extends StatefulWidget {
  const MiniPlayerWidget({super.key});

  @override
  State<MiniPlayerWidget> createState() => _MiniPlayerWidgetState();
}

class _MiniPlayerWidgetState extends State<MiniPlayerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayerProvider = Provider.of<AudioPlayerProvider>(context);
    final isPlaying = audioPlayerProvider.isPlaying;
    final currentPlaying = audioPlayerProvider.currentPlaying;

    if (currentPlaying == null) {
      return const SizedBox.shrink();
    }

    if (isPlaying && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!isPlaying && _rotationController.isAnimating) {
      _rotationController.stop();
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          ModalSlideUpPageRoute(child: PlayerScreen(song: currentPlaying)),
        );
      },
      child: Container(
        height: 60,
        margin: const EdgeInsets.only(left: 40, right: 40, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
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
            RotationTransition(
              turns: _rotationController,
              child: CircleAvatar(
                backgroundImage: NetworkImage(currentPlaying.thumbnail),
                radius: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: autoTextScroller(
                currentPlaying.title,
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    );
  }
}