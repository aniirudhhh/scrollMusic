import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/song.dart';

/// Displays song title and artist name with clean typographic hierarchy.
/// Animates in when a new song appears.
class SongInfoWidget extends StatelessWidget {
  const SongInfoWidget({super.key, required this.song, this.isCentered = false});

  final Song song;
  final bool isCentered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          song.title,
          maxLines: 2,
          textAlign: isCentered ? TextAlign.center : TextAlign.start,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 19, // Reduced from 22
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.2,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4), // Reduced from 6
        Text(
          song.artist,
          maxLines: 1,
          textAlign: isCentered ? TextAlign.center : TextAlign.start,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 14, // Reduced from 15
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.6),
            letterSpacing: 0.1,
          ),
        ),
      ],
    )
        .animate(key: ValueKey(song.id))
        .slideX(
          begin: 0.08,
          end: 0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        )
        .fadeIn(duration: const Duration(milliseconds: 350));
  }
}
