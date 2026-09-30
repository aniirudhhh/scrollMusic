import re

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_title = '''                  title: Text(
                    _accountName ?? (_isLoggedIn ? 'YouTube Music User' : 'Profile & Settings'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                    ),
                  ),'''

new_title = '''                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _accountName ?? (_isLoggedIn ? 'YouTube Music User' : 'Profile & Settings'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                        ),
                      ),
                      if (_accountEmail != null && _accountEmail!.isNotEmpty)
                        Text(
                          _accountEmail!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10, // Will scale up/down with FlexibleSpaceBar
                            fontWeight: FontWeight.normal,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                          ),
                        ),
                    ],
                  ),'''

content = content.replace(old_title, new_title)

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
