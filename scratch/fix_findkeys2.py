import re

with open('D:/scrollMusic/lib/data/yt_music_sync_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# I will replace the inside of `if (response.statusCode == 200) { ... } catch` completely
new_logic = """      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? avatarUrl;
        String? accountName;
        String? accountEmail;
        
        List<Map<String, dynamic>> accountItems = [];
        _findKeys(data, 'accountName', accountItems);
        if (accountItems.isNotEmpty) {
           final item = accountItems.first;
           accountName = item['accountName']?['simpleText'];
           if (accountName == null && item['accountName']?['runs'] != null) {
             accountName = item['accountName']['runs'][0]['text'];
           }
        }
        
        List<Map<String, dynamic>> bylineItems = [];
        _findKeys(data, 'accountByline', bylineItems);
        if (bylineItems.isNotEmpty) {
           final bylineItem = bylineItems.first;
           accountEmail = bylineItem['accountByline']?['simpleText'] ?? bylineItem['accountByline']?['runs']?[0]?['text'];
        }
        
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
        
        if (accountName != null || accountEmail != null || avatarUrl != null) {
          return {
            'name': accountName ?? 'YouTube User',
            'email': accountEmail ?? '',
            'avatarUrl': (avatarUrl != null && avatarUrl.isNotEmpty) ? avatarUrl : null,
          };
        }
      }"""

content = re.sub(r'      if \(response\.statusCode == 200\) \{.*?if \(accountName != null \|\| accountEmail != null \|\| avatarUrl != null\) \{.*?\}\n      \}', new_logic, content, flags=re.DOTALL)

with open('D:/scrollMusic/lib/data/yt_music_sync_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
