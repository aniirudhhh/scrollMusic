import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/search_theme.dart';
import '../../models/search_models.dart';
import '../../data/search_repository.dart';
import 'search_controller.dart';
import 'search_top_bar.dart';
import 'search_filter_chips.dart';
import 'top_result_card.dart';
import 'search_result_tile.dart';
import 'result_actions_sheet.dart';
import 'search_skeleton.dart';
import 'package:provider/provider.dart';
import '../../models/song.dart';
import '../../models/artist.dart';
import '../home/home_controller.dart';
import '../artist/artist_screen.dart';
import '../playlist/playlist_screen.dart';
import '../../core/utils/app_toast.dart';
import '../../widgets/song_options_sheet.dart';
import '../../widgets/coming_soon_dialog.dart';
import 'suggestion_tile.dart';
import '../../data/download_manager.dart';

class SearchScreen extends StatefulWidget {
  final double bottomInset;
  final SearchRepository? repository;
  final ValueChanged<SearchItem>? onPlay;
  final ValueChanged<SearchItem>? onAddToQueue;

  const SearchScreen({
    super.key,
    this.bottomInset = 0.0,
    this.repository,
    this.onPlay,
    this.onAddToQueue,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late SearchScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SearchScreenController(
      repository: widget.repository ?? YoutubeSearchRepository(),
      downloadManager: context.read<DownloadManager>(),
    );
    _controller.addListener(_onControllerUpdate);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        _controller.loadNextPage();
      }
    });
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _handleItemTap(SearchItem item) {
    if (item is ArtistItem) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArtistScreen(
            artist: Artist(
              id: item.id,
              name: item.title,
              imageUrl: item.thumbnailUrl,
            ),
          ),
        ),
      );
      return;
    }

    if (item is PlaylistItem) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistScreen(
            playlistId: item.id,
            title: item.title,
            imageUrl: item.thumbnailUrl,
            owner: item.owner,
          ),
        ),
      );
      return;
    }
    if (item is AlbumItem) {
      showComingSoonDialog(context);
      return;
    }

    // Treat as playable Song/Video/Episode
    final song = Song(
      id: item.id,
      title: item.title,
      artist: (item is SongItem)
          ? item.artist
          : ((item is VideoItem) ? item.channel : item.subtitle),
      artwork: item.thumbnailUrl,
      source: 'youtube',
    );
    context.read<HomeController>().playSongNext(song);
  }

  void _showItemOptions(SearchItem item) {
    String artistName = item.title;
    if (item is SongItem) artistName = item.artist;
    if (item is VideoItem) artistName = item.channel;
    if (item is AlbumItem) artistName = item.artist;

    final song = Song(
      id: item.id,
      title: item.title,
      artist: artistName,
      artwork: item.thumbnailUrl,
      source: 'youtube',
    );
    SongOptionsBottomSheet.show(context, song);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SearchTheme.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Text(
                    'Search',
                    style: TextStyle(
                      fontSize: 34.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickySearchBarDelegate(
                hasChips: (!_controller.isEditing && _searchController.text.isNotEmpty),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      color: Colors.transparent, // slight tint for glass effect
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SearchTopBar(
                            controller: _searchController,
                            focusNode: _focusNode,
                            isEditing: _controller.isEditing,
                            onClear: () {
                              _searchController.clear();
                              _controller.currentQuery = '';
                              _controller.onQueryChanged('');
                              _focusNode.requestFocus();
                            },
                            onTapSearchField: () {
                              _controller.setEditing(true);
                              _focusNode.requestFocus();
                            },
                            onSubmitted: (q) {
                              _focusNode.unfocus();
                              _searchController.text = q;
                              _controller.submitSearch(q);
                            },
                            onChanged: (q) {
                              _controller.currentQuery = q;
                              _controller.onQueryChanged(q);
                            },
                            hintText: _controller.isOffline
                                ? 'Search your downloads...'
                                : 'Search songs, artists...',
                          ),
                          if (!_controller.isEditing && _searchController.text.isNotEmpty)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 8.0),
                                SearchFilterChips(
                                  selectedFilter: _controller.selectedFilter,
                                  onFilterSelected: (filter) {
                                    _controller.setFilter(filter);
                                  },
                                ),
                                const SizedBox(height: 16.0),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ..._buildBodySlivers(),
            SliverToBoxAdapter(
              child: SizedBox(height: widget.bottomInset),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBodySlivers() {
    if (_controller.isEditing) {
      return [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final suggestion = _controller.suggestions[index];
              final isHistoryItem =
                  _searchController.text.isEmpty &&
                  index < _controller.history.length;

              return SuggestionTile(
                text: suggestion,
                isHistory: isHistoryItem,
                onTap: () {
                  _searchController.text = suggestion;
                  _focusNode.unfocus();
                  _controller.submitSearch(suggestion);
                },
                onFill: () {
                  _searchController.text = suggestion;
                  _searchController.selection = TextSelection.collapsed(
                    offset: suggestion.length,
                  );
                  _controller.currentQuery = suggestion;
                  _controller.onQueryChanged(suggestion);
                  _focusNode.requestFocus();
                },
              );
            },
            childCount: _controller.suggestions.length,
          ),
        ),
      ];
    }

    switch (_controller.state) {
      case SearchScreenState.loading:
        return [const SliverToBoxAdapter(child: SearchSkeleton())];

      case SearchScreenState.empty:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off,
                    color: SearchTheme.secondaryText,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No results for '${_controller.currentQuery}'",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Try checking the spelling or use different keywords",
                    style: TextStyle(
                      color: SearchTheme.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ];

      case SearchScreenState.error:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Something went wrong",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        _controller.submitSearch(_controller.currentQuery),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ];

      case SearchScreenState.results:
        final page = _controller.currentPage;
        if (page == null) return [const SliverToBoxAdapter(child: SizedBox.shrink())];

        return [
          SliverPadding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 80.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  int itemIndex = index;

                  if (page.topResult != null) {
                    if (index == 0) {
                      final top = page.topResult!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 32.0),
                        child: TopResultCard(
                          imageUrl: top.thumbnailUrl,
                          title: top.title,
                          subtitle: top.subtitle,
                          onPlay: () => _handleItemTap(top),
                          onSave: () => _showItemOptions(top),
                          onCardTapped: () => _handleItemTap(top),
                          onMoreTapped: () => _showItemOptions(top),
                        ),
                      );
                    }
                    itemIndex--;
                  }

                  if (itemIndex == page.items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2.0,
                        ),
                      ),
                    );
                  }

                  final item = page.items[itemIndex];
                  SearchResultType type = SearchResultType.song;
                  if (item is VideoItem) type = SearchResultType.video;
                  if (item is ArtistItem) type = SearchResultType.artist;
                  if (item is AlbumItem) type = SearchResultType.album;
                  if (item is PlaylistItem) type = SearchResultType.playlist;
                  if (item is EpisodeItem) type = SearchResultType.episode;

                  return SearchResultTile(
                    imageUrl: item.thumbnailUrl,
                    title: item.title,
                    subtitle: item.subtitle,
                    type: type,
                    onTap: () => _handleItemTap(item),
                    onMoreTapped: () => _showItemOptions(item),
                  );
                },
                childCount:
                    page.items.length +
                    (page.topResult != null ? 1 : 0) +
                    (_controller.isPaginating ? 1 : 0),
              ),
            ),
          ),
        ];

      default:
        return [const SliverToBoxAdapter(child: SizedBox.shrink())];
    }
  }
}

class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final bool hasChips;

  _StickySearchBarDelegate({required this.child, required this.hasChips});

  @override
  double get minExtent => 56.0 + (hasChips ? (8.0 + 36.0 + 16.0) : 0.0);

  @override
  double get maxExtent => 56.0 + (hasChips ? (8.0 + 36.0 + 16.0) : 0.0);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StickySearchBarDelegate oldDelegate) {
    return oldDelegate.hasChips != hasChips || oldDelegate.child != child;
  }
}
