import re

with open('D:/scrollMusic/lib/downloads/download_manager.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(
    r'final streamUrl = await NativeExtractionService\.extractAudioUrl\([\s\S]*?if \(streamUrl == null\) throw Exception\("Failed to extract stream URL"\);',
    'final stream = await _extractor.extractStream(task.song);\n      final streamUrl = stream.streamUrl;\n      if (streamUrl.isEmpty) throw Exception("Failed to extract stream URL");',
    content
)

with open('D:/scrollMusic/lib/downloads/download_manager.dart', 'w', encoding='utf-8') as f:
    f.write(content)
