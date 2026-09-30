import re

with open('D:/scrollMusic/lib/data/yt_music_sync_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

bad_code = """        List<Map<String, dynamic>> accountItems = [];
        _findKeys(data, 'accountName', accountItems);
        
        if (accountItems.isNotEmpty) {
           final item = accountItems.first;
           debugPrint('Found account item: $item');
           
           accountName = item['accountName']?['simpleText'];
           if (accountName == null && item['accountName']?['runs'] != null) {
             accountName = item['accountName']['runs'][0]['text'];
           }
           
           // We search for email in 'accountByline' or 'email' nearby
           _findKeys(data, 'accountByline', accountItems); // re-use array
           if (accountItems.length > 1) {
             final bylineItem = accountItems[1]; // assuming it appended
             accountEmail = bylineItem['accountByline']?['simpleText'] ?? bylineItem['accountByline']?['runs']?[0]?['text'];
           }"""

good_code = """        List<Map<String, dynamic>> accountItems = [];
        _findKeys(data, 'accountName', accountItems);
        
        if (accountItems.isNotEmpty) {
           final item = accountItems.first;
           debugPrint('Found accountName item: $item');
           
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
        }"""

content = content.replace(bad_code, good_code)

with open('D:/scrollMusic/lib/data/yt_music_sync_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
