import re

with open('D:/scrollMusic/lib/screens/home/home_controller.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(
    r'    required RecommendationEngine recommendationEngine,\s*required DownloadManager downloadManager,\s*\)\s*:\s*_player = playbackManager,\s*_extractor = extractionService,\s*_repo = repository,\s*_libraryManager = libraryManager,\s*_recEngine = recommendationEngine,\s*_downloadManager = downloadManager \{',
    '    required RecommendationEngine recommendationEngine,\n  }) : _player = playbackManager,\n       _extractor = extractionService,\n       _repo = repository,\n       _libraryManager = libraryManager,\n       _recEngine = recommendationEngine {',
    content
)

with open('D:/scrollMusic/lib/screens/home/home_controller.dart', 'w', encoding='utf-8') as f:
    f.write(content)
