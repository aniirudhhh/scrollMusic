import re

with open('D:/scrollMusic/lib/app.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add cupertino import
if "import 'package:flutter/cupertino.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:flutter/cupertino.dart';")

bad_transitions = '''          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
            },
          ),'''

good_transitions = '''          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: CupertinoPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),'''

content = content.replace(bad_transitions, good_transitions)

with open('D:/scrollMusic/lib/app.dart', 'w', encoding='utf-8') as f:
    f.write(content)
