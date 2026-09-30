import re

with open('D:/scrollMusic/lib/data/yt_music_sync_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

match = re.search(r'(static Future<Map<String, String>\?> fetchUserProfile\(\) async \{.*?\n  \})', content, re.DOTALL)
if match:
    print(match.group(1))
