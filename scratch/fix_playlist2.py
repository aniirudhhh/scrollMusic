import re

with open('D:/scrollMusic/lib/screens/playlist/playlist_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the start of the title text block
title_start = content.find("Text(")
title_start = content.find("widget.title,", title_start)

# We want to keep the title block
# It ends with ), and then const SizedBox(height: 8),
# Let's use regex to replace from const SizedBox(height: 8),\n Text(\n 'Playlist down to the next ),

pattern = r"const SizedBox\(height: 8\),\s*Text\(\s*'Playlist[\s\S]*?widget\.owner\}',[\s\S]*?textAlign: TextAlign\.center,\s*\),"
content = re.sub(pattern, '', content)

with open('D:/scrollMusic/lib/screens/playlist/playlist_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
