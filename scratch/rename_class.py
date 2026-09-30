import os

files = ['D:/scrollMusic/lib/app.dart', 'D:/scrollMusic/lib/main.dart', 'D:/scrollMusic/test/widget_test.dart']
for path in files:
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        content = content.replace('ScrollMusicApp', 'LooprApp')
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)

