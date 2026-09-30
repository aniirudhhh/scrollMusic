with open('D:/scrollMusic/lib/screens/playlist/playlist_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start = content.find("widget.title,")
if start != -1:
    end_of_title = content.find("),", start) + 2
    # Find the next _buildActionButton
    next_btn = content.find("_buildActionButton", end_of_title)
    if next_btn != -1:
        # We need to find the start of the row containing _buildActionButton
        # Just find the 'Row(' before it
        row_start = content.rfind("Row(", end_of_title, next_btn)
        if row_start != -1:
            content = content[:end_of_title] + "\n                        const SizedBox(height: 24),\n                        " + content[row_start:]

with open('D:/scrollMusic/lib/screens/playlist/playlist_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
