import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable component that implements the "Apple Liquid Glass" aesthetic.
/// It uses a true BackdropFilter for authentic background blurring (refraction),
/// and layers a tint, specular highlight gradient, subtle inner edge lighting, 
/// and an outer soft shadow.
/// 
/// Set [blurBehind] to false for list items to maintain 60/120fps scrolling
/// while keeping the glass look.
class LiquidGlassSurface extends StatelessWidget {
  const LiquidGlassSurface({
    super.key,
    required this.child,
    this.blurBehind = true,
    this.sigma = 25.0,
    this.tintColor,
    this.borderRadius,
    this.borderWidth = 1.0,
    this.borderColor,
    this.shadowColor,
    this.shadowElevation = 10.0,
    this.width,
    this.height,
    this.padding,
    this.margin,
  });

  final Widget child;
  
  /// Whether to apply a BackdropFilter blur. Disable this for scrollable lists.
  final bool blurBehind;
  
  /// The intensity of the background blur.
  final double sigma;
  
  /// The base translucent color of the glass. Defaults to Colors.black26.
  final Color? tintColor;
  
  /// Corner radius of the glass surface. Defaults to 16.
  final BorderRadius? borderRadius;
  
  /// Thickness of the glass edge highlight.
  final double borderWidth;
  
  /// Color of the glass edge. Defaults to white with 15% opacity.
  final Color? borderColor;
  
  /// Outer drop shadow color.
  final Color? shadowColor;
  
  /// Outer drop shadow blur radius and offset base. Set to 0 to disable.
  final double shadowElevation;

  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(16);
    final effectiveTint = tintColor ?? Colors.black.withValues(alpha: 0.2);
    final effectiveBorder = borderColor ?? Colors.white.withValues(alpha: 0.12);
    final effectiveShadow = shadowColor ?? Colors.black.withValues(alpha: 0.4);

    // The inner visual layers: base tint, specular highlight, and border.
    Widget innerContent = Stack(
      fit: StackFit.passthrough,
      children: [
        // Visual layers (Gradient + Tint + Border)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: effectiveTint,
              borderRadius: effectiveRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.15), // Top-left specular hit
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.05), // Subtle bounce light
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
              border: borderWidth > 0 
                  ? Border.all(color: effectiveBorder, width: borderWidth)
                  : null,
            ),
          ),
        ),
        // The actual child content
        Container(
          width: width,
          height: height,
          padding: padding,
          child: child,
        ),
      ],
    );

    // Apply the heavy blur if requested
    if (blurBehind) {
      innerContent = ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: innerContent,
        ),
      );
    } else {
      innerContent = ClipRRect(
        borderRadius: effectiveRadius,
        child: innerContent,
      );
    }

    // Wrap in outer shadow and margin
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: shadowElevation > 0
            ? [
                BoxShadow(
                  color: effectiveShadow,
                  blurRadius: shadowElevation,
                  offset: Offset(0, shadowElevation / 2),
                ),
              ]
            : null,
      ),
      child: innerContent,
    );
  }
}
