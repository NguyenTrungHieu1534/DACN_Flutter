import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spinController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.oceanDeep,
                  AppColors.oceanBlue,
                  AppColors.skyBlue,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.more_horiz, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Spinning disc
                RotationTransition(
                  turns: _spinController,
                  child: _Disc(),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 16),
                      // Animated chill slider (value fixed at 0)
                      _ChillSlider(controller: _shimmerController),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('0:00', style: TextStyle(color: Colors.white70)),
                          Text('0:00', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shuffle),
                            color: Colors.white70,
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded),
                            color: Colors.white,
                            iconSize: 36,
                            onPressed: () {},
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.play_arrow),
                              color: AppColors.oceanBlue,
                              iconSize: 36,
                              onPressed: () {},
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded),
                            color: Colors.white,
                            iconSize: 36,
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.repeat),
                            color: Colors.white70,
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Lyrics space placeholder
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Lyrics',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const LyricsScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text('Open'),
                                )
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Lyrics will appear here...\nTap Open to view in full screen.',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.black87),
                            ),
                          ],
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

class _Disc extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      width: 320,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          colors: [
            Colors.white,
            Colors.white70,
            Colors.white,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 16),
          )
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Center(
          child: Container(
            height: 64,
            width: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black12,
            ),
            child: const Icon(Icons.music_note, size: 34, color: Colors.black45),
          ),
        ),
      ),
    );
  }
}

class _ChillSlider extends StatelessWidget {
  const _ChillSlider({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final Animation<double> anim = Tween<double>(begin: -1, end: 2).animate(CurvedAnimation(
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
                  color: Colors.white24,
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
                        Colors.white.withOpacity(0.6),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      transform: GradientTranslation(anim.value * rect.width, 0),
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.srcATop,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white30,
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
                    color: Colors.white,
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
        backgroundColor: AppColors.oceanBlue,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.oceanDeep,
              AppColors.oceanBlue,
              AppColors.skyBlue,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: const [
              SizedBox(height: 16),
              Text(
                'Lyrics will be displayed here.\n\nThis page is ready for integration with real lyrics later.',
                style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
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


