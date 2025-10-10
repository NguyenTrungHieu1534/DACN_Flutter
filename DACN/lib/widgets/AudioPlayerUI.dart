import 'package:flutter/material.dart';
import '../models/songs.dart';

class AudioPlayerUI extends StatelessWidget {
  final Songs song;
  final bool isPlaying;
  final double progress; // giá trị 0-1 cho Slider
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final String thumbnailUrl;

  const AudioPlayerUI({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.progress,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrev,
    required this.thumbnailUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Column(
        children: [
          // Tên bài hát & nghệ sĩ
          Text(song.title,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(song.artist,
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 20),

          // Đĩa quay
          SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RotationTransition(
                  turns: AlwaysStoppedAnimation(isPlaying ? 1 : 0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(thumbnailUrl),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 8)
                      ],
                    ),
                  ),
                ),
                // Optional: overlay play icon when paused
                if (!isPlaying)
                  const Icon(Icons.play_arrow, size: 60, color: Colors.white70),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Slider progress
          Slider(
            value: progress,
            onChanged: (_) {}, // bind sau với AudioPlayer
            min: 0,
            max: 1,
            activeColor: Colors.deepOrange,
            inactiveColor: Colors.grey.shade300,
          ),

          const SizedBox(height: 20),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                iconSize: 40,
                onPressed: onPrev,
              ),
              IconButton(
                icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
                iconSize: 70,
                onPressed: onPlayPause,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                iconSize: 40,
                onPressed: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
