import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../data/download_manager.dart';
import '../core/utils/artwork_helper.dart';

/// Full-bleed artwork widget with a blurred dark backdrop.
/// Supports HD YouTube thumbnails (maxresdefault) with seamless fallback
/// to standard HQ thumbnail if the HD version is unavailable.
class ArtworkWidget extends StatefulWidget {
  const ArtworkWidget({
    super.key,
    required this.artworkUrl,
    this.fallbackUrl,
    required this.songId,
    this.navCount = 0,
  });

  final String artworkUrl;
  final String? fallbackUrl;
  final int navCount;

  /// Used as hero tag so transitions between pages animate cleanly.
  final String songId;

  @override
  State<ArtworkWidget> createState() => _ArtworkWidgetState();
}

class _ArtworkWidgetState extends State<ArtworkWidget>
    with SingleTickerProviderStateMixin {
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
    if (oldWidget.navCount != widget.navCount ||
        oldWidget.artworkUrl != widget.artworkUrl) {
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
          child: ArtworkHelper.getWidget(
            artworkUrl: widget.artworkUrl,
            fallbackUrl: widget.fallbackUrl,
            songId: widget.songId,
            dm: context.read<DownloadManager>(),
            placeholder: (_, __) => _Placeholder(),
            errorWidget: (_, __, ___) => _ErrorArtwork(),
          ),
        )
        // Tie to standard ValueKey so the widget itself doesn't unmount unless the URL actually changes
        .animate(
          key: ValueKey(widget.artworkUrl),
          controller: _controller,
          autoPlay: true,
        )
        .fadeIn(duration: const Duration(milliseconds: 200))
        .scaleXY(
          begin: 0.95,
          end: 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        ); // Removed slideX since PageView already handles sliding!
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
