import re

with open('D:/scrollMusic/lib/data/yt_music_sync_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the email fallback section
old_email_logic = """        if (accountEmail == null) {
           List<Map<String, dynamic>> emailItems = [];
           _findKeys(data, 'email', emailItems);
           if (emailItems.isNotEmpty) {
               accountEmail = emailItems.first['email']?['simpleText'] ?? emailItems.first['email']?.toString();
           }
        }"""

new_email_logic = """        if (accountEmail == null) {
           List<Map<String, dynamic>> emailItems = [];
           _findKeys(data, 'email', emailItems);
           if (emailItems.isNotEmpty) {
               accountEmail = emailItems.first['email']?['simpleText'] ?? emailItems.first['email']?.toString();
           }
        }
        
        // Final fallback: Use Regex to extract the first email address found in the entire JSON payload!
        if (accountEmail == null) {
            final emailRegExp = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
            final match = emailRegExp.firstMatch(response.body);
            if (match != null) {
              accountEmail = match.group(0);
            }
        }"""

content = content.replace(old_email_logic, new_email_logic)

with open('D:/scrollMusic/lib/data/yt_music_sync_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
