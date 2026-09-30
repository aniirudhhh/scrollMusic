import re

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace ListView( with SafeArea(child: ListView(
content = content.replace(
    '          ListView(',
    '          SafeArea(child: ListView('
)

# Replace the end of the ListView which is     );
# The file ends with     );\n  }\n}\n
content = content.replace(
    '        ],\n      ),\n    );\n  }\n}',
    '        ],\n      ),\n      ),\n    );\n  }\n}'
)


with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
