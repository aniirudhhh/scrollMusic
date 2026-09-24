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

class _WavyProgressBarState extends State<WavyProgressBar> with SingleTickerProviderStateMixin {
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
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
      
    final thumbPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    // 1. Draw Active Track (Wavy)
    final path = Path();
    final waveAmplitude = 4.0;
    final waveFrequency = 0.25; 
    
    path.moveTo(0, centerY);
    
    for (double x = 0; x <= thumbX; x += 2.0) {
      // Smooth taper off at the ends so it connects nicely
      double taper = 1.0;
      if (x < 10) {
        taper = x / 10.0;
      }
      if (thumbX - x < 15) {
        taper = (thumbX - x) / 15.0;
      }
      
      final y = centerY + math.sin((x * waveFrequency) - phase) * waveAmplitude * taper;
      path.lineTo(x, y);
    }
    
    // Ensure it ends exactly at thumb center vertically
    path.lineTo(thumbX, centerY);
    canvas.drawPath(path, activePaint);
    
    // 2. Draw Inactive Track (Straight line)
    canvas.drawLine(Offset(thumbX, centerY), Offset(size.width, centerY), inactivePaint);
    
    // 3. Draw Thumb
    canvas.drawCircle(Offset(thumbX, centerY), 6.0, thumbPaint);
  }

  @override
  bool shouldRepaint(covariant _WavyPainter oldDelegate) {
    return oldDelegate.value != value || 
           oldDelegate.phase != phase ||
           oldDelegate.activeColor != activeColor ||
           oldDelegate.inactiveColor != inactiveColor;
  }
}
