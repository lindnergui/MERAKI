import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lightweight playback waveform. It is painted from a deterministic curve,
/// avoiding an audio decode pass on mobile while still expressing progress.
class AudioWaveform extends StatelessWidget {
  const AudioWaveform({
    required this.progress,
    required this.color,
    this.height = 56,
    super.key,
  });

  final double progress;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _AudioWaveformPainter(
            color: color,
            progress: progress.clamp(0.0, 1.0),
          ),
        ),
      ),
    );
  }
}

class _AudioWaveformPainter extends CustomPainter {
  const _AudioWaveformPainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const bars = 54;
    const spacing = 3.0;
    final barWidth = (size.width - ((bars - 1) * spacing)) / bars;
    final center = size.height / 2;
    final playedPaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round;
    final pendingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..strokeCap = StrokeCap.round;

    for (var index = 0; index < bars; index++) {
      final normalized = index / (bars - 1);
      final amplitude =
          0.22 +
          0.72 *
              ((math.sin(index * 1.73).abs() * 0.58) +
                  (math.cos(index * 0.43).abs() * 0.42));
      final halfHeight = math.max(3.0, size.height * amplitude / 2);
      final x = index * (barWidth + spacing) + barWidth / 2;
      canvas.drawLine(
        Offset(x, center - halfHeight),
        Offset(x, center + halfHeight),
        normalized <= progress ? playedPaint : pendingPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_AudioWaveformPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}
