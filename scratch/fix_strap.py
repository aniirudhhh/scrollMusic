import re

with open('D:/scrollMusic/lib/screens/search/search_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the line: color: SearchTheme.backgroundColor.withOpacity(0.5),
content = content.replace('color: SearchTheme.backgroundColor.withOpacity(0.5)', 'color: Colors.transparent')

with open('D:/scrollMusic/lib/screens/search/search_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
