import re

with open('D:/scrollMusic/lib/screens/playlist/playlist_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# We just want to remove the Text() block that contains widget.owner
# Because of the mojibake, the string is massive.
pattern = r'const SizedBox\(height: 8\),\s*Text\([\s\S]*?widget\.owner\}'',[\s\S]*?textAlign: TextAlign\.center,\s*\),'
content = re.sub(pattern, '', content)

with open('D:/scrollMusic/lib/screens/playlist/playlist_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
