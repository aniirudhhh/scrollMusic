import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/search_theme.dart';

enum SearchResultType { song, video, artist, album, playlist, episode }

class SearchResultTile extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final SearchResultType type;
  final VoidCallback onTap;
  final VoidCallback onMoreTapped;

  const SearchResultTile({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.onTap,
    required this.onMoreTapped,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onMoreTapped,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail
            _buildThumbnail(),
            const SizedBox(width: 16.0),
            // Text Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SearchTheme.titleStyle,
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SearchTheme.subtitleStyle,
                  ),
                ],
              ),
            ),
            // Trailing 3-dot
            SizedBox(
              width: 48.0,
              height: 48.0,
              child: IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: onMoreTapped,
                splashRadius: 24.0, // Provides correct visual feedback radius
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    double width = 64.0;
    double height = 64.0;
    BoxShape shape = BoxShape.rectangle;
    double radius = 4.0;

    if (type == SearchResultType.video || type == SearchResultType.episode) {
      width = 116.0;
      height = 65.0; // ~16:9
    } else if (type == SearchResultType.artist) {
      shape = BoxShape.circle;
      radius = 32.0;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(radius)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey[900]),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[900],
          child: Icon(
            type == SearchResultType.video
                ? Icons.video_library
                : Icons.music_note,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
