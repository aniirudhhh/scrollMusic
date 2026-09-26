import 'dart:math' as math;
import 'package:flutter/material.dart';

class WavyProgressBar extends StatefulWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final Color activeColor;
  final Color inactiveColor;
  final bool isPaused;

  const WavyProgressBar({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.white24,
    this.isPaused = false,
  });

  @override
  State<WavyProgressBar> createState() => _WavyProgressBarState();
}

class _WavyProgressBarState extends State<WavyProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (!widget.isPaused) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(WavyProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _controller.stop();
      } else {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleUpdate(Offset localPosition, Size size) {
    if (widget.onChanged != null) {
      final dx = localPosition.dx.clamp(0.0, size.width);
      widget.onChanged!(dx / size.width);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        _handleUpdate(details.localPosition, box.size);
      },
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        _handleUpdate(details.localPosition, box.size);
      },
      child: Container(
        height: 32, // Generous touch target
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _WavyPainter(
                value: widget.value,
                phase: _controller.value * 2 * math.pi, // 0 to 2*PI
                activeColor: widget.activeColor,
                inactiveColor: widget.inactiveColor,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WavyPainter extends CustomPainter {
  final double value;
  final double phase;
  final Color activeColor;
  final Color inactiveColor;

  _WavyPainter({
    required this.value,
    required this.phase,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final thumbX = size.width * value;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    final inactivePaint = Paint()
      ..color = activeColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    // 1. Draw Inactive Track (Straight line)
    // Add a gap of 12 pixels between the active track and inactive track
    final inactiveStartX = math.min(thumbX + 12.0, size.width);
    if (inactiveStartX < size.width) {
      canvas.drawLine(
        Offset(inactiveStartX, centerY),
        Offset(size.width, centerY),
        inactivePaint,
      );
    }

    // 2. Draw Active Track (Wavy)
    final path = Path();
    final waveAmplitude = 2.5; // Much smaller amplitude (gentle wave)
    final waveFrequency = 0.12; // Much longer wavelength (stretched out)

    path.moveTo(0, centerY);

    for (double x = 0; x <= thumbX; x += 8.0) {
      // Gentle taper only at the very start so it doesn't jump
      double taper = 1.0;
      if (x < 12) {
        taper = x / 12.0;
      }
      // Removed the end taper to let it act like a true chopped wave

      final y =
          centerY +
          math.sin((x * waveFrequency) - phase) * waveAmplitude * taper;
      path.lineTo(x, y);
    }

    // Ensure the wave reaches exactly the thumbX position
    final finalY =
        centerY + math.sin((thumbX * waveFrequency) - phase) * waveAmplitude;
    path.lineTo(thumbX, finalY);

    // Draw the active path
    canvas.drawPath(path, activePaint);

    // Draw tiny dot at the very end of the inactive track
    final endDotPaint = Paint()
      ..color = activeColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width - 2, centerY), 2.5, endDotPaint);
  }

  @override
  bool shouldRepaint(covariant _WavyPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.phase != phase ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
