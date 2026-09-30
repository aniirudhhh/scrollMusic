import re

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if "import '../screens/lyrics/lyrics_screen.dart';" not in content:
    content = content.replace("import '../models/song.dart';", "import '../models/song.dart';\nimport '../screens/lyrics/lyrics_screen.dart';")

# 1. Update onTap for SingleLineLyricsView
old_ontap = '''                                    onTap: () {
                                      setState(() {
                                        _showLyrics = true;
                                      });
                                    },'''
new_ontap = '''                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => LyricsScreen(song: widget.song)));
                                    },'''
content = content.replace(old_ontap, new_ontap)

# 2. We can just leave _showLyrics logic but remove the assignment. Or we can just leave it as is and the lyrics will never be shown inline because we changed onTap!
# Wait, did the user want to completely remove the inline artwork flip? Yes. But it's easier to just leave the _showLyrics variable and only change the onTap so it never flips, and then we don't break the layout.
# Let's just remove the inline flip by replacing _showLyrics initial value to false, and not mutating it. Wait, _showLyrics = true was only ever called in that onTap. If we change the onTap, it will never be true!
# So the artwork will never flip. This is perfectly safe and doesn't require modifying the layout tree!

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
