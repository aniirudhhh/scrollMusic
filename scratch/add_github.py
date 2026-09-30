import re

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Update Footer
content = content.replace("Made with ❤️ in Flutter", "Made with ❤️ by aniirudhhh")

# Add GitHub Tile to Developer section
developer_section = '''                        children: [
                          _buildTile('Frequently Asked Questions', HugeIcons.strokeRoundedHelpCircle, onTap: () {}),'''

new_developer_section = '''                        children: [
                          _buildTile('GitHub Profile', HugeIcons.strokeRoundedGithub, onTap: () {
                            // TODO: Launch https://github.com/aniirudhhh using url_launcher
                          }),
                          Divider(height: 1, color: Colors.white.withAlpha(25), indent: 52),
                          _buildTile('Frequently Asked Questions', HugeIcons.strokeRoundedHelpCircle, onTap: () {}),'''

content = content.replace(developer_section, new_developer_section)

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
