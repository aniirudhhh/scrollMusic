import re

with open('D:/scrollMusic/lib/screens/lyrics/lyrics_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = '''    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            const Positioned.fill(
              child: DynamicSingleColorBackground(),
            ),
            Positioned.fill(
              child: Column('''

replacement = '''    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DynamicSingleColorBackground(),
          ),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Column('''

content = content.replace(target, replacement)

# We also need to fix the closing braces for SafeArea.
# The original code has:
#                 ],
#               ),
#             ),
#             Positioned(

closing_target = '''                  Expanded(
                    child: _buildLyricsContent(),
                  ),
                ],
              ),
            ),
            Positioned('''

closing_replacement = '''                  Expanded(
                    child: _buildLyricsContent(),
                  ),
                ],
              ),
            ),
            ),
            Positioned('''

content = content.replace(closing_target, closing_replacement)

# And remove the closing brace for the old SafeArea at the end of Stack.
# Original end of Stack:
#           ],
#         ),
#       ),
#     );
#   }

end_target = '''          ],
        ),
      ),
    );
  }'''

end_replacement = '''          ],
        ),
    );
  }'''

content = content.replace(end_target, end_replacement)

with open('D:/scrollMusic/lib/screens/lyrics/lyrics_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
