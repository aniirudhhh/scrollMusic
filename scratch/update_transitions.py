import re

with open('D:/scrollMusic/lib/app.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add pageTransitionsTheme to ThemeData
old_theme = '''        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.white,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.black,
          fontFamily: 'GoogleSansFlex',
          textTheme: _buildRoundedTextTheme(Typography.material2021().white),
        ),'''

new_theme = '''        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.white,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.black,
          fontFamily: 'GoogleSansFlex',
          textTheme: _buildRoundedTextTheme(Typography.material2021().white),
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
        ),'''

content = content.replace(old_theme, new_theme)

with open('D:/scrollMusic/lib/app.dart', 'w', encoding='utf-8') as f:
    f.write(content)
