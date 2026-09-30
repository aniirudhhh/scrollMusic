import re

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add import
if "import '../../widgets/coming_soon_dialog.dart';" not in content:
    content = content.replace("import 'package:flutter/services.dart';", "import 'package:flutter/services.dart';\nimport '../../widgets/coming_soon_dialog.dart';")

# 2. Remove local _showComingSoonDialog
local_dialog = r'  void _showComingSoonDialog\(BuildContext context\) \{.*?\n  Widget _buildTile'
content = re.sub(local_dialog, '  Widget _buildTile', content, flags=re.DOTALL)

# 3. Replace calls
content = content.replace("_showComingSoonDialog(context)", "showComingSoonDialog(context)")

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
