import re

with open('D:/scrollMusic/lib/screens/profile/profile_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if "import '../../widgets/coming_soon_dialog.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport '../../widgets/coming_soon_dialog.dart';")

# Replace AppToasts
content = re.sub(
    r"onTap: \(\) => AppToast\.show\(context, 'Albums coming soon'\),",
    "onTap: () => showComingSoonDialog(context),",
    content
)
content = re.sub(
    r"onTap: \(\) => AppToast\.show\(context, 'Made for You coming soon'\),",
    "onTap: () => showComingSoonDialog(context),",
    content
)
content = re.sub(
    r"onTap: \(\) => AppToast\.show\(context, 'Downloads coming soon'\),",
    "onTap: () => showComingSoonDialog(context),",
    content
)

with open('D:/scrollMusic/lib/screens/profile/profile_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
