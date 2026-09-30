import re

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Change NEED HELP? to DEVELOPER
content = content.replace("_buildSectionHeader('NEED HELP?')", "_buildSectionHeader('DEVELOPER')")

# Add the footer info right before the bottom SizedBox
footer_ui = '''
                    const SizedBox(height: 32),
                    const Center(
                      child: Column(
                        children: [
                          Text('Scroll Music v1.0.0', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Made with ❤️ in Flutter', style: TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),'''
                    
content = content.replace("const SizedBox(height: 100),", footer_ui)

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
