import re

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = re.compile(r'return Column\(\s*mainAxisSize: MainAxisSize\.min,\s*children: \[\s*Center\(\s*child: IconButton\([\s\S]*?activeColor: _primaryColor \?\? Colors\.white,\s*\),;', re.DOTALL)

replacement = '''return _ProgressBar(
                            positionNotifier: controller.positionNotifier,
                            isCurrent: isCurrent,
                            durationNotifier: controller.durationNotifier,
                            onSeek: controller.seek,
                            isPaused:
                                state != PlaybackState.playing &&
                                state != PlaybackState.loading,
                            activeColor: _primaryColor ?? Colors.white,
                          );'''

content = target.sub(replacement, content)

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
