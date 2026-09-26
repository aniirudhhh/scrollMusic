import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Full-bleed artwork widget with a blurred dark backdrop.
/// Supports HD YouTube thumbnails (maxresdefault) with seamless fallback
/// to standard HQ thumbnail if the HD version is unavailable.
class ArtworkWidget extends StatelessWidget {
  const ArtworkWidget({
    super.key,
    required this.artworkUrl,
    this.fallbackUrl,
    required this.songId,
  });

  final String artworkUrl;
  final String? fallbackUrl;

  /// Used as hero tag so transitions between pages animate cleanly.
  final String songId;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CachedNetworkImage(
        imageUrl: artworkUrl,
        fit: BoxFit.cover,
        memCacheWidth: 800, // Downscale to prevent jank
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (_, _) => _Placeholder(),
        errorWidget: (_, _, _) {
          // If high-res thumbnail 404s, seamlessly fallback to standard HQ thumbnail
          if (fallbackUrl != null && fallbackUrl!.isNotEmpty && fallbackUrl != artworkUrl) {
            return CachedNetworkImage(
              imageUrl: fallbackUrl!,
              fit: BoxFit.cover,
              memCacheWidth: 800,
              fadeInDuration: const Duration(milliseconds: 150),
              placeholder: (_, _) => _Placeholder(),
              errorWidget: (_, _, _) => _ErrorArtwork(),
            );
          }
          return _ErrorArtwork();
        },
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 200))
        .scaleXY(
          begin: 0.92,
          end: 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Opacity(
          opacity: 0.2,
          child: Image.asset(
            'assets/applogo-new.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _ErrorArtwork extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 48,
          color: Color(0xFF3A3A3A),
        ),
      ),
    );
  }
}
