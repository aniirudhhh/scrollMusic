import re

with open('D:/scrollMusic/lib/screens/artist/artist_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add import
if "import '../../widgets/coming_soon_dialog.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../widgets/coming_soon_dialog.dart';")

# 2. Wire up empty onPressed blocks
content = content.replace("onPressed: () {},", "onPressed: () => showComingSoonDialog(context),")

with open('D:/scrollMusic/lib/screens/artist/artist_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
