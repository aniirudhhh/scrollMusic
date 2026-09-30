import re

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = '''                                    child: Container(
                                      color:
                                          Colors.transparent, // expand hit area
                                      child: Consumer<HomeController>(
                                        builder: (context, controller, _) {
                                          final isCurrent =
                                              controller.currentIndex ==
                                              widget.index;
                                          return LyricsView(
                                            title: widget.song.title,
                                            artist: widget.song.artist,
                                            durationNotifier:
                                                controller.durationNotifier,
                                            positionNotifier:
                                                controller.positionNotifier,
                                            isCurrent: isCurrent,
                                          );
                                        },
                                      ),
                                    ),'''

replacement = '''                                    child: Container(
                                      color: Colors.transparent,
                                      child: Stack(
                                        children: [
                                          Consumer<HomeController>(
                                            builder: (context, controller, _) {
                                              final isCurrent = controller.currentIndex == widget.index;
                                              return LyricsView(
                                                title: widget.song.title,
                                                artist: widget.song.artist,
                                                durationNotifier: controller.durationNotifier,
                                                positionNotifier: controller.positionNotifier,
                                                isCurrent: isCurrent,
                                              );
                                            },
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black.withAlpha(150),
                                                shape: BoxShape.circle,
                                              ),
                                              child: IconButton(
                                                icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 24),
                                                onPressed: () {
                                                  Navigator.push(context, MaterialPageRoute(builder: (_) => LyricsScreen(song: widget.song)));
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),'''

content = content.replace(target, replacement)

# Restore the onTap logic in SingleLineLyricsView to flip back to LyricsView
# Wait! SingleLineLyricsView is in song_page.dart
# I replaced _showLyrics = true; with Navigator.push(...) earlier.
single_line_target = '''                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => LyricsScreen(song: widget.song)));
                                    },'''

single_line_replacement = '''                                    onTap: () {
                                      setState(() {
                                        _showLyrics = true;
                                      });
                                    },'''

content = content.replace(single_line_target, single_line_replacement)

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
