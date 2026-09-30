import re

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(
    r'onTap:\s*\(\)\s*\{\s*setState\(\(\)\s*\{\s*_showLyrics\s*=\s*true;\s*\}\);\s*\},',
    r'onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => LyricsScreen(song: widget.song))); },',
    content
)

# Also remove _showLyrics from the state class
content = re.sub(r'bool _showLyrics = false;', '', content)

# Remove the animated switchers that check _showLyrics
content = re.sub(
    r'child:\s*AnimatedSwitcher\(\s*duration:.*?child:\s*_showLyrics\s*\?.*?ArtworkWidget\(.*?size:\s*artworkSize,\s*\),\s*\),',
    r'child: ArtworkWidget(key: const ValueKey("artwork"), imageUrl: widget.song.artwork, size: artworkSize,),',
    content,
    flags=re.DOTALL
)

content = re.sub(
    r'AnimatedSwitcher\(\s*duration:.*?child:\s*_showLyrics\s*\?.*?Column\(',
    r'Column(',
    content,
    flags=re.DOTALL
)

content = re.sub(
    r'AnimatedSwitcher\(\s*duration:.*?child:\s*_showLyrics\s*\?.*?Consumer<HomeController>\(',
    r'Consumer<HomeController>(',
    content,
    flags=re.DOTALL
)

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
