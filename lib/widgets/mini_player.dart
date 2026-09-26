import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hugeicons/hugeicons.dart';
import '../models/playback_state.dart';
import '../screens/home/home_controller.dart';
import '../screens/main_screen.dart';
import 'liquid_glass_surface.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        final song = controller.currentSong;
        if (song == null) {
          return const SizedBox.shrink();
        }

        final isPlaying =
            controller.playbackState == PlaybackState.playing ||
            controller.playbackState == PlaybackState.buffering;

        return GestureDetector(
          onTap: () {
            // Pop any pushed screens (like ArtistScreen) and switch to Home tab
            Navigator.of(context).popUntil((route) => route.isFirst);
            mainScreenKey.currentState?.switchToTab(0);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: LiquidGlassSurface(
              blurBehind: true,
              sigma: 30,
              borderRadius: BorderRadius.circular(50),
              tintColor: const Color(0xFF1E1E1E).withValues(alpha: 0.8),
              borderWidth: 1,
              borderColor: Colors.white.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Album Art
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: CachedNetworkImage(
                      imageUrl: song.artwork,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 44,
                        height: 44,
                        color: Colors.white.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white54,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title & Artist
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Controls
                  IconButton(
                    icon: HugeIcon(
                      icon: isPlaying
                          ? HugeIcons.strokeRoundedPause
                          : HugeIcons.strokeRoundedPlay,
                      size: 24,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      controller.togglePlayPause();
                    },
                  ),
                  IconButton(
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedNext,
                      size: 24,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      controller.skipToNext();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
