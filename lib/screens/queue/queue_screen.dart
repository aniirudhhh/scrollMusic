import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home/home_controller.dart';
import '../../models/song.dart';
import '../../widgets/liquid_glass_surface.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => const QueueScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassSurface(
      blurBehind: true,
      sigma: 40,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      tintColor: const Color(0xFF1E1E1E).withValues(alpha: 0.8),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Up Next',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          
          Expanded(
            child: Consumer<HomeController>(
              builder: (context, controller, child) {
                final songs = controller.songs;
                final currentIndex = controller.currentIndex;
                
                if (songs.isEmpty || currentIndex >= songs.length) {
                  return const Center(child: Text('Queue is empty', style: TextStyle(color: Colors.white54)));
                }

                // We only want to show the currently playing song (at top, non-reorderable)
                // and the upcoming songs (reorderable).
                final currentSong = songs[currentIndex];
                final upcomingSongs = songs.sublist(currentIndex + 1);

                return CustomScrollView(
                  slivers: [
                    // Now Playing (fixed)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: _QueueItem(song: currentSong, isCurrent: true),
                      ),
                    ),
                    
                    // Up Next list (reorderable)
                    SliverReorderableList(
                      itemCount: upcomingSongs.length,
                      onReorder: (oldIndex, newIndex) {
                        // The actual indices in the repository are offset by currentIndex + 1
                        controller.reorderQueue(currentIndex + 1 + oldIndex, currentIndex + 1 + newIndex);
                      },
                      itemBuilder: (context, index) {
                        final song = upcomingSongs[index];
                        return _buildReorderableItem(
                          context,
                          song: song,
                          index: index,
                          globalIndex: currentIndex + 1 + index,
                          controller: controller,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableItem(
    BuildContext context, {
    required Song song,
    required int index,
    required int globalIndex,
    required HomeController controller,
  }) {
    return ReorderableDelayedDragStartListener(
      key: ValueKey(song.id + globalIndex.toString()),
      index: index,
      child: Dismissible(
        key: ValueKey('dismiss_${song.id}_$globalIndex'),
        direction: DismissDirection.endToStart,
        background: Container(
          color: const Color(0xFFFF2D55),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
        ),
        onDismissed: (_) {
          controller.removeFromQueue(globalIndex);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: _QueueItem(song: song, isCurrent: false),
        ),
      ),
    );
  }
}

class _QueueItem extends StatelessWidget {
  final Song song;
  final bool isCurrent;

  const _QueueItem({required this.song, this.isCurrent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isCurrent ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(isCurrent ? 12 : 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: song.artwork,
              width: isCurrent ? 56 : 48,
              height: isCurrent ? 56 : 48,
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
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCurrent ? 16 : 15,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: isCurrent ? 14 : 13,
                  ),
                ),
              ],
            ),
          ),
          if (isCurrent)
            const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20)
          else
            Icon(Icons.drag_handle_rounded, color: Colors.white.withValues(alpha: 0.3), size: 20),
        ],
      ),
    );
  }
}
