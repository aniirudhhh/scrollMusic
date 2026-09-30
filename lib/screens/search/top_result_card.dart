import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/search_theme.dart';

class TopResultCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final VoidCallback onPlay;
  final VoidCallback onSave;
  final VoidCallback onCardTapped;
  final VoidCallback onMoreTapped;

  const TopResultCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.onPlay,
    required this.onSave,
    required this.onCardTapped,
    required this.onMoreTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: SearchTheme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onCardTapped,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.0),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 56.0,
                      height: 56.0,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[900], // Dark gray placeholder
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[900],
                        child: const Icon(Icons.music_note, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  // Text column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SearchTheme.topCardTitleStyle,
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SearchTheme.subtitleStyle,
                        ),
                      ],
                    ),
                  ),
                  // More icon
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: onMoreTapped,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 24,
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              // Row 2: Action Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48.0,
                      child: ElevatedButton.icon(
                        onPressed: onPlay,
                        icon: const Icon(
                          Icons.play_arrow,
                          color: Colors.black,
                          size: 28,
                        ),
                        label: const Text(
                          'Play',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: SizedBox(
                      height: 48.0,
                      child: OutlinedButton.icon(
                        onPressed: onSave,
                        icon: const Icon(
                          Icons.playlist_add,
                          color: Colors.white,
                          size: 24,
                        ),
                        label: const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                            color: Color(0xFF5F5F5F),
                            width: 1.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
