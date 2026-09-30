import os

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start_str = '''                      Consumer<HomeController>(
                          builder: (context, controller, _) {
                            final isCurrent =
                                controller.currentIndex == widget.index;
                            final state = isCurrent
                                ? controller.playbackState
                                : PlaybackState.idle;
                            return Column('''

end_str = '''                                activeColor: _primaryColor ?? Colors.white,
                              ),;
                        },
                      ),'''

start_idx = content.find(start_str)
if start_idx != -1:
    end_idx = content.find(end_str, start_idx) + len(end_str)
    
    replacement = '''                      Consumer<HomeController>(
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
    
    content = content[:start_idx] + replacement + content[end_idx:]

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
