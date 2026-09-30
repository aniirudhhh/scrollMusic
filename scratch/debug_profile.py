import re

with open('D:/scrollMusic/lib/data/yt_music_sync_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

new_func = '''static Future<Map<String, String>?> fetchUserProfile() async {
    final cookie = await getCookie();
    if (!hasCookie(cookie)) {
      debugPrint('No cookie found');
      return null;
    }

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
              "clientName": "WEB_REMIX", 
              "clientVersion": "1.20231214.01.00",
            }
          }
        }),
      );

      debugPrint('Profile fetch status: \');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? avatarUrl;
        String? accountName;
        String? accountEmail;
        
        // Debug
        // debugPrint('Profile data: \');
        
        List<Map<String, dynamic>> accountItems = [];
        _findKeys(data, 'accountName', accountItems);
        
        if (accountItems.isNotEmpty) {
           final item = accountItems.first;
           debugPrint('Found account item: \');
           
           accountName = item['accountName']?['simpleText'];
           if (accountName == null && item['accountName']?['runs'] != null) {
             accountName = item['accountName']['runs'][0]['text'];
           }
           
           // We search for email in 'accountByline' or 'email' nearby
           _findKeys(data, 'accountByline', accountItems); // re-use array
           if (accountItems.length > 1) {
             final bylineItem = accountItems[1]; // assuming it appended
             accountEmail = bylineItem['accountByline']?['simpleText'] ?? bylineItem['accountByline']?['runs']?[0]?['text'];
           }
           
           // If we didn't find email yet, search 'email'
           if (accountEmail == null) {
             List<Map<String, dynamic>> emailItems = [];
             _findKeys(data, 'email', emailItems);
             if (emailItems.isNotEmpty) {
                 accountEmail = emailItems.first['email']?['simpleText'] ?? emailItems.first['email']?.toString();
             }
           }
           
           List<Map<String, dynamic>> photoItems = [];
           _findKeys(data, 'accountPhoto', photoItems);
           if (photoItems.isNotEmpty) {
             final thumbnails = photoItems.first['accountPhoto']?['thumbnails'];
             if (thumbnails != null && thumbnails.isNotEmpty) {
               avatarUrl = thumbnails.last['url'];
             }
           }
        }
        
        debugPrint('Found Name: \, Email: \, Avatar: \');
        
        // Return even if some are null
        if (accountName != null || accountEmail != null || avatarUrl != null) {
          return {
            'name': accountName ?? 'YouTube User',
            'email': accountEmail ?? '',
            'avatarUrl': avatarUrl ?? '',
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
