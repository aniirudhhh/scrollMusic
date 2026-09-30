import re

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add subtitle to _buildTile
old_build_tile = '''  Widget _buildTile(String title, dynamic icon, {VoidCallback? onTap, Color? color, Widget? trailing}) {
    return ListTile(
      onTap: onTap,
      leading: icon is IconData 
          ? Icon(icon, color: color ?? Colors.white, size: 22)
          : HugeIcon(icon: icon, color: color ?? Colors.white, size: 22),
      title: Text(
        title,
        style: TextStyle(color: color ?? Colors.white, fontSize: 16),
      ),
      trailing: trailing ?? HugeIcon(
        icon: HugeIcons.strokeRoundedArrowRight01,
        color: Colors.white.withAlpha(76),
        size: 18,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }'''

new_build_tile = '''  Widget _buildTile(String title, dynamic icon, {VoidCallback? onTap, Color? color, Widget? trailing, String? subtitle}) {
    return ListTile(
      onTap: onTap,
      leading: icon is IconData 
          ? Icon(icon, color: color ?? Colors.white, size: 22)
          : HugeIcon(icon: icon, color: color ?? Colors.white, size: 22),
      title: Text(
        title,
        style: TextStyle(color: color ?? Colors.white, fontSize: 16),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.white.withAlpha(128), fontSize: 12)) : null,
      trailing: trailing ?? HugeIcon(
        icon: HugeIcons.strokeRoundedArrowRight01,
        color: Colors.white.withAlpha(76),
        size: 18,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }'''

content = content.replace(old_build_tile, new_build_tile)

# Add import for clipboard
if "import 'package:flutter/services.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';")


# Update Contact Us tile
old_contact_tile = "_buildTile('Contact Us', HugeIcons.strokeRoundedMail01, onTap: () {}),"
new_contact_tile = '''_buildTile('Contact Us', HugeIcons.strokeRoundedMail01, subtitle: 'iaminsanexdev@gmail.com', onTap: () {
                              Clipboard.setData(const ClipboardData(text: 'iaminsanexdev@gmail.com'));
                              AppToast.show(context, 'Email copied to clipboard!');
                            }),'''

content = content.replace(old_contact_tile, new_contact_tile)


with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
