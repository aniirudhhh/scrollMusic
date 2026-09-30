import re

with open('D:/scrollMusic/lib/screens/profile/faq_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

bad_string = r"you\\'ll be able"
content = re.sub(r"'Currently, downloads are a work in progress! Soon, .*? playback\.',",
                 '"Currently, downloads are a work in progress! Soon, you\'ll be able to tap the download icon on any song or playlist to save it directly to your device for anytime playback.",',
                 content)

with open('D:/scrollMusic/lib/screens/profile/faq_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
