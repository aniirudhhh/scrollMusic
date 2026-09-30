import re

with open('D:/scrollMusic/lib/app.dart', 'r', encoding='utf-8') as f:
    content = f.read()

bad_transitions = '''          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),'''

good_transitions = '''          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
            },
          ),'''

# Wait, FadeUpwardsPageTransitionsBuilder has a const constructor, so I can just use const.
good_transitions = '''          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: const FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
            },
          ),'''

content = content.replace(bad_transitions, good_transitions)

# Let me just completely remove const from PageTransitionsTheme just in case to be perfectly safe
safe_transitions = '''          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),'''
safer_transitions = '''          pageTransitionsTheme: PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: const FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
            },
          ),'''
content = content.replace(safe_transitions, safer_transitions)

with open('D:/scrollMusic/lib/app.dart', 'w', encoding='utf-8') as f:
    f.write(content)
