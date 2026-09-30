import 'package:flutter/material.dart';
import '../../theme/search_theme.dart';

class SuggestionTile extends StatelessWidget {
  final String text;
  final bool isHistory;
  final VoidCallback onTap;
  final VoidCallback onFill;

  const SuggestionTile({
    super.key,
    required this.text,
    required this.isHistory,
    required this.onTap,
    required this.onFill,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48.0,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Icon(
              isHistory ? Icons.history : Icons.search,
              color: SearchTheme.secondaryText,
              size: 24,
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.north_west,
                color: SearchTheme.secondaryText,
                size: 24,
              ),
              onPressed: onFill,
              splashRadius: 24.0,
            ),
          ],
        ),
      ),
    );
  }
}
