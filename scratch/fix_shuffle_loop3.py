import os
import re

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Playback row regex
playback_pattern = re.compile(
    r'(// [^\n]*Playback Controls Row[^\n]*\n\s*Row\(\s*mainAxisAlignment: MainAxisAlignment\.spaceBetween,\s*children: \[\s*)Consumer<HomeController>\(\s*builder: \(context, controller, child\) \{\s*return IconButton\(\s*icon: HugeIcon\(\s*icon: HugeIcons\.strokeRoundedShuffle,.*?\);\s*\},\s*\),\s*(Expanded\(\s*child: Padding\(.*?child: Consumer<HomeController>\(\s*builder: \(context, controller, _\) \{.*?return AnimatedPlaybackControls\(.*?\);\s*\},\s*\),\s*\),\s*\),\s*)Consumer<HomeController>\(\s*builder: \(context, controller, child\) \{\s*return IconButton\(\s*icon: HugeIcon\(\s*icon: HugeIcons\.strokeRoundedArrowReloadHorizontal,.*?\);\s*\},\s*\),(\s*\])',
    re.DOTALL
)

def playback_repl(m):
    return m.group(1) + m.group(2) + m.group(3)

content = playback_pattern.sub(playback_repl, content)

# Footer row regex (fixed parenthesis for IconButton)
footer_pattern = re.compile(
    r'(// [^\n]*Footer Row[^\n]*\n\s*Row\(\s*mainAxisAlignment: MainAxisAlignment\.spaceBetween,\s*children: \[\s*IconButton\(\s*icon: const HugeIcon\(\s*icon: HugeIcons\.strokeRoundedPlaylist01,.*?\),\s*onPressed: \(\) \{.*?\},\s*\),\s*)(IconButton\(\s*icon: const HugeIcon\(\s*icon: HugeIcons\.strokeRoundedMoreVertical,)',
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

if footer_pattern.search(content):
    content = footer_pattern.sub(footer_replacement, content)
else:
    print("Footer pattern not found!")

with open('D:/scrollMusic/lib/widgets/song_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
