import re

with open('D:/scrollMusic/lib/downloads/download_manager.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix constructor
content = re.sub(
    r'class DownloadManager extends ChangeNotifier \{\n  final DownloadRepository _repository;\n  final DownloadStorage _storage;\n  final Dio _dio = Dio\(\);',
    'class DownloadManager extends ChangeNotifier {\n  final DownloadRepository _repository;\n  final DownloadStorage _storage;\n  final ExtractionService _extractor;\n  final Dio _dio = Dio();',
    content, flags=re.MULTILINE
)
content = re.sub(
    r'DownloadManager\(this\._repository, this\._storage\);',
    'DownloadManager(this._repository, this._storage, this._extractor);',
    content
)

# Fix extractAudioUrl
content = re.sub(
    r'final streamUrl = await NativeExtractionService\.extractAudioUrl\(task\.song\);\s*if \(streamUrl == null\) throw Exception\("Failed to extract stream URL"\);',
    'final stream = await _extractor.extractStream(task.song);\n      final streamUrl = stream.streamUrl;\n      if (streamUrl.isEmpty) throw Exception("Failed to extract stream URL");',
    content, flags=re.MULTILINE
)

with open('D:/scrollMusic/lib/downloads/download_manager.dart', 'w', encoding='utf-8') as f:
    f.write(content)
