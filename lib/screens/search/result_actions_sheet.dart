import 'package:flutter/material.dart';
import '../../theme/search_theme.dart';

class ResultActionsSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback? onPlayNext;
  final VoidCallback? onAddToQueue;
  final VoidCallback? onSaveToLibrary;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onDownload;
  final VoidCallback? onGoToArtist;
  final VoidCallback? onGoToAlbum;
  final VoidCallback? onShare;

  const ResultActionsSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.onPlayNext,
    this.onAddToQueue,
    this.onSaveToLibrary,
    this.onAddToPlaylist,
    this.onDownload,
    this.onGoToArtist,
    this.onGoToAlbum,
    this.onShare,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String imageUrl,
    VoidCallback? onPlayNext,
    VoidCallback? onAddToQueue,
    VoidCallback? onSaveToLibrary,
    VoidCallback? onAddToPlaylist,
    VoidCallback? onDownload,
    VoidCallback? onGoToArtist,
    VoidCallback? onGoToAlbum,
    VoidCallback? onShare,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SearchTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => ResultActionsSheet(
        title: title,
        subtitle: subtitle,
        imageUrl: imageUrl,
        onPlayNext: onPlayNext,
        onAddToQueue: onAddToQueue,
        onSaveToLibrary: onSaveToLibrary,
        onAddToPlaylist: onAddToPlaylist,
        onDownload: onDownload,
        onGoToArtist: onGoToArtist,
        onGoToAlbum: onGoToAlbum,
        onShare: onShare,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: Image.network(
                    imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[900],
                      child: const Icon(Icons.music_note, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Actions
          if (onPlayNext != null)
            _buildActionItem(Icons.queue_music, 'Play next', () {
              Navigator.pop(context);
              onPlayNext!();
            }),
          if (onAddToQueue != null)
            _buildActionItem(Icons.playlist_add, 'Add to queue', () {
              Navigator.pop(context);
              onAddToQueue!();
            }),
          if (onSaveToLibrary != null)
            _buildActionItem(Icons.library_add, 'Save to library', () {
              Navigator.pop(context);
              onSaveToLibrary!();
            }),
          if (onAddToPlaylist != null)
            _buildActionItem(Icons.playlist_add_check, 'Add to playlist', () {
              Navigator.pop(context);
              onAddToPlaylist!();
            }),
          if (onDownload != null)
            _buildActionItem(Icons.download, 'Download', () {
              Navigator.pop(context);
              onDownload!();
            }),
          if (onGoToArtist != null)
            _buildActionItem(Icons.person, 'Go to artist', () {
              Navigator.pop(context);
              onGoToArtist!();
            }),
          if (onGoToAlbum != null)
            _buildActionItem(Icons.album, 'Go to album', () {
              Navigator.pop(context);
              onGoToAlbum!();
            }),
          if (onShare != null)
            _buildActionItem(Icons.share, 'Share', () {
              Navigator.pop(context);
              onShare!();
            }),
          const SizedBox(height: 8.0),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16.0),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
