import re

with open('D:/scrollMusic/lib/data/yt_music_sync_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add cache methods to YTMusicSyncService
cache_methods = '''
  static Future<Map<String, String>?> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('yt_profile_name');
    final email = prefs.getString('yt_profile_email');
    final avatar = prefs.getString('yt_profile_avatar');
    
    if (name != null) {
      return {
        'name': name,
        'email': email ?? '',
        'avatarUrl': avatar ?? '',
      };
    }
    return null;
  }

  static Future<void> clearCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('yt_profile_name');
    await prefs.remove('yt_profile_email');
    await prefs.remove('yt_profile_avatar');
  }
'''

# Insert after getCookie
content = content.replace(
    "  static bool hasCookie(String? cookie) {",
    cache_methods + "\n  static bool hasCookie(String? cookie) {"
)

# 2. Update fetchUserProfile to save to cache
fetch_logic = '''        if (accountName != null || accountEmail != null || avatarUrl != null) {
          final profileData = {
            'name': accountName ?? 'YouTube User',
            'email': accountEmail ?? '',
            'avatarUrl': avatarUrl ?? '',
          };
          
          // Save to cache
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('yt_profile_name', profileData['name']!);
          await prefs.setString('yt_profile_email', profileData['email']!);
          await prefs.setString('yt_profile_avatar', profileData['avatarUrl']!);
          
          return profileData;
        }'''

content = re.sub(
    r'        if \(accountName != null \|\| accountEmail != null \|\| avatarUrl != null\) \{.*?return \{.*?\};\n        \}',
    fetch_logic,
    content,
    flags=re.DOTALL
)

with open('D:/scrollMusic/lib/data/yt_music_sync_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
