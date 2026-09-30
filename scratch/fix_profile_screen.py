import re

with open('D:/scrollMusic/lib/screens/profile/profile_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Completely remove _SettingsBottomSheet and _SettingsBottomSheetState
# Since it's at the end of the file, we can just split at 'class _SettingsBottomSheet'
if 'class _SettingsBottomSheet' in content:
    content = content.split('class _SettingsBottomSheet')[0]

with open('D:/scrollMusic/lib/screens/profile/profile_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
