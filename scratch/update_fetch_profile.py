import re

with open('D:/scrollMusic/lib/data/yt_music_sync_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Update fetchUserProfile to also fetch email
new_func = '''static Future<Map<String, String>?> fetchUserProfile() async {
    final cookie = await getCookie();
    if (!hasCookie(cookie)) return null;

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Cookie': cookie!,
      'Origin': 'https://music.youtube.com',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };

    final sapisid = _getSapisid(cookie);
    if (sapisid != null) {
      headers['Authorization'] = _generateSapisidHash(sapisid);
    }

    try {
      final url = Uri.parse('\/account/account_menu?prettyPrint=false');
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          "context": {
            "client": {
              "clientName": "WEB", 
              "clientVersion": "2.20231214.01.00",
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? avatarUrl;
        String? accountName;
        String? accountEmail;
        
        // Recursive search for account info
        List<Map<String, dynamic>> accountItems = [];
        _findKeys(data, 'accountItem', accountItems);
        
        if (accountItems.isNotEmpty) {
           final item = accountItems.first['accountItem'];
           
           // Name can be in simpleText or runs
           accountName = item?['accountName']?['simpleText'];
           if (accountName == null) {
             final runs = item?['accountName']?['runs'];
             if (runs != null && runs.isNotEmpty) {
               accountName = runs[0]['text'];
             }
           }
           
           // Email is typically in accountByline or accountEmail
           accountEmail = item?['accountByline']?['simpleText'];
           if (accountEmail == null) {
               final runs = item?['accountByline']?['runs'];
               if (runs != null && runs.isNotEmpty) {
                   accountEmail = runs[0]['text'];
               }
           }
           if (accountEmail == null) {
               accountEmail = item?['email']?['simpleText'];
           }
           
           final thumbnails = item?['accountPhoto']?['thumbnails'];
           if (thumbnails != null && thumbnails.isNotEmpty) {
             avatarUrl = thumbnails.last['url'];
           }
        }
        
        if (avatarUrl != null) {
          return {
            'name': accountName ?? 'YouTube User',
            'email': accountEmail ?? '',
            'avatarUrl': avatarUrl,
          };
        }
      }
    } catch (e) {
      debugPrint('Error fetching user profile: \');
    }
    return null;
  }'''

content = re.sub(r'static Future<Map<String, String>\?> fetchUserProfile\(\) async \{.*?\n  \}', new_func, content, flags=re.DOTALL)

with open('D:/scrollMusic/lib/data/yt_music_sync_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
