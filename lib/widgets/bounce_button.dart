import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class BounceButton extends StatefulWidget {
  const BounceButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.92,
  });

  final Widget child;
  final VoidCallback onTap;
  final double scaleFactor;

  @override
  State<BounceButton> createState() => _BounceButtonState();
}

class _BounceButtonState extends State<BounceButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: double.infinity,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.animateTo(
      widget.scaleFactor,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  void _onTapUp(TapUpDetails details) {
    _bounceBack();
    widget.onTap();
  }

  void _onTapCancel() {
    _bounceBack();
  }

  void _bounceBack() {
    final springDesc = const SpringDescription(
      mass: 1.0,
      stiffness: 450.0,
      damping: 15.0, // High stiffness, low damping = very bouncy and shakey
    );
    final spring = SpringSimulation(springDesc, _controller.value, 1.0, 0.0);
    _controller.animateWith(spring);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _controller.value,
            alignment: Alignment.center,
            child: widget.child,
          );
        },
      ),
    );
  }
}
