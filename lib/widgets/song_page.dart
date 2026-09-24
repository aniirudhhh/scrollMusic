import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../data/library_manager.dart';
import '../models/playback_state.dart';
import '../models/song.dart';
import 'artwork_widget.dart';
import 'lyrics_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hugeicons/hugeicons.dart';
import '../core/utils/app_toast.dart';
import '../screens/queue/queue_screen.dart';
import 'song_options_sheet.dart';
import 'single_line_lyrics_view.dart';
import 'wavy_progress_bar.dart';
import '../models/artist.dart';
import '../screens/artist/artist_screen.dart';

class SongPage extends StatefulWidget {
  const SongPage({
    super.key,
    required this.song,
    required this.playbackState,
    required this.positionNotifier,
    required this.isCurrent,
    required this.durationNotifier,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSkipNext,
    required this.onSkipPrev,
  });

  final Song song;
  final PlaybackState playbackState;
  final ValueNotifier<Duration> positionNotifier;
  final bool isCurrent;
  final ValueNotifier<Duration?> durationNotifier;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onSkipNext;
  final VoidCallback onSkipPrev;

  @override
  State<SongPage> createState() => _SongPageState();
}

class _SongPageState extends State<SongPage> {
  bool _showLyrics = false;

  @override
  void didUpdateWidget(SongPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.artwork != widget.song.artwork) {
      _showLyrics = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Removed duplicate local blurred background.
        // Handled globally by DynamicGlobalBackground.

        // ── Main UI Overlay ────────────────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // ── Large Artwork or Lyrics ──────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showLyrics
                          ? GestureDetector(
                              key: const ValueKey('lyrics'),
                              onTap: () {
                                setState(() {
                                  _showLyrics = false;
                                });
                              },
                              child: Container(
                                color: Colors.transparent, // expand hit area
                                child: LyricsView(
                                  title: widget.song.title,
                                  artist: widget.song.artist,
                                  durationNotifier: widget.durationNotifier,
                                  positionNotifier: widget.positionNotifier,
                                  isCurrent: widget.isCurrent,
                                ),
                              ),
                            )
                          : AspectRatio(
                              key: const ValueKey('artwork'),
                              aspectRatio: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: RepaintBoundary(
                                    child: ArtworkWidget(
                                      artworkUrl: widget.song.artwork,
                                      fallbackUrl: widget.song.fallbackArtwork,
                                      songId: widget.song.id,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1.0,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: _showLyrics
                      ? const SizedBox.shrink(key: ValueKey('hidden_info'))
                      : Column(
                          key: const ValueKey('info_row'),
                          children: [
                            const SizedBox(height: 24),
                            // ── Info Row (Title, Artist, Like) ──────────────────────────
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.song.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 20, // Reduced from 24
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2), // Reduced from 4
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 2,
                                        children: widget.song.artist
                                            .split(RegExp(r'(?:,\s*|\s+&\s+)'))
                                            .where((a) => a.trim().isNotEmpty)
                                            .map((artistName) => GestureDetector(
                                                  onTap: () {
                                                    final dummyArtist = Artist(
                                                      id: artistName.trim(),
                                                      name: artistName.trim(),
                                                      imageUrl: widget.song.artwork,
                                                    );
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => ArtistScreen(artist: dummyArtist),
                                                      ),
                                                    );
                                                  },
                                                  child: Text(
                                                    artistName.trim(),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w400,
                                                      color: Colors.white.withOpacity(0.7),
                                                      decoration: TextDecoration.underline,
                                                      decorationColor: Colors.white.withOpacity(0.3),
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedForward01, color: Colors.white, size: 28),
                                  onPressed: () => QueueScreen.show(context),
                                ),
                                _LikeButton(song: widget.song),
                              ],
                            ),
                          ],
                        ),
                ),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _showLyrics 
                    ? const SizedBox(height: 24)
                    : SingleLineLyricsView(
                        title: widget.song.title,
                        artist: widget.song.artist,
                        durationNotifier: widget.durationNotifier,
                        positionNotifier: widget.positionNotifier,
                        isCurrent: widget.isCurrent,
                        onTap: () {
                          setState(() {
                            _showLyrics = true;
                          });
                        },
                      ),
                ),
                
                const SizedBox(height: 8),

                // ── Progress Bar ────────────────────────────────────────────
                _ProgressBar(
                  positionNotifier: widget.positionNotifier,
                  isCurrent: widget.isCurrent,
                  durationNotifier: widget.durationNotifier,
                  onSeek: widget.onSeek,
                  isPaused: widget.playbackState != PlaybackState.playing && widget.playbackState != PlaybackState.loading,
                ),

                const SizedBox(height: 8),

                // ── Playback Controls Row ────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedShuffle,
                        size: 24.0,
                        color: Colors.white70,
                        strokeWidth: 1.5,
                      ),
                      onPressed: () {}, // Placeholder
                    ),
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
                      onPressed: widget.onSkipPrev,
                    ),
                    GestureDetector(
                      onTap: widget.onPlayPause,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: widget.playbackState == PlaybackState.playing || 
                                  widget.playbackState == PlaybackState.buffering
                                ? HugeIcons.strokeRoundedPause
                                : HugeIcons.strokeRoundedPlay,
                            color: Colors.black,
                            size: 36.0,
                            strokeWidth: 1.5, // Matches the thin stroke style
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                      onPressed: widget.onSkipNext,
                    ),
                    IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowReloadHorizontal,
                        size: 24.0,
                        color: Colors.white70,
                        strokeWidth: 1.5,
                      ),
                      onPressed: () {}, // Placeholder
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Footer Row ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedPlaylist01,
                        size: 24.0,
                        color: Colors.white70,
                        strokeWidth: 1.5,
                      ),
                      onPressed: () {
                        final library = context.read<LibraryManager>();
                        _showAddToPlaylistModal(context, library, widget.song);
                      },
                    ),
                    IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedMoreVertical,
                        size: 24.0,
                        color: Colors.white70,
                        strokeWidth: 1.5,
                      ),
                      onPressed: () {
                        SongOptionsBottomSheet.show(context, widget.song);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 90), // Reduced padding for floating navbar
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddToPlaylistModal(BuildContext context, LibraryManager library, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add to Playlist',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (library.customPlaylists.isEmpty)
                Text(
                  "You don't have any playlists yet. Go to your Profile to create one!",
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                )
              else
                ...library.customPlaylists.map((playlist) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const HugeIcon(
                      icon: HugeIcons.strokeRoundedPlaylist01,
                      size: 24.0,
                      color: Colors.white70,
                      strokeWidth: 1.5,
                    ),
                    title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      library.addSongToPlaylist(playlist.id, song);
                      Navigator.pop(context);
                      AppToast.show(
                        context,
                        'Added to ${playlist.name}',
                        icon: HugeIcons.strokeRoundedPlaylist01,
                      );
                    },
                  );
                }),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// ─── Like Button ─────────────────────────────────────────────────────────────
