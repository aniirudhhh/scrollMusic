import re

with open('D:/scrollMusic/lib/screens/profile/profile_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

settings_match = re.search(r'(class _SettingsBottomSheet extends StatefulWidget .*?)\Z', content, re.DOTALL)
if settings_match:
    print(settings_match.group(1))
else:
    print("Could not find settings class")
