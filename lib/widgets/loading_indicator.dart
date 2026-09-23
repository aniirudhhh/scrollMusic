import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Subtle pulsing loading indicator for extraction/buffering states.
/// Never shows a raw spinner — keeps the UI feeling polished.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.size = 6.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: size * 0.4),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            shape: BoxShape.circle,
          ),
        )
            .animate(
              onPlay: (c) => c.repeat(reverse: true),
              delay: Duration(milliseconds: i * 160),
            )
            .scaleXY(
              begin: 0.5,
              end: 1.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            )
            .fadeIn(
              begin: 0.3,
              duration: const Duration(milliseconds: 500),
            );
      }),
    );
  }
}
