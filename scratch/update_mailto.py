import re

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import for url_launcher
if "import 'package:url_launcher/url_launcher.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:url_launcher/url_launcher.dart';")

# Update Contact Us tile
old_contact_tile = '''_buildTile('Contact Us', HugeIcons.strokeRoundedMail01, subtitle: 'iaminsanexdev@gmail.com', onTap: () {
                              Clipboard.setData(const ClipboardData(text: 'iaminsanexdev@gmail.com'));
                              AppToast.show(context, 'Email copied to clipboard!');
                            }),'''
new_contact_tile = '''_buildTile('Contact Us', HugeIcons.strokeRoundedMail01, subtitle: 'iaminsanexdev@gmail.com', onTap: () async {
                              final Uri emailLaunchUri = Uri(
                                scheme: 'mailto',
                                path: 'iaminsanexdev@gmail.com',
                                query: 'subject=Scroll Music Support',
                              );
                              if (await canLaunchUrl(emailLaunchUri)) {
                                await launchUrl(emailLaunchUri);
                              } else {
                                // Fallback if no email client is installed
                                Clipboard.setData(const ClipboardData(text: 'iaminsanexdev@gmail.com'));
                                AppToast.show(context, 'Email copied to clipboard!');
                              }
                            }),'''

content = content.replace(old_contact_tile, new_contact_tile)

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
