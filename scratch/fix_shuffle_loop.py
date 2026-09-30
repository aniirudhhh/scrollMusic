import os

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove Shuffle from Playback Row
start_shuffle = content.find('Consumer<HomeController>(')
# we need to find the specific Consumer for Shuffle
shuffle_str = '''Consumer<HomeController>(
                          builder: (context, controller, child) {
                            return IconButton(
                              icon: HugeIcon(
                                icon: HugeIcons.strokeRoundedShuffle,'''
idx = content.find(shuffle_str)
if idx == -1: print("Shuffle not found!")

# Let's use a simpler approach. I will use Dart format to my advantage.
# Actually, I'll just use a small Dart script to parse the AST! No, Python regex with DOTALL is fine.

import re

# Playback row regex
playback_pattern = re.compile(
    r'(// [^\n]*Playback Controls Row[^\n]*\n\s*Row\(\s*mainAxisAlignment: MainAxisAlignment\.spaceBetween,\s*children: \[\s*)Consumer<HomeController>\(\s*builder: \(context, controller, child\) \{\s*return IconButton\(\s*icon: HugeIcon\(\s*icon: HugeIcons\.strokeRoundedShuffle,.*?\);\s*\},\s*\),\s*(Expanded\(\s*child: Padding\(.*?child: Consumer<HomeController>\(\s*builder: \(context, controller, _\) \{.*?return AnimatedPlaybackControls\(.*?\);\s*\},\s*\),\s*\),\s*\),\s*)Consumer<HomeController>\(\s*builder: \(context, controller, child\) \{\s*return IconButton\(\s*icon: HugeIcon\(\s*icon: HugeIcons\.strokeRoundedArrowReloadHorizontal,.*?\);\s*\},\s*\),(\s*\])',
    re.DOTALL
)

def playback_repl(m):
    return m.group(1) + m.group(2) + m.group(3)

content = playback_pattern.sub(playback_repl, content)

# Footer row regex
footer_pattern = re.compile(
    r'(// [^\n]*Footer Row[^\n]*\n\s*Row\(\s*mainAxisAlignment: MainAxisAlignment\.spaceBetween,\s*children: \[\s*IconButton\(\s*icon: const HugeIcon\(\s*icon: HugeIcons\.strokeRoundedPlaylist01,.*?\),\s*)IconButton\(\s*icon: const HugeIcon\(\s*icon: HugeIcons\.strokeRoundedMoreVertical,)',
    re.DOTALL
)

footer_replacement = r'''\1Consumer<HomeController>(
                          builder: (context, controller, child) {
                            return IconButton(
                              icon: HugeIcon(
                                icon: HugeIcons.strokeRoundedShuffle,
                                size: 24.0,
                                color: controller.isShuffled
                                    ? Colors.greenAccent
                                    : Colors.white70,
                                strokeWidth: 1.5,
                              ),
                              onPressed: () {
                                controller.toggleShuffle();
                              },
                            );
                          },
                        ),
                        Consumer<HomeController>(
                          builder: (context, controller, child) {
                            return IconButton(
                              icon: HugeIcon(
                                icon: HugeIcons.strokeRoundedArrowReloadHorizontal,
                                size: 24.0,
                                color: controller.isLoopOne
                                    ? Colors.greenAccent
                                    : Colors.white70,
                                strokeWidth: 1.5,
                              ),
                              onPressed: () {
                                controller.toggleLoop();
                              },
                            );
                          },
                        ),
                        \2'''

content = footer_pattern.sub(footer_replacement, content)

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
