import 'dart:io';
import 'profile_settings_screen.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../widgets/coming_soon_dialog.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../data/library_manager.dart';
import '../../data/download_manager.dart';
import '../../screens/home/home_controller.dart';
import '../../models/playlist.dart';
import '../../models/song.dart';
import '../../core/utils/app_toast.dart';
import '../artist/artist_screen.dart';
import '../../data/yt_music_sync_service.dart';
import '../playlist/playlist_edit_sheet.dart';

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
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Library',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    
                  ],
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const _ArtistsListView()),
                        );
                      },
                    ),
                    _LibraryCategoryTile(
                      title: 'Albums',
                      icon: HugeIcons.strokeRoundedAlbum02,
                      onTap: () => showComingSoonDialog(context),
                    ),
                    _LibraryCategoryTile(
                      title: 'Liked Songs',
                      icon: HugeIcons.strokeRoundedFavourite,
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
                      onTap: () => showComingSoonDialog(context),
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
                      title: 'Downloads',
                      icon: HugeIcons.strokeRoundedDownload04,
                      isLast: false,
                      onTap: () {
                        final downloadManager = context.read<DownloadManager>();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _PlaylistDetailScreen(
                              title: 'Downloads',
                              songs: downloadManager.downloadedSongs.map((d) => d.song).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                    _LibraryCategoryTile(
                      title: 'Profile & Settings',
                      icon: HugeIcons.strokeRoundedSettings01,
                      isLast: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),

          // Recently Played Grid
          const SliverToBoxAdapter(
            child: _RecentlyPlayedGrid(),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _RecentlyPlayedGrid extends StatelessWidget {
  const _RecentlyPlayedGrid();

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryManager>(
      builder: (context, library, _) {
        final recentSongs = library.recentlyPlayed.take(20).toList(); // Increased to 20 songs
        if (recentSongs.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recently Played',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8, // Adjust for title/artist text below image
                ),
                itemCount: recentSongs.length,
                itemBuilder: (context, index) {
                  final song = recentSongs[index];
                  return InkWell(
                    onTap: () {
                      context.read<HomeController>().playNewQueue([song]);
                      AppToast.show(context, 'Playing ${song.title}');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: song.artwork,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorWidget: (_, __, ___) => Container(
                                color: Colors.white.withOpacity(0.1),
                                child: const HugeIcon(icon: HugeIcons.strokeRoundedMusicNote01, color: Colors.white54, size: 32),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
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

// â”€â”€â”€ Internal Playlists View â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
                          playlist: playlist,
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
                        child: playlist.imagePath != null
                            ? Image.file(File(playlist.imagePath!), fit: BoxFit.cover)
                            : (playlist.songs.isNotEmpty
                                ? CachedNetworkImage(imageUrl: playlist.songs.last.artwork, fit: BoxFit.cover)
                                : const HugeIcon(icon: HugeIcons.strokeRoundedMusicNote01, color: Colors.white30, size: 32)),
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
  PlaylistEditDialog.show(context);
}

// â”€â”€â”€ Playlist Details View â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PlaylistDetailScreen extends StatelessWidget {
  const _PlaylistDetailScreen({
    required this.title,
    required this.songs,
    this.playlistId,
    this.library,
    this.playlist,
  });

  final String title;
  final List<Song> songs;
  final String? playlistId;
  final LibraryManager? library;
  final Playlist? playlist;

  @override
  Widget build(BuildContext context) {
    // If it's a dynamic playlist object from provider, listen to it to update UI when edited
    final p = playlistId != null && library != null 
        ? context.watch<LibraryManager>().customPlaylists.firstWhere((e) => e.id == playlistId, orElse: () => playlist!)
        : playlist;

    final displayTitle = p?.name ?? title;
    final displayDesc = p?.description;
    final displayImage = p?.imagePath;

    final hasArtwork = (displayImage != null) || (songs.isNotEmpty && songs.last.artwork.isNotEmpty);

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
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedPencilEdit01, color: Colors.white, size: 24),
                  onPressed: () {
                    PlaylistEditDialog.show(context, existingPlaylist: p);
                  },
                ),
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
                displayTitle,
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
                  if (displayImage != null)
                    Image.file(File(displayImage), fit: BoxFit.cover)
                  else if (songs.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: songs.last.artwork,
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
          
          if (displayDesc != null && displayDesc.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text(
                  displayDesc,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8), 
                    fontSize: 16,
                    height: 1.4,
                  ),
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
                            AppToast.show(context, 'Playing ${song.title}');
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
                AppToast.show(context, 'Playing ${songs.first.title}');
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

// â”€â”€â”€ Artists List View â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ArtistsListView extends StatelessWidget {
  const _ArtistsListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFF2D55)),
        title: const Text('Artists', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Consumer<LibraryManager>(
        builder: (context, library, _) {
          final artists = library.followedArtists;
          if (artists.isEmpty) {
            return const Center(
              child: Text('No Followed Artists', style: TextStyle(color: Colors.white54, fontSize: 16)),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 24,
              childAspectRatio: 0.8,
            ),
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArtistScreen(artist: artist),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                          image: DecorationImage(
                            image: NetworkImage(artist.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      artist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}


