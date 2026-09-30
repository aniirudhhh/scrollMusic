import re

with open('D:/scrollMusic/lib/screens/search/search_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace SliverAppBar with SliverPersistentHeader
old_sliver_app_bar = r'''            SliverAppBar\(
              pinned: true,
              floating: true,
              backgroundColor: SearchTheme.backgroundColor,
              elevation: 0,
              toolbarHeight: 56.0,
              titleSpacing: 0,
              title: SearchTopBar\(
                controller: _searchController,
                focusNode: _focusNode,
                isEditing: _controller.isEditing,
                onClear: \(\) \{
                  _searchController.clear\(\);
                  _controller.currentQuery = '';
                  _controller.onQueryChanged\(''\);
                  _focusNode.requestFocus\(\);
                \},
                onTapSearchField: \(\) \{
                  _controller.setEditing\(true\);
                  _focusNode.requestFocus\(\);
                \},
                onSubmitted: \(q\) \{
                  _focusNode.unfocus\(\);
                  _searchController.text = q;
                  _controller.submitSearch\(q\);
                \},
                onChanged: \(q\) \{
                  _controller.currentQuery = q;
                  _controller.onQueryChanged\(q\);
                \},
              \),
              bottom: \(!_controller.isEditing && _searchController.text.isNotEmpty\)
                  \? PreferredSize\(
                      preferredSize: const Size.fromHeight\(60.0\),
                      child: Column\(
                        mainAxisSize: MainAxisSize.min,
                        children: \[
                          const SizedBox\(height: 8.0\),
                          SearchFilterChips\(
                            selectedFilter: _controller.selectedFilter,
                            onFilterSelected: \(filter\) \{
                              _controller.setFilter\(filter\);
                            \},
                          \),
                          const SizedBox\(height: 16.0\),
                        \],
                      \),
                    \)
                  : null,
            \),'''

new_sliver_app_bar = '''            SliverPersistentHeader(
              pinned: true,
              delegate: _StickySearchBarDelegate(
                hasChips: (!_controller.isEditing && _searchController.text.isNotEmpty),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      color: SearchTheme.backgroundColor.withOpacity(0.5), // slight tint for glass effect
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
            ),'''

content = re.sub(old_sliver_app_bar, new_sliver_app_bar, content)

# Need to add ImageFilter import and _StickySearchBarDelegate class
if "import 'dart:ui';" not in content:
    content = "import 'dart:ui';\n" + content

delegate_class = '''
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
'''

content += delegate_class

with open('D:/scrollMusic/lib/screens/search/search_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
