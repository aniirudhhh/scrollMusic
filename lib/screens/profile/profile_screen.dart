import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../data/library_manager.dart';
import '../../screens/home/home_controller.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../core/utils/app_toast.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Rely on DynamicGlobalBackground
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          const SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 12),
                child: Text(
                  'Library',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
          
          // Category List
          SliverToBoxAdapter(
            child: Consumer<LibraryManager>(
              builder: (context, library, _) {
                return Column(
                  children: [
                    _LibraryCategoryTile(
                      title: 'Playlists',
                      icon: HugeIcons.strokeRoundedPlaylist01,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const _PlaylistsListView()),
                        );
                      },
                    ),
                    _LibraryCategoryTile(
                      title: 'Artists',
                      icon: HugeIcons.strokeRoundedMic01,
                      onTap: () => AppToast.show(context, 'Artists coming soon'),
                    ),
                    _LibraryCategoryTile(
                      title: 'Albums',
                      icon: HugeIcons.strokeRoundedAlbum02,
                      onTap: () => AppToast.show(context, 'Albums coming soon'),
                    ),
                    _LibraryCategoryTile(
                      title: 'Songs',
                      icon: HugeIcons.strokeRoundedMusicNote01,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _PlaylistDetailScreen(
                              title: 'Liked Songs',
                              songs: library.likedSongs,
                            ),
                          ),
                        );
                      },
                    ),
                    _LibraryCategoryTile(
                      title: 'Made for You',
                      icon: HugeIcons.strokeRoundedUserCircle,
                      onTap: () => AppToast.show(context, 'Made for You coming soon'),
                    ),
                    _LibraryCategoryTile(
                      title: 'Recently Played',
                      icon: HugeIcons.strokeRoundedTime02,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _PlaylistDetailScreen(
                              title: 'Recently Played',
                              songs: library.recentlyPlayed,
                            ),
                          ),
                        );
                      },
                    ),
                    _LibraryCategoryTile(
                      title: 'Downloaded',
                      icon: HugeIcons.strokeRoundedDownload04,
                      isLast: true,
                      onTap: () => AppToast.show(context, 'Downloads coming soon'),
                    ),
                  ],
                );
              },
            ),
          ),

          // We can add a "Recently Added" grid section here in the future
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _LibraryCategoryTile extends StatelessWidget {
  final String title;
  final dynamic icon;
  final VoidCallback onTap;
  final bool isLast;

  const _LibraryCategoryTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      highlightColor: Colors.white.withOpacity(0.05),
      splashColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(left: 20), // Inset for divider
        child: Column(
          children: [
            SizedBox(
              height: 52, // Standard Apple Music list item height
              child: Row(
                children: [
                  HugeIcon(
                    icon: icon,
                    color: const Color(0xFFFF2D55),
                    size: 24,
                    strokeWidth: 2,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withOpacity(0.3),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(left: 40), // Align divider with text
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Internal Playlists View ──────────────────────────────────────────────

class _PlaylistsListView extends StatelessWidget {
  const _PlaylistsListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFF2D55)),
        title: const Text('Playlists', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              final library = context.read<LibraryManager>();
              _showCreatePlaylistModal(context, library);
            },
            child: const Text('New', style: TextStyle(color: Color(0xFFFF2D55), fontSize: 16)),
          ),
        ],
      ),
      body: Consumer<LibraryManager>(
        builder: (context, library, _) {
          final playlists = library.customPlaylists;
          if (playlists.isEmpty) {
            return const Center(
              child: Text('No Playlists', style: TextStyle(color: Colors.white54, fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _PlaylistDetailScreen(
                          title: playlist.name,
                          songs: playlist.songs,
                          playlistId: playlist.id,
                          library: library,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: playlist.songs.isNotEmpty
                            ? CachedNetworkImage(imageUrl: playlist.songs.first.artwork, fit: BoxFit.cover)
                            : const HugeIcon(icon: HugeIcons.strokeRoundedMusicNote01, color: Colors.white30, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlist.name,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${playlist.songs.length} songs',
                              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.3)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

void _showCreatePlaylistModal(BuildContext context, LibraryManager library) {
  final textController = TextEditingController();

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1C1C1E),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'New Playlist',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: textController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Playlist Name',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
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
                  final name = textController.text.trim();
                  if (name.isNotEmpty) {
                    library.createPlaylist(name);
                    Navigator.pop(context);
                    AppToast.show(context, 'Playlist "$name" created');
                  }
                },
                child: const Text('Create', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ─── Playlist Details View ────────────────────────────────────────────────

class _PlaylistDetailScreen extends StatelessWidget {
  const _PlaylistDetailScreen({
    required this.title,
    required this.songs,
    this.playlistId,
    this.library,
  });

  final String title;
  final List<Song> songs;
  final String? playlistId;
  final LibraryManager? library;

  @override
  Widget build(BuildContext context) {
    final hasArtwork = songs.isNotEmpty && songs.first.artwork.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280, 
            pinned: true,
            backgroundColor: Colors.black.withOpacity(0.5), 
            iconTheme: const IconThemeData(color: Color(0xFFFF2D55)),
            actions: [
              if (playlistId != null && library != null)
                IconButton(
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02, color: Color(0xFFFF2D55), size: 24),
                  onPressed: () {
                    library!.deletePlaylist(playlistId!);
                    Navigator.pop(context);
                    AppToast.show(context, 'Playlist deleted');
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 48, bottom: 16, right: 16),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasArtwork)
                    CachedNetworkImage(
                      imageUrl: songs.first.artwork,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                      ),
                      child: const Center(
                        child: HugeIcon(icon: HugeIcons.strokeRoundedMusicNote01, size: 80, color: Colors.white24),
                      ),
                    ),
                  
                  // Gradient overlay so text is readable
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                          Colors.black,
                        ],
                        stops: const [0.0, 0.4, 0.8, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (songs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedPlaylist01, size: 64, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    Text(
                      'No songs here yet',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100, top: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = songs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            final queue = songs.sublist(index);
                            context.read<HomeController>().playNewQueue(queue);
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: CachedNetworkImage(
                                  imageUrl: song.artwork,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.white.withOpacity(0.1),
                                    child: const HugeIcon(icon: HugeIcons.strokeRoundedMusicNote01, color: Colors.white54, size: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      song.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      song.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (playlistId != null && library != null)
                                IconButton(
                                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedRemove01, color: Colors.white38, size: 24),
                                  onPressed: () {
                                    library!.removeSongFromPlaylist(playlistId!, song.id);
                                    AppToast.show(context, 'Removed from playlist');
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: songs.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: songs.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                context.read<HomeController>().playNewQueue(songs);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              backgroundColor: const Color(0xFFFF2D55),
              foregroundColor: Colors.white,
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedPlay, size: 24, color: Colors.white),
              label: const Text('Play', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          : null,
    );
  }
}
