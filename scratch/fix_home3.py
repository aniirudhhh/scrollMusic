with open('D:/scrollMusic/lib/screens/home/home_controller.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    '       _recEngine = recommendationEngine,\n       _recEngine = recommendationEngine {',
    '       _recEngine = recommendationEngine {'
)

with open('D:/scrollMusic/lib/screens/home/home_controller.dart', 'w', encoding='utf-8') as f:
    f.write(content)
