import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/songs.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  /// You can either pass a [Songs] object via [song], or provide [title]/[subtitle]/[imageUrl]/[heroTag] manually.
  const PlayerScreen({
    super.key,
    this.song,
    this.title,
    this.subtitle,
    this.imageUrl,
    this.heroTag,
  });

  final Songs? song;
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final Object? heroTag;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    // no spinning animation needed for cover-layout
    _shimmerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    // Resolve display fields (supports either passing a Songs object or individual fields)
    final displayImage = widget.song?.thumbnail ?? widget.imageUrl;
    final displayTitle = widget.song?.title ?? widget.title ?? 'Unknown Title';
    final displaySubtitle = widget.song?.artist ?? widget.subtitle ?? '';
    final screenHeight = MediaQuery.of(context).size.height;
    final topHeight = screenHeight * 0.33; // top 1/3
    return Scaffold(
      body: Stack(
        children: [
          // Base blue retro background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.retroPrimary,
                    Color.fromARGB(255, 112, 150, 193),
                    AppColors.retroWhite,
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Top cover image occupying 1/3 of the screen
          if (displayImage != null && displayImage.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    displayImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: AppColors.retroPrimary),
                  ),
                  // Slight blur to soften cover
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                    child: Container(color: Colors.black.withOpacity(0.08)),
                  ),
                  // Gradient fade from cover into blue retro background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00000000), // transparent top
                          AppColors.retroAccent.withOpacity(0.3),
                          AppColors.retroAccent.withOpacity(0.8),
                        ],
                        stops: const [0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // A subtle additional overlay across whole screen for Hawaii/retro warmth
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: AppColors.retroWhite),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: AppColors.retroWhite),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Show a centered album cover thumbnail (no spinning disc)
                if (displayImage != null && displayImage.isNotEmpty)
                  Center(
                    child: Hero(
                      tag: widget.song?.id ?? widget.heroTag ?? displayImage,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          displayImage,
                          width: 160,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 160,
                            height: 160,
                            color: AppColors.retroWhite.withOpacity(0.7),
                            child: const Icon(Icons.album, size: 48),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 160),

                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.retroWhite,
                          fontWeight: FontWeight.w800,
                          shadows: const [
                            Shadow(
                              offset: Offset(0, 4),
                              blurRadius: 8,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displaySubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.retroWhite.withOpacity(0.95),
                          fontWeight: FontWeight.w600,
                          shadows: const [
                            Shadow(
                              offset: Offset(0, 3),
                              blurRadius: 6,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Animated chill slider (value fixed at 0)
                      _ChillSlider(controller: _shimmerController),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text('0:00', style: TextStyle(color: AppColors.retroWhite.withOpacity(0.7))),
                          Text('0:00', style: TextStyle(color: AppColors.retroWhite.withOpacity(0.7))),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shuffle),
                            color: AppColors.retroWhite.withOpacity(0.7),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded),
                            color: AppColors.retroWhite,
                            iconSize: 40,
                            onPressed: () {},
                          ),

                          // Bigger play button with glow
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.retroWhite,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.retroWhite.withOpacity(0.9),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: AppColors.retroAccent.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.play_arrow),
                              color: AppColors.retroAccent,
                              iconSize: 44,
                              onPressed: () {},
                            ),
                          ),

                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded),
                            color: AppColors.retroWhite,
                            iconSize: 40,
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.repeat),
                            color: AppColors.retroWhite.withOpacity(0.7),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Lyrics box: semi-transparent glassmorphism effect
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.retroWhite.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.retroWhite.withOpacity(0.12)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Lyrics',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.retroWhite,
                                          ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const LyricsScreen(),
                                          ),
                                        );
                                      },
                                      child: Text('Open', style: TextStyle(color: AppColors.retroAccent),),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Lyrics will appear here.\nTap Open to view in full screen.',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: AppColors.retroWhite.withOpacity(0.7)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// removed spinning disco widgets; using cover image as top background + static thumbnail

class _ChillSlider extends StatelessWidget {
  const _ChillSlider({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final Animation<double> anim =
        Tween<double>(begin: -1, end: 2).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));

    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        return Container(
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Base track
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.retroWhite.withOpacity(0.24),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Animated shimmer wave
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 1,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        AppColors.retroWhite.withOpacity(0.6),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      transform:
                          GradientTranslation(anim.value * rect.width, 0),
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.srcATop,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.retroWhite.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              // Thumb at 0
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 12,
                  width: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.retroWhite,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class LyricsScreen extends StatelessWidget {
  const LyricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lyrics'),
        backgroundColor: AppColors.retroPrimary,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.retroPrimary,
              Color.fromARGB(255, 112, 150, 193),
              AppColors.retroWhite,
            ],
          ),
        ),
        child: const SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(height: 16),
              Text(
                'Lyrics will be displayed here.\n\nThis page is ready for integration with real lyrics later.',
                style:
                    TextStyle(color: AppColors.retroWhite, fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GradientTranslation extends GradientTransform {
  const GradientTranslation(this.dx, this.dy);
  final double dx;
  final double dy;
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.identity()..translate(dx, dy);
  }
}
