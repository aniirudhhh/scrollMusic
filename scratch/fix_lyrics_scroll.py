import re

with open('D:/scrollMusic/lib/screens/lyrics/lyrics_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add _lineKeys to state
if "List<GlobalKey> _lineKeys = [];" not in content:
    content = content.replace(
        "int _activeIndex = -1;", 
        "int _activeIndex = -1;\n  List<GlobalKey> _lineKeys = [];"
    )

# 2. Update _fetchLyrics to initialize keys
content = re.sub(
    r"_lyrics = lines;\s*_isLoading = false;",
    "_lyrics = lines;\n          _lineKeys = List.generate(lines?.length ?? 0, (index) => GlobalKey());\n          _isLoading = false;",
    content
)

# 3. Update _scrollToActive logic
old_scroll = '''  void _scrollToActive() {
    if (!_scrollController.hasClients || _activeIndex < 0) return;
    
    final targetOffset = (_activeIndex * 48.0) - (MediaQuery.of(context).size.height * 0.3);
    
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }'''

new_scroll = '''  void _scrollToActive() {
    if (!_scrollController.hasClients || _activeIndex < 0 || _activeIndex >= _lineKeys.length) return;
    
    final key = _lineKeys[_activeIndex];
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        alignment: 0.4, // Slightly above absolute center so it's visually pleasing above the playback controls
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }'''

content = content.replace(old_scroll, new_scroll)

# 4. Attach keys to the Padding in itemBuilder
old_padding = '''        return Padding(
          padding: const EdgeInsets.only(bottom: 24.0),'''

new_padding = '''        return Padding(
          key: _lineKeys[index],
          padding: const EdgeInsets.only(bottom: 24.0),'''

content = content.replace(old_padding, new_padding)

# 5. Optional: Add a top and bottom padding to the list view so the very first and last items CAN reach the center!
old_list_padding = '''padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 250),'''
new_list_padding = '''padding: EdgeInsets.only(left: 24, right: 24, top: MediaQuery.of(context).size.height * 0.4, bottom: MediaQuery.of(context).size.height * 0.5),'''

content = content.replace(old_list_padding, new_list_padding)

with open('D:/scrollMusic/lib/screens/lyrics/lyrics_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
