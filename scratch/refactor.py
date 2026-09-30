import re

with open('D:/scrollMusic/lib/screens/search/search_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the Scaffold body with CustomScrollView
old_body = '''      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
              padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
              child: Text(
                'Search',
                style: TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                ),
              ),
            ),
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
            ),

            if (!_controller.isEditing &&
                _searchController.text.isNotEmpty) ...[
              const SizedBox(height: 12.0),
              SearchFilterChips(
                selectedFilter: _controller.selectedFilter,
                onFilterSelected: (filter) {
                  _controller.setFilter(filter);
                },
              ),
            ],

            Expanded(child: _buildBody()),
            SizedBox(height: widget.bottomInset),
          ],
        ),
      ),'''

new_body = '''      body: SafeArea(
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
            SliverAppBar(
              pinned: true,
              floating: true,
              backgroundColor: SearchTheme.backgroundColor,
              elevation: 0,
              toolbarHeight: 56.0,
              titleSpacing: 0,
              title: SearchTopBar(
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
              ),
              bottom: (!_controller.isEditing && _searchController.text.isNotEmpty)
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(60.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8.0),
                          SearchFilterChips(
                            selectedFilter: _controller.selectedFilter,
                            onFilterSelected: (filter) {
                              _controller.setFilter(filter);
                            },
                          ),
                          const SizedBox(height: 16.0), // Margin below pills
                        ],
                      ),
                    )
                  : null,
            ),
            ..._buildBodySlivers(),
            SliverToBoxAdapter(
              child: SizedBox(height: widget.bottomInset),
            ),
          ],
        ),
      ),'''

if old_body in content:
    content = content.replace(old_body, new_body)
else:
    print("Could not find old_body")

old_build_body = '''  Widget _buildBody() {
    if (_controller.isEditing) {
      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: _controller.suggestions.length,
        itemBuilder: (context, index) {
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
      );
    }

    switch (_controller.state) {
      case SearchScreenState.loading:
        return const SearchSkeleton();

      case SearchScreenState.empty:
        return Center(
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
                "No results for ''",
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
        );

      case SearchScreenState.error:
        return Center(
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
        );

      case SearchScreenState.results:
        final page = _controller.currentPage;
        if (page == null) return const SizedBox.shrink();

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: ListView.builder(
            key: ValueKey(
              '_',
            ),
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 16.0, bottom: 80.0),
            itemCount:
                page.items.length +
                (page.topResult != null ? 1 : 0) +
                (_controller.isPaginating ? 1 : 0),
            itemBuilder: (context, index) {
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
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }'''

new_build_body = '''  List<Widget> _buildBodySlivers() {
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
                    "No results for ''",
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
  }'''

if old_build_body in content:
    content = content.replace(old_build_body, new_build_body)
else:
    print("Could not find old_build_body")

with open('D:/scrollMusic/lib/screens/search/search_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
