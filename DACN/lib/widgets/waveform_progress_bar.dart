import 'dart:math' as math;
import 'package:flutter/material.dart';

class WaveformProgressBar extends StatefulWidget {
  final Duration progress;
  final Duration total;
  final Function(Duration) onSeek;
  final Color waveColor;
  final Color progressColor;

  const WaveformProgressBar({
    super.key,
    required this.progress,
    required this.total,
    required this.onSeek,
    this.waveColor = Colors.white38,
    this.progressColor = Colors.white,
  });

  @override
  State<WaveformProgressBar> createState() => _WaveformProgressBarState();
}

class _WaveformProgressBarState extends State<WaveformProgressBar> {
  late List<double> _waveformData;

  @override
  void initState() {
    super.initState();
    _waveformData = _generateWaveformData(100);
  }

  List<double> _generateWaveformData(int count) {
    final random = math.Random();
    return List<double>.generate(
        count, (i) => (random.nextDouble() * 0.8) + 0.2);
  }

  void _handleDragUpdate(DragUpdateDetails details, double width) {
    final progress = (details.localPosition.dx / width).clamp(0.0, 1.0);
    final seekPosition = widget.total * progress;
    widget.onSeek(seekPosition);
  }

  void _handleTapDown(TapDownDetails details, double width) {
    final progress = (details.localPosition.dx / width).clamp(0.0, 1.0);
    final seekPosition = widget.total * progress;
    widget.onSeek(seekPosition);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) => _handleTapDown(details, constraints.maxWidth),
          onHorizontalDragUpdate: (details) =>
              _handleDragUpdate(details, constraints.maxWidth),
          child: CustomPaint(
            size: Size(constraints.maxWidth, 50),
            painter: _WaveformPainter(
              waveformData: _waveformData,
              progress: widget.progress,
              total: widget.total,
              waveColor: widget.waveColor,
              progressColor: widget.progressColor,
            ),
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Duration progress;
  final Duration total;
  final Color waveColor;
  final Color progressColor;

  _WaveformPainter({
    required this.waveformData,
    required this.progress,
    required this.total,
    required this.waveColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = waveColor;

    final progressPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = progressColor;

    final barWidth = size.width / (waveformData.length * 2 - 1);
    final barSpacing = barWidth;

    for (int i = 0; i < waveformData.length; i++) {
      final barHeight = waveformData[i] * size.height;
      final x = i * (barWidth + barSpacing);
      final y = (size.height - barHeight) / 2;
      final rect = Rect.fromLTWH(x, y, barWidth, barHeight);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
    }

    final progressRatio = (total.inMilliseconds == 0)
        ? 0.0
        : (progress.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final progressWidth = size.width * progressRatio;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, progressWidth, size.height));

    for (int i = 0; i < waveformData.length; i++) {
      final barHeight = waveformData[i] * size.height;
      final x = i * (barWidth + barSpacing);
      final y = (size.height - barHeight) / 2;
      final rect = Rect.fromLTWH(x, y, barWidth, barHeight);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          progressPaint);
    }

    canvas.restore();

    final handleX = progressWidth;
    final handlePaint = Paint()
      ..color = progressColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.fill;

    final handlePath = Path()
      ..moveTo(handleX, 0)
      ..lineTo(handleX, size.height);

    canvas.drawPath(handlePath, handlePaint);
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.total != total ||
        oldDelegate.waveColor != waveColor ||
        oldDelegate.progressColor != progressColor;
  }
}