class _LikeButton extends StatelessWidget {
  const _LikeButton({required this.song});
  final Song song;

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryManager>(
      builder: (context, library, _) {
        final isLiked = library.isLiked(song.id);
        return IconButton(
          icon: isLiked
              ? const Icon(Icons.favorite_rounded, color: Colors.white, size: 28)
              : const HugeIcon(
                  icon: HugeIcons.strokeRoundedFavourite,
                  color: Colors.white70,
                  size: 28.0,
                  strokeWidth: 1.5,
                ),
          onPressed: () {
            library.toggleLike(song);
            AppToast.show(
              context,
              !isLiked ? 'Added to Liked Songs' : 'Removed from Liked Songs',
              icon: HugeIcons.strokeRoundedFavourite,
            );
          },
        ).animate(key: ValueKey(isLiked)).scaleXY(
          begin: 0.5,
          end: 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
        );
      },
    );
  }
}

// ─── Progress bar ──────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.positionNotifier,
    required this.isCurrent,
    required this.durationNotifier,
    required this.onSeek,
    this.isPaused = false,
  });

  final ValueNotifier<Duration> positionNotifier;
  final bool isCurrent;
  final ValueNotifier<Duration?> durationNotifier;
  final ValueChanged<Duration> onSeek;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration?>(
      valueListenable: durationNotifier,
      builder: (context, duration, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: positionNotifier,
          builder: (context, rawPosition, child) {
            final position = isCurrent ? rawPosition : Duration.zero;
            final total = duration?.inMilliseconds.toDouble() ?? 1.0;
            final current = position.inMilliseconds.toDouble().clamp(0.0, total);
            final progress = total > 0 ? current / total : 0.0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                WavyProgressBar(
                  value: progress.clamp(0.0, 1.0),
                  isPaused: isPaused,
                  onChanged: duration != null
                      ? (v) {
                          final ms = (v * (duration.inMilliseconds)).round();
                          onSeek(Duration(milliseconds: ms));
                        }
                      : null,
                ),
                // Transform to reduce the padding inherently added by the slider widget
                Transform.translate(
                  offset: const Offset(0, -2), // Adjusted for WavyProgressBar height
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _format(position),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        duration != null ? _format(duration) : '--:--',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}


