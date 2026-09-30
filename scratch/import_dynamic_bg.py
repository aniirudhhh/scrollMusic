import re

with open('D:/scrollMusic/lib/screens/lyrics/lyrics_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

if "import '../../widgets/dynamic_single_color_background.dart';" not in content:
    content = content.replace("import '../../models/song.dart';", "import '../../models/song.dart';\nimport '../../widgets/dynamic_single_color_background.dart';")

with open('D:/scrollMusic/lib/screens/lyrics/lyrics_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
