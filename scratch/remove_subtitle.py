import re

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove subtitle from Contact Us tile
content = content.replace(
    "_buildTile('Contact Us', HugeIcons.strokeRoundedMail01, subtitle: 'iaminsanexdev@gmail.com', onTap: () async {",
    "_buildTile('Contact Us', HugeIcons.strokeRoundedMail01, onTap: () async {"
)

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
