import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/songs.dart';
import '../widgets/AudioPlayerUI.dart';
import 'package:just_audio/just_audio.dart';

class BuildNaviBot extends StatefulWidget {
  final int currentIndex;
  final Function(int) onItemSelected;

  BuildNaviBot({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });
  @override
  State<BuildNaviBot> createState() => BuildNaviBotState();
}

class BuildNaviBotState extends State<BuildNaviBot>
    with SingleTickerProviderStateMixin {
  Songs? currentPlaying;
  late AnimationController _rotationController;
  late AudioPlayer _audioPlayer;
  late AudioPlayerUI _audioPlayerUI;
  bool isPlaying = false;
  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _audioPlayer = AudioPlayer();
    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        isPlaying = state.playing;
      });

      if (state.processingState == ProcessingState.completed) {
        _rotationController.stop();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 40, right: 40),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
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
          _dockItem(Icons.search_rounded, "Search", 1, widget.currentIndex,
              widget.onItemSelected),
          _dockItem(Icons.favorite_rounded, "Favorites", 2, widget.currentIndex,
              widget.onItemSelected),
          _dockItem(Icons.person_rounded, "Profile", 3, widget.currentIndex,
              widget.onItemSelected),
        ],
      ),
    );
  }

  Widget _dockItem(IconData icon, String label, int index, int currentIndex,
      Function(int) onTap) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSlide(
              offset: isActive ? const Offset(0, -0.15) : Offset.zero,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: AnimatedScale(
                scale: isActive ? 1.3 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: Icon(
                  icon,
                  size: isActive ? 34 : 28,
                  color: isActive ? Colors.blueAccent : Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedOpacity(
              opacity: isActive ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
