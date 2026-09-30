import re

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the Container + BoxDecoration with Material
pattern = re.compile(
    r'Container\(\s*decoration: BoxDecoration\(\s*color: Colors\.white\.withAlpha\(12\),\s*borderRadius: BorderRadius\.circular\(16\),\s*\),',
    re.MULTILINE
)

replacement = r'''Material(
                  color: Colors.white.withAlpha(12),
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,'''

content = pattern.sub(replacement, content)

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
