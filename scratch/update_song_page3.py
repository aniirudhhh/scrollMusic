import re

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

if "import '../screens/lyrics/lyrics_screen.dart';" not in content:
    content = content.replace("import '../models/song.dart';", "import '../models/song.dart';\nimport '../screens/lyrics/lyrics_screen.dart';")

old_block = '''                                    onTap: () {
                                      setState(() {
                                        _showLyrics = true;
                                      });
                                    },'''
new_block = '''                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => LyricsScreen(song: widget.song)));
                                    },'''
content = content.replace(old_block, new_block)

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
