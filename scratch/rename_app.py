import os

# 1. AndroidManifest.xml
path = 'D:/scrollMusic/android/app/src/main/AndroidManifest.xml'
if os.path.exists(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace('android:label="ScrollMusic"', 'android:label="Loopr"')
    content = content.replace('android:label="scrollMusic"', 'android:label="Loopr"')
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# 2. app.dart
path = 'D:/scrollMusic/lib/app.dart'
if os.path.exists(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace("title: 'ScrollMusic',", "title: 'Loopr',")
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# 3. song_options_sheet.dart
path = 'D:/scrollMusic/lib/widgets/song_options_sheet.dart'
if os.path.exists(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace("subject: 'Shared from ScrollMusic'", "subject: 'Shared from Loopr'")
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

# 4. lyrics_service.dart
path = 'D:/scrollMusic/lib/data/lyrics_service.dart'
if os.path.exists(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace("ScrollMusic (https://github.com/scrollmusic)", "Loopr (https://github.com/aniirudhhh/Loopr)")
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

