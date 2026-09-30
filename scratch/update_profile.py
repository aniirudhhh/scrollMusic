import re

with open('D:/scrollMusic/lib/screens/profile/profile_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add import for the new screen
if "profile_settings_screen.dart" not in content:
    content = "import 'profile_settings_screen.dart';\n" + content

# 2. Remove the IconButton in the SliverToBoxAdapter header
# The IconButton code is roughly:
# Builder(
#   builder: (context) => IconButton(
#     icon: const HugeIcon(icon: HugeIcons.strokeRoundedSettings01, color: Colors.white, size: 28),
#     onPressed: () { ... showModalBottomSheet ... }
#   )
# )
icon_pattern = re.compile(r'Builder\(\s*builder: \(context\) => IconButton\(.*?icon: const HugeIcon\(icon: HugeIcons\.strokeRoundedSettings01.*?\),.*?onPressed: \(\) \{.*?showModalBottomSheet\(.*?builder: \(context\) => const _SettingsBottomSheet\(\),.*?\);.*?\},.*?\),\s*\),', re.DOTALL)
content = icon_pattern.sub('', content)

# 3. Add 'Profile & Settings' tile to the category list
# Find _LibraryCategoryTile(title: 'Downloaded' ... )
download_pattern = re.compile(r"(_LibraryCategoryTile\(\s*title:\s*'Downloaded',.*?isLast:\s*true,.*?onTap:.*?AppToast\.show\(context,\s*'Downloads coming soon'\),?\s*\),?)", re.DOTALL)

def replace_download(match):
    original_download = match.group(1).replace('isLast: true', 'isLast: false')
    new_tile = '''
                    _LibraryCategoryTile(
                      title: 'Profile & Settings',
                      icon: HugeIcons.strokeRoundedSettings01,
                      isLast: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
                        );
                      },
                    ),'''
    return original_download + new_tile

content = download_pattern.sub(replace_download, content)

# 4. Remove _SettingsBottomSheet and _SettingsBottomSheetState completely
bottom_sheet_pattern = re.compile(r'class _SettingsBottomSheet extends StatefulWidget \{.*?(?=// ┈┈┈ Internal Playlists View)', re.DOTALL)
content = bottom_sheet_pattern.sub('', content)

with open('D:/scrollMusic/lib/screens/profile/profile_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
