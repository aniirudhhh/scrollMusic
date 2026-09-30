import re

with open('D:/scrollMusic/lib/screens/lyrics/lyrics_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = '''    if (_error.isNotEmpty || _lyrics == null || _lyrics!.isEmpty) {
      return Center(
        child: Text(
          _error.isEmpty ? 'No lyrics available' : _error,
          style: const TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }'''

replacement = '''    if (_error.isNotEmpty || _lyrics == null || _lyrics!.isEmpty) {
      return Center(
        child: Text(
          _error.isEmpty ? 'No lyrics available' : _error,
          style: const TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }
    
    // Safety sync for Hot Reloads where state is preserved but new variables aren't
    if (_lineKeys.length != _lyrics!.length) {
      _lineKeys = List.generate(_lyrics!.length, (_) => GlobalKey());
    }'''

content = content.replace(target, replacement)

with open('D:/scrollMusic/lib/screens/lyrics/lyrics_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
