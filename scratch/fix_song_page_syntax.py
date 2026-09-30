import re

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# We need to replace the entire Consumer block that returns Column with the one that returns _ProgressBar
target = re.compile(r'Consumer<HomeController>\(\s*builder: \(context, controller, _\) \{\s*final isCurrent =[^;]+;\s*final state =[^;]+;\s*return Column\(\s*mainAxisSize: MainAxisSize\.min,\s*children: \[\s*Center\(\s*child: IconButton\(\s*icon: const Icon\(Icons\.fullscreen_rounded, color: Colors\.white70, size: 28\),\s*onPressed: \(\) \{\s*Navigator\.push[^}]+\}\);\s*\},\s*\),\s*\),\s*_ProgressBar\([\s\S]*?activeColor: _primaryColor \?\? Colors\.white,\s*\),;\s*},\s*\),', re.DOTALL)

replacement = '''Consumer<HomeController>(
                        builder: (context, controller, _) {
                          final isCurrent =
                              controller.currentIndex == widget.index;
                          final state = isCurrent
                              ? controller.playbackState
                              : PlaybackState.idle;
                          return _ProgressBar(
                            positionNotifier: controller.positionNotifier,
                            isCurrent: isCurrent,
                            durationNotifier: controller.durationNotifier,
                            onSeek: controller.seek,
                            isPaused:
                                state != PlaybackState.playing &&
                                state != PlaybackState.loading,
                            activeColor: _primaryColor ?? Colors.white,
                          );
                        },
                      ),'''

content = target.sub(replacement, content)

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
