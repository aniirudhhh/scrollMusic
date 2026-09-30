import re

with open('D:/scrollMusic/lib/screens/lyrics/lyrics_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Trigger initial scroll
fetch_target = '''          if (_lyrics == null || _lyrics!.isEmpty) {
            _error = 'No lyrics found';
          } else {
            final hasTimestamps = _lyrics!.any((l) => l.timeMs > 0);
            _isSynced = hasTimestamps;
          }
        });
      }'''

fetch_replacement = '''          if (_lyrics == null || _lyrics!.isEmpty) {
            _error = 'No lyrics found';
          } else {
            final hasTimestamps = _lyrics!.any((l) => l.timeMs > 0);
            _isSynced = hasTimestamps;
            if (_isSynced) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onPositionChanged();
              });
            }
          }
        });
      }'''
content = content.replace(fetch_target, fetch_replacement)

# 2. Dynamic pastel colors
bottom_target = '''                      final themeColor = dominantColor ?? Colors.black;
                      
                      // Derive a dark, solid color for the pill matching the theme palette
                      final darkSolidBg = Color.lerp(themeColor, Colors.black, 0.75)!.withValues(alpha: 1.0);'''

bottom_replacement = '''                      final themeColor = dominantColor ?? Colors.black;
                      
                      // Dynamically generate subtle pastel color from the artwork theme!
                      final pastelColor = HSLColor.fromColor(themeColor).withLightness(0.85).withSaturation(0.4).toColor();
                      // Derive a dark, solid color for the pill matching the theme palette
                      final darkSolidBg = Color.lerp(themeColor, Colors.black, 0.75)!.withValues(alpha: 1.0);'''
content = content.replace(bottom_target, bottom_replacement)

btn_target = '''                                decoration: BoxDecoration(
                                  color: const Color(0xFFC3D8B4), // Subtle pastel green from mockup
                                  borderRadius: BorderRadius.circular(32),'''
btn_replacement = '''                                decoration: BoxDecoration(
                                  color: pastelColor, // Dynamically generated subtle pastel!
                                  borderRadius: BorderRadius.circular(32),'''
content = content.replace(btn_target, btn_replacement)

prog_target = '''                                            activeColor: const Color(0xFFE5B8CD), // Subtle pastel pink from mockup
                                            inactiveColor: Colors.white.withValues(alpha: 0.2),'''
prog_replacement = '''                                            activeColor: pastelColor,
                                            inactiveColor: Colors.white.withValues(alpha: 0.2),'''
content = content.replace(prog_target, prog_replacement)

with open('D:/scrollMusic/lib/screens/lyrics/lyrics_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
