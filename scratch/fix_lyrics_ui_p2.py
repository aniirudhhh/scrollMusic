import re

with open('D:/scrollMusic/lib/screens/lyrics/lyrics_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

bottom_old = '''                  ValueListenableBuilder<Color?>(
                    valueListenable: DynamicSingleColorBackground.dominantColorNotifier,
                    builder: (context, dominantColor, _) {
                      final themeColor = dominantColor ?? Colors.white;
                      final isLight = themeColor.computeLuminance() > 0.5;
                      final iconColor = isLight ? Colors.black : Colors.white;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: () => controller.togglePlayPause(),
                              behavior: HitTestBehavior.opaque,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  color: themeColor,
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: themeColor.withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 16),
                                child: Icon(
                                  controller.playbackState == PlaybackState.playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 42,
                                  color: iconColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: ValueListenableBuilder<Duration>(
                              valueListenable: controller.positionNotifier,
                              builder: (context, position, child) {
                                return ValueListenableBuilder<Duration?>(
                                  valueListenable: controller.durationNotifier,
                                  builder: (context, duration, child) {
                                    return Row(
                                      children: [
                                        Text(
                                          _formatDuration(position),
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: WavyProgressBar(
                                            value: duration != null && duration.inMilliseconds > 0 
                                              ? position.inMilliseconds / duration.inMilliseconds 
                                              : 0.0,
                                            onChanged: (val) {
                                              if (duration != null) {
                                                controller.seek(Duration(milliseconds: (val * duration.inMilliseconds).toInt()));
                                              }
                                            },
                                            activeColor: themeColor,
                                            inactiveColor: Colors.white.withValues(alpha: 0.2),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _formatDuration(duration ?? const Duration(minutes: 3)),
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    );
                                  }
                                );
                              }
                            ),
                          ),
                        ],
                      );
                    }
                  ),'''

bottom_new = '''                  ValueListenableBuilder<Color?>(
                    valueListenable: DynamicSingleColorBackground.dominantColorNotifier,
                    builder: (context, dominantColor, _) {
                      final themeColor = dominantColor ?? Colors.black;
                      
                      // Derive a dark, solid color for the pill matching the theme palette
                      final darkSolidBg = Color.lerp(themeColor, Colors.black, 0.75)!.withValues(alpha: 1.0);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: () => controller.togglePlayPause(),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC3D8B4), // Subtle pastel green from mockup
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 16),
                                child: Icon(
                                  controller.playbackState == PlaybackState.playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 42,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: darkSolidBg, // Solid background matching theme palette
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: ValueListenableBuilder<Duration>(
                              valueListenable: controller.positionNotifier,
                              builder: (context, position, child) {
                                return ValueListenableBuilder<Duration?>(
                                  valueListenable: controller.durationNotifier,
                                  builder: (context, duration, child) {
                                    return Row(
                                      children: [
                                        Text(
                                          _formatDuration(position),
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: WavyProgressBar(
                                            value: duration != null && duration.inMilliseconds > 0 
                                              ? position.inMilliseconds / duration.inMilliseconds 
                                              : 0.0,
                                            onChanged: (val) {
                                              if (duration != null) {
                                                controller.seek(Duration(milliseconds: (val * duration.inMilliseconds).toInt()));
                                              }
                                            },
                                            activeColor: const Color(0xFFE5B8CD), // Subtle pastel pink from mockup
                                            inactiveColor: Colors.white.withValues(alpha: 0.2),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _formatDuration(duration ?? const Duration(minutes: 3)),
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    );
                                  }
                                );
                              }
                            ),
                          ),
                        ],
                      );
                    }
                  ),'''

content = content.replace(bottom_old, bottom_new)

with open('D:/scrollMusic/lib/screens/lyrics/lyrics_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
