import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Full-bleed artwork widget with a blurred dark backdrop.
/// Supports HD YouTube thumbnails (maxresdefault) with seamless fallback
/// to standard HQ thumbnail if the HD version is unavailable.
class ArtworkWidget extends StatefulWidget {
  const ArtworkWidget({
    super.key,
    required this.artworkUrl,
    this.fallbackUrl,
    required this.songId,
    this.navDirection = 0.0,
    this.navCount = 0,
  });

  final String artworkUrl;
  final String? fallbackUrl;
  final double navDirection;
  final int navCount;

  /// Used as hero tag so transitions between pages animate cleanly.
  final String songId;

  @override
  State<ArtworkWidget> createState() => _ArtworkWidgetState();
}

class _ArtworkWidgetState extends State<ArtworkWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant ArtworkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the navCount changes, it means the user tapped Next/Prev again.
    // We replay the animation from the start without unmounting the image!
    if (oldWidget.navCount != widget.navCount || oldWidget.artworkUrl != widget.artworkUrl) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CachedNetworkImage(
        imageUrl: widget.artworkUrl,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 300), // Smoothly crossfade when image loads from network
        placeholder: (_, _) => _Placeholder(),
        errorWidget: (_, _, _) {
          if (widget.fallbackUrl != null && widget.fallbackUrl!.isNotEmpty && widget.fallbackUrl != widget.artworkUrl) {
            return CachedNetworkImage(
              imageUrl: widget.fallbackUrl!,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 300),
              placeholder: (_, _) => _Placeholder(),
              errorWidget: (_, _, _) => _ErrorArtwork(),
            );
          }
          return _ErrorArtwork();
        },
      ),
    )
        // Tie to standard ValueKey so the widget itself doesn't unmount unless the URL actually changes
        .animate(key: ValueKey(widget.artworkUrl), controller: _controller, autoPlay: true)
        .fadeIn(duration: const Duration(milliseconds: 200))
        .scaleXY(
          begin: widget.navDirection != 0.0 ? 1.0 : 0.92,
          end: 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        )
        .slideX(
          begin: widget.navDirection,
          end: 0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutQuart,
        );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: Colors.white.withValues(alpha: 0.2),
          size: 64,
        ),
      ),
    );
  }
}

class _ErrorArtwork extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.error_outline_rounded,
          color: Colors.white.withValues(alpha: 0.2),
          size: 48,
        ),
      ),
    );
  }
}

