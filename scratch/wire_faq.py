import re

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if "import 'faq_screen.dart';" not in content:
    content = content.replace("import 'package:flutter/services.dart';", "import 'package:flutter/services.dart';\nimport 'faq_screen.dart';")

# Update onTap
old_faq = "_buildTile('Frequently Asked Questions', HugeIcons.strokeRoundedHelpCircle, onTap: () => showComingSoonDialog(context)),"
new_faq = '''_buildTile('Frequently Asked Questions', HugeIcons.strokeRoundedHelpCircle, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqScreen()));
                            }),'''

content = content.replace(old_faq, new_faq)

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
