import 'package:flutter/material.dart';
import '../models/songs.dart';

class AudioPlayerUI extends StatelessWidget {
  final Songs song;
  final bool isPlaying;
  final Duration position; // Change to Duration
  final Duration duration; // Add duration
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final ValueChanged<double> onSeek; // Add onSeek callback
  final String thumbnailUrl;

  const AudioPlayerUI({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrev,
    required this.onSeek,
    required this.thumbnailUrl,
  });
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade100, Colors.pink.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Song info
          Text(
            song.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            song.artist,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.brown,
            ),
          ),
          const SizedBox(height: 12),

          // Album art / Disk
          SizedBox(
            width: screenWidth * 0.3,
            height: screenWidth * 0.3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                RotationTransition(
                  turns: AlwaysStoppedAnimation(isPlaying ? 1 : 0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.orangeAccent, Colors.deepOrange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      image: DecorationImage(
                        image: NetworkImage(thumbnailUrl),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.1),
                          BlendMode.darken,
                        ),
                      ),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4))
                      ],
                    ),
                  ),
                ),
                if (!isPlaying)
                  const Icon(Icons.play_arrow_rounded,
                      size: 48, color: Colors.white70),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Progress bar
          Row(
            children: [
              Text(
                _formatDuration(position),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    inactiveTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    trackHeight: 3,
                    thumbColor: Theme.of(context).colorScheme.primary,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: position.inMilliseconds
                        .toDouble()
                        .clamp(0, duration.inMilliseconds.toDouble()),
                    onChanged: onSeek,
                    min: 0,
                    max: duration.inMilliseconds.toDouble(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(duration),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _controlButton(Icons.skip_previous_rounded, onPrev, size: 28),
              _controlButton(
                isPlaying
                    ? Icons.pause_circle_rounded
                    : Icons.play_circle_rounded,
                onPlayPause,
                size: 50,
                gradient: const LinearGradient(
                  colors: [Colors.orangeAccent, Colors.deepOrange],
                ),
              ),
              _controlButton(Icons.skip_next_rounded, onNext, size: 28),
            ],
          ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onTap,
      {double size = 40, Gradient? gradient}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
          color: gradient == null ? Colors.brown.shade200 : null,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: size * 0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}
