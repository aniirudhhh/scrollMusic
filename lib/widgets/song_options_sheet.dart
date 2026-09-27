import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import '../models/song.dart';
import '../models/artist.dart';
import '../screens/home/home_controller.dart';
import '../screens/artist/artist_screen.dart';
import '../data/library_manager.dart';
import '../core/utils/app_toast.dart';
import '../core/utils/sleep_timer.dart';
import 'package:share_plus/share_plus.dart';
import 'liquid_glass_surface.dart';

class SongOptionsBottomSheet extends StatelessWidget {
  final Song song;

  const SongOptionsBottomSheet({super.key, required this.song});

  static void show(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SongOptionsBottomSheet(song: song),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Glass
          LiquidGlassSurface(
            blurBehind: true,
            sigma: 30,
            borderRadius: BorderRadius.circular(24),
            tintColor: const Color(0xFF1E1E1E).withValues(alpha: 0.6),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: song.artwork,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Options List Glass
          LiquidGlassSurface(
            blurBehind: true,
            sigma: 30,
            borderRadius: BorderRadius.circular(24),
            tintColor: const Color(0xFF1E1E1E).withValues(alpha: 0.6),
            child: Column(
              children: [
                if (context.read<HomeController>().currentSong?.id != song.id) ...[
                  _OptionTile(
                    icon: HugeIcons.strokeRoundedPlaylist01,
                    title: 'Play Next',
                    onTap: () {
                      Navigator.pop(context);
                      context.read<HomeController>().addToQueueNext(song);
                      AppToast.show(context, 'Added to queue', icon: HugeIcons.strokeRoundedPlaylist01);
                    },
                  ),
                  _buildDivider(),
                  _OptionTile(
                    icon: HugeIcons.strokeRoundedPlaylist02,
                    title: 'Add to Queue',
                    onTap: () {
                      Navigator.pop(context);
                      context.read<HomeController>().addToQueueLast(song);
                      AppToast.show(context, 'Added to end of queue', icon: HugeIcons.strokeRoundedPlaylist02);
                    },
                  ),
                  _buildDivider(),
                ],
                Consumer<LibraryManager>(
                  builder: (context, library, _) {
                    final isLiked = library.likedSongs.any((s) => s.id == song.id);
                    return _OptionTile(
                      icon: HugeIcons.strokeRoundedFavourite,
                      iconColor: isLiked ? const Color(0xFFFF2D55) : Colors.white,
                      title: isLiked ? 'Remove from Liked' : 'Add to Liked Songs',
                      onTap: () {
                        library.toggleLike(song);
                        // Do not pop the sheet on Like toggle
                        AppToast.show(context, isLiked ? 'Removed from Liked' : 'Added to Liked', icon: HugeIcons.strokeRoundedFavourite);
                      },
                    );
                  },
                ),
                _buildDivider(),
                _OptionTile(
                  icon: HugeIcons.strokeRoundedFolder01,
                  title: 'Add to a Playlist',
                  onTap: () {
                    // Do not pop, open on top
                    _showPlaylistPicker(context, song);
                  },
                ),
                _buildDivider(),
                Consumer<SleepTimer>(
                  builder: (context, sleepTimer, _) {
                    final remaining = sleepTimer.timeRemaining;
                    String? timeStr;
                    if (remaining != null && remaining.inSeconds > 0) {
                      final m = remaining.inMinutes;
                      final s = remaining.inSeconds % 60;
                      timeStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
                    }

                    return _OptionTile(
                      icon: HugeIcons.strokeRoundedClock01,
                      iconColor: sleepTimer.isActive ? const Color(0xFFFF2D55) : Colors.white,
                      title: 'Sleep Timer',
                      trailing: timeStr != null
                          ? Text(timeStr, style: const TextStyle(color: Color(0xFFFF2D55), fontWeight: FontWeight.bold))
                          : null,
                      onTap: () {
                        _showSleepTimerPicker(context);
                      },
                    );
                  }
                ),
                _buildDivider(),
                _OptionTile(
                  icon: HugeIcons.strokeRoundedMic01,
                  title: 'View Artist',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ArtistScreen(artist: Artist(id: '', name: song.artist, imageUrl: ''))));
                  },
                ),
                _buildDivider(),
                _OptionTile(
                  icon: HugeIcons.strokeRoundedDownload04,
                  title: 'Download',
                  onTap: () {
                    Navigator.pop(context);
                    AppToast.show(context, 'Downloads coming soon', icon: HugeIcons.strokeRoundedDownload04);
                  },
                ),
                _buildDivider(),
                _OptionTile(
                  icon: HugeIcons.strokeRoundedShare01,
                  title: 'Share',
                  onTap: () {
                    Navigator.pop(context);
                    final shareText = 'Listen to "${song.title}" by ${song.artist}\n\nhttps://music.youtube.com/watch?v=${song.id}'; Share.share(shareText, subject: 'Shared from ScrollMusic');
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: Colors.white.withValues(alpha: 0.1),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final dynamic icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;
  final Widget? trailing;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor = Colors.white,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            HugeIcon(
              icon: icon,
              size: 24,
              color: iconColor,
              strokeWidth: 2,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

void _showPlaylistPicker(BuildContext context, Song song) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        margin: const EdgeInsets.all(16),
        child: LiquidGlassSurface(
          blurBehind: true,
          sigma: 30,
          borderRadius: BorderRadius.circular(24),
          tintColor: const Color(0xFF1E1E1E).withValues(alpha: 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Add to Playlist',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Divider(height: 1, thickness: 0.5, color: Colors.white.withValues(alpha: 0.1)),
              Consumer<LibraryManager>(
                builder: (context, library, _) {
                  final playlists = library.customPlaylists;
                  if (playlists.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No playlists yet.', style: TextStyle(color: Colors.white54)),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final p = playlists[index];
                      return ListTile(
                        leading: const HugeIcon(
                          icon: HugeIcons.strokeRoundedPlaylist01,
                          size: 24,
                          color: Color(0xFFFF2D55),
                        ),
                        title: Text(p.name, style: const TextStyle(color: Colors.white)),
                        onTap: () {
                          library.addSongToPlaylist(p.id, song);
                          Navigator.pop(context);
                          AppToast.show(context, 'Added to ${p.name}', icon: HugeIcons.strokeRoundedPlaylist01);
                        },
                      );
                    },
                  );
                },
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      );
    },
  );
}

void _showSleepTimerPicker(BuildContext context) {
  int minutes = 15;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            margin: const EdgeInsets.all(16),
            child: LiquidGlassSurface(
              blurBehind: true,
              sigma: 30,
              borderRadius: BorderRadius.circular(24),
              tintColor: const Color(0xFF1E1E1E).withValues(alpha: 0.8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Sleep Timer',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Divider(height: 1, thickness: 0.5, color: Colors.white.withValues(alpha: 0.1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    child: Consumer<SleepTimer>(
                      builder: (context, sleepTimer, _) {
                        if (sleepTimer.isActive) {
                          final remaining = sleepTimer.timeRemaining!;
                          final m = remaining.inMinutes;
                          final s = remaining.inSeconds % 60;
                          final timeStr = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
                          
                          return Column(
                            children: [
                              const Text('Time Remaining', style: TextStyle(color: Colors.white54, fontSize: 16)),
                              const SizedBox(height: 8),
                              Text(timeStr, style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 32),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    sleepTimer.cancel();
                                    Navigator.pop(context);
                                    AppToast.show(context, 'Sleep timer disabled');
                                  },
                                  child: const Text('Turn Off Timer', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          );
                        }

                        // Timer not active, show customizer
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  iconSize: 42,
                                  color: Colors.white54,
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: minutes > 5 ? () {
                                    setState(() => minutes -= 5);
                                  } : null,
                                ),
                                const SizedBox(width: 24),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    '$minutes min',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                IconButton(
                                  iconSize: 42,
                                  color: Colors.white,
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: minutes < 120 ? () {
                                    setState(() => minutes += 5);
                                  } : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF2D55),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  final homeController = context.read<HomeController>();
                                  sleepTimer.start(Duration(minutes: minutes), () {
                                    homeController.pause();
                                  });
                                  Navigator.pop(context);
                                  AppToast.show(context, 'Sleeping in $minutes minutes', icon: HugeIcons.strokeRoundedClock01);
                                },
                                child: const Text('Start Timer', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          );
        }
      );
    },
  );
}


