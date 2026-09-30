import re

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import if missing
if "import '../screens/lyrics/lyrics_screen.dart';" not in content:
    content = content.replace(
        "import '../models/song.dart';",
        "import '../models/song.dart';\nimport '../screens/lyrics/lyrics_screen.dart';"
    )

target = '''                      Consumer<HomeController>(
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

replacement = '''                      Consumer<HomeController>(
                        builder: (context, controller, _) {
                          final isCurrent =
                              controller.currentIndex == widget.index;
                          final state = isCurrent
                              ? controller.playbackState
                              : PlaybackState.idle;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: IconButton(
                                  icon: const Icon(Icons.fullscreen_rounded, color: Colors.white70, size: 28),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => LyricsScreen(song: widget.song)));
                                  },
                                ),
                              ),
                              _ProgressBar(
                                positionNotifier: controller.positionNotifier,
                                isCurrent: isCurrent,
                                durationNotifier: controller.durationNotifier,
                                onSeek: controller.seek,
                                isPaused:
                                    state != PlaybackState.playing &&
                                    state != PlaybackState.loading,
                                activeColor: _primaryColor ?? Colors.white,
                              ),
                            ],
                          );
                        },
                      ),'''

content = content.replace(target, replacement)

# Clean up SingleLineLyricsView if it had Navigator.push instead of _showLyrics = true
single_line_target = '''                                    onTap: () {
                                      setState(() {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => LyricsScreen(song: 
widget.song)));
                                      });
                                    },'''

single_line_replacement = '''                                    onTap: () {
                                      setState(() { _showLyrics = true; });
                                    },'''
content = content.replace(single_line_target, single_line_replacement)

# A fallback in case it was formatted slightly differently:
content = re.sub(
    r'onTap:\s*\(\)\s*\{\s*setState\(\(\)\s*\{\s*Navigator\.push[^}]+\}\);\s*\},',
    r'onTap: () { setState(() { _showLyrics = true; }); },',
    content,
    flags=re.DOTALL
)

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
