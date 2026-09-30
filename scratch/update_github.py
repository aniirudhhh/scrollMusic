import re

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_github = '''_buildTile('GitHub Profile', HugeIcons.strokeRoundedGithub, onTap: () {
                              // TODO: Launch https://github.com/aniirudhhh using url_launcher
                            }),'''
new_github = '''_buildTile('GitHub Profile', HugeIcons.strokeRoundedGithub, onTap: () async {
                              final Uri githubUri = Uri.parse('https://github.com/aniirudhhh');
                              if (await canLaunchUrl(githubUri)) {
                                await launchUrl(githubUri, mode: LaunchMode.externalApplication);
                              }
                            }),'''

content = content.replace(old_github, new_github)

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
