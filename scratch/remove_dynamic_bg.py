import re

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Remove the import
content = content.replace("import '../../widgets/dynamic_single_color_background.dart';\n", "")

# 2. Change background color
content = content.replace("backgroundColor: Colors.black, // Fallback background", "backgroundColor: const Color(0xFF0F0F13),")

# 3. Remove the stack and dynamic background
old_body = '''      body: Stack(
        children: [
          const Positioned.fill(child: DynamicSingleColorBackground()),
          CustomScrollView('''

new_body = '''      body: CustomScrollView('''

content = content.replace(old_body, new_body)

# 4. Remove the closing stack tags (we need to be careful)
# The end of the file looks like:
#             ],
#           ),
#         ],
#       ),
#     );
#   }
# }

# We will just replace the trailing brackets.
end_pattern = r'            \],\n          \),\n        \],\n      \),\n    \);\n  \}\n\}'
end_replacement = r'            ],\n          ),\n    );\n  }\n}'
content = re.sub(end_pattern, end_replacement, content)

with open('D:/scrollMusic/lib/screens/profile/profile_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
