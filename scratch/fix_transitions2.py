import re

with open('D:/scrollMusic/lib/app.dart', 'r', encoding='utf-8') as f:
    content = f.read()

bad_transitions = '''          pageTransitionsTheme: PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: const FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
            },
          ),'''

good_transitions = '''          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
            },
          ),'''

content = content.replace(bad_transitions, good_transitions)

with open('D:/scrollMusic/lib/app.dart', 'w', encoding='utf-8') as f:
    f.write(content)
