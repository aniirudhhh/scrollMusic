import os

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import re

# Match the bad block entirely and replace it
pattern = re.compile(
    r'return Column\(\s*mainAxisSize: MainAxisSize\.min,\s*children: \[\s*Center\(\s*child: IconButton\(\s*icon: const Icon\(Icons\.fullscreen_rounded, color: Colors\.white70, size: 28\),\s*onPressed: \(\) \{\s*Navigator\.push[^}]+\}\);\s*\},\s*\),\s*\),\s*_ProgressBar',
    re.MULTILINE | re.DOTALL
)

content = pattern.sub('return _ProgressBar', content)

# Now we must remove the trailing ], and ); from the Column, which is just after ctiveColor: _primaryColor ?? Colors.white,\s*),
# Let's do a more precise replacement for the tail end.
pattern_tail = re.compile(
    r'(activeColor: _primaryColor \?\? Colors\.white,\s*\),)\s*\],\s*\);',
    re.MULTILINE | re.DOTALL
)
content = pattern_tail.sub(r'\1;', content)

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
