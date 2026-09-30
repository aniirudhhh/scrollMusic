import re

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add import for lyrics screen
if "import '../screens/lyrics/lyrics_screen.dart';" not in content:
    content = content.replace("import '../models/song.dart';", "import '../models/song.dart';\nimport '../screens/lyrics/lyrics_screen.dart';")

# 2. Update the onTap for SingleLineLyricsView
old_single_line = '''                                    onTap: () {
                                      setState(() {
                                        _showLyrics = true;
                                      });
                                    },'''
new_single_line = '''                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => LyricsScreen(song: widget.song)));
                                    },'''
content = content.replace(old_single_line, new_single_line)

# 3. Simplify the artwork section - remove AnimatedSwitcher and _showLyrics logic
old_artwork_section = '''                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _showLyrics
                                ? GestureDetector(
                                    key: const ValueKey('lyrics'),
                                    onTap: () {
                                      setState(() {
                                        _showLyrics = false;
                                      });
                                    },
                                    child: Container(
                                      height: artworkSize,
                                      width: artworkSize,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlpha(50),
                                        borderRadius: BorderRadius.circular(32),
                                      ),
                                      child: LyricsView(
                                        title: widget.song.title,
                                        artist: widget.song.artist,
                                        durationNotifier:
                                            context.read<HomeController>().durationNotifier,
                                        positionNotifier:
                                            context.read<HomeController>().positionNotifier,
                                        isCurrent: true,
                                      ),
                                    ),
                                  )
                                : ArtworkWidget(
                                    key: const ValueKey('artwork'),
                                    imageUrl: widget.song.artwork,
                                    size: artworkSize,
                                  ),
                          ),'''

new_artwork_section = '''                          child: ArtworkWidget(
                            key: const ValueKey('artwork'),
                            imageUrl: widget.song.artwork,
                            size: artworkSize,
                          ),'''
content = content.replace(old_artwork_section, new_artwork_section)

# 4. Remove _showLyrics check in the info row section
old_info_row = '''                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                        child: _showLyrics
                            ? const SizedBox.shrink(key: ValueKey('hidden_info'))
                            : Column(
                                key: const ValueKey('info_row'),
                                children: [
                                  const SizedBox(height: 16), // Extra gap when info is visible
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: SongInfoWidget(
                                          title: widget.song.title,
                                          artist: widget.song.artist,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const HugeIcon(
                                          icon: HugeIcons.strokeRoundedMoreHorizontal,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            backgroundColor: Colors.transparent,
                                            isScrollControlled: true,
                                            builder: (_) => SongOptionsSheet(song: widget.song),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),'''

new_info_row = '''                      Column(
                        key: const ValueKey('info_row'),
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: SongInfoWidget(
                                  title: widget.song.title,
                                  artist: widget.song.artist,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedMoreHorizontal,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    isScrollControlled: true,
                                    builder: (_) => SongOptionsSheet(song: widget.song),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),'''
content = content.replace(old_info_row, new_info_row)

# 5. Remove _showLyrics check before SingleLineLyricsView
old_single_line_switcher = '''                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _showLyrics
                            ? SizedBox(height: isSmallScreen ? 8 : 24)
                            : Consumer<HomeController>(
                                builder: (context, controller, _) {
                                  final isCurrent =
                                      controller.currentIndex == widget.index;
                                  return SingleLineLyricsView(
                                    title: widget.song.title,
                                    artist: widget.song.artist,
                                    durationNotifier: controller.durationNotifier,
                                    positionNotifier: controller.positionNotifier,
                                    isCurrent: isCurrent,
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => LyricsScreen(song: widget.song)));
                                    },
                                  );
                                },
                              ),
                      ),'''

new_single_line_switcher = '''                      Consumer<HomeController>(
                        builder: (context, controller, _) {
                          final isCurrent =
                              controller.currentIndex == widget.index;
                          return SingleLineLyricsView(
                            title: widget.song.title,
                            artist: widget.song.artist,
                            durationNotifier: controller.durationNotifier,
                            positionNotifier: controller.positionNotifier,
                            isCurrent: isCurrent,
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => LyricsScreen(song: widget.song)));
                            },
                          );
                        },
                      ),'''
content = content.replace(old_single_line_switcher, new_single_line_switcher)

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
