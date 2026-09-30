import re

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove Tips and Tricks and its divider
tips_and_tricks = '''                          _buildTile('Tips and Tricks', HugeIcons.strokeRoundedIdea01, onTap: () {}),
                          Divider(height: 1, color: Colors.white.withAlpha(25), indent: 52),
'''
content = content.replace(tips_and_tricks, "")

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
