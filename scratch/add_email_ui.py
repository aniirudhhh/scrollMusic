import re

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add _accountEmail
content = content.replace(
    "  String? _accountName;\n  String? _avatarUrl;",
    "  String? _accountName;\n  String? _accountEmail;\n  String? _avatarUrl;"
)

# 2. Update _checkLoginStatus
check_status_new = '''        setState(() {
          _isLoggedIn = true;
          _accountName = profile?['name'];
          _accountEmail = profile?['email'];
          _avatarUrl = profile?['avatarUrl'];
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _accountName = null;
          _accountEmail = null;
          _avatarUrl = null;
        });'''
content = re.sub(
    r'        setState\(\(\) \{\n          _isLoggedIn = true;\n          _accountName = profile\?\[\'name\'\];\n          _avatarUrl = profile\?\[\'avatarUrl\'\];\n        \}\);\n      \}\n    \} else \{\n      if \(mounted\) \{\n        setState\(\(\) \{\n          _isLoggedIn = false;\n          _accountName = null;\n          _avatarUrl = null;\n        \}\);',
    check_status_new,
    content,
    flags=re.DOTALL
)

# 3. Add email Text widget to the UI
ui_old = '''                      Text(
                        _accountName ?? (_isLoggedIn ? 'YouTube Music User' : 'Guest'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],'''
ui_new = '''                      Text(
                        _accountName ?? (_isLoggedIn ? 'YouTube Music User' : 'Guest'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_accountEmail != null && _accountEmail!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            _accountEmail!,
                            style: TextStyle(
                              color: Colors.white.withAlpha(150),
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],'''
content = content.replace(ui_old, ui_new)

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
