import 'dart:math' as math;
import 'package:flutter/material.dart';

class AppleProgressBar extends StatefulWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final Color activeColor;
  final Color inactiveColor;
  final bool isPaused;

  const AppleProgressBar({
    super.key,
    required this.value,
    this.onChanged,
    this.onChangeEnd,
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.white24,
    this.isPaused = false,
  });

  @override
  State<AppleProgressBar> createState() => _AppleProgressBarState();
}

class _AppleProgressBarState extends State<AppleProgressBar> {
  double? _dragValue;
  bool _isDragging = false;

  void _handleDragUpdate(Offset localPosition, Size size) {
    if (widget.onChanged != null || widget.onChangeEnd != null) {
      final dx = localPosition.dx.clamp(0.0, size.width);
      final newValue = dx / size.width;
      setState(() {
        _dragValue = newValue;
      });
      widget.onChanged?.call(newValue);
    }
  }

  void _handleDragEnd() {
    if (_dragValue != null && widget.onChangeEnd != null) {
      widget.onChangeEnd!(_dragValue!);
    }
    setState(() {
      _dragValue = null;
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (details) {
        final box = context.findRenderObject() as RenderBox;
        setState(() => _isDragging = true);
        _handleDragUpdate(details.localPosition, box.size);
      },
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        _handleDragUpdate(details.localPosition, box.size);
      },
      onHorizontalDragEnd: (details) {
        _handleDragEnd();
      },
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        setState(() => _isDragging = true);
        _handleDragUpdate(details.localPosition, box.size);
      },
      onTapUp: (details) {
        _handleDragEnd();
      },
      onTapCancel: () {
        setState(() {
          _dragValue = null;
          _isDragging = false;
        });
      },
      child: SizedBox(
        height: 32, // Generous touch target
        width: double.infinity,
        child: CustomPaint(
          painter: _LinearPainter(
            value: _dragValue ?? widget.value,
            activeColor: widget.activeColor,
            inactiveColor: widget.inactiveColor,
            isDragging: _isDragging,
          ),
        ),
      ),
    );
  }
}

class _LinearPainter extends CustomPainter {
  final double value;
  final Color activeColor;
  final Color inactiveColor;
  final bool isDragging;

  _LinearPainter({
    required this.value,
    required this.activeColor,
    required this.inactiveColor,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final thumbX = size.width * value;
    
    // The exact Apple Music style from the image:
    // A single continuous capsule/pill shape.
    // The active fill has a straight right edge, no circle thumb.
    final trackHeight = 6.0;
    
    // Create the pill shape for the entire track
    final trackRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width / 2, centerY), width: size.width, height: trackHeight),
      const Radius.circular(3.0),
    );

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;
      
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    // 1. Draw the inactive background track
    canvas.drawRRect(trackRect, inactivePaint);

    // 2. Clip to the pill shape so the active fill doesn't spill over the rounded corners
    canvas.save();
    canvas.clipRRect(trackRect);

    // 3. Draw the active fill with a straight right edge
    canvas.drawRect(
      Rect.fromLTRB(0, centerY - trackHeight / 2, thumbX, centerY + trackHeight / 2),
      activePaint,
    );

    canvas.restore();
    
    // No thumb circle!
  }

  @override
  bool shouldRepaint(covariant _LinearPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.isDragging != isDragging;
  }
}
