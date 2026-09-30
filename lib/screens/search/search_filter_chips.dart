import 'package:flutter/material.dart';
import '../../theme/search_theme.dart';
import '../../models/search_models.dart';

const List<Map<String, dynamic>> searchFilters = [
  {'label': 'Songs', 'value': SearchFilter.songs},
  {'label': 'Videos', 'value': SearchFilter.videos},
  {'label': 'Artists', 'value': SearchFilter.artists},
  {'label': 'Albums', 'value': SearchFilter.albums},
  {'label': 'Featured playlists', 'value': SearchFilter.featuredPlaylists},
  {'label': 'Community playlists', 'value': SearchFilter.communityPlaylists},
];

class SearchFilterChips extends StatelessWidget {
  final SearchFilter? selectedFilter;
  final ValueChanged<SearchFilter?> onFilterSelected;

  const SearchFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: searchFilters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8.0),
        itemBuilder: (context, index) {
          final filterDef = searchFilters[index];
          final String label = filterDef['label'];
          final SearchFilter filterValue = filterDef['value'];
          final isSelected = filterValue == selectedFilter;

          return Material(
            color: isSelected ? Colors.white : SearchTheme.chipColor,
            borderRadius: BorderRadius.circular(8.0),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                // If tapped while selected, it reverts to 'All' (null)
                onFilterSelected(isSelected ? null : filterValue);
              },
              child: Container(
                height: 36.0,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: SearchTheme.chipTextStyle.copyWith(
                    color: isSelected ? Colors.black : SearchTheme.primaryText,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
