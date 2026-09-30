import re

with open('D:/scrollMusic/lib/screens/lyrics/lyrics_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add the DynamicSingleColorBackground inside the Stack
stack_target = '''        child: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: ['''

stack_replacement = '''        child: Stack(
          children: [
            const Positioned.fill(
              child: DynamicSingleColorBackground(),
            ),
            Positioned.fill(
              child: Column(
                children: ['''

content = content.replace(stack_target, stack_replacement)

# 2. Fix the play pause button and progress bar to use dominant color
button_target = '''                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFC3D8B4),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(50),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                      child: PlaybackButton(
                        state: controller.playbackState,
                        onTap: () => controller.togglePlayPause(),
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(200),
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
                                    activeColor: const Color(0xFFE5B8CD),
                                    inactiveColor: Colors.white.withAlpha(50),
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
                  ),'''

button_replacement = '''                  ValueListenableBuilder<Color?>(
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

content = content.replace(button_target, button_replacement)

with open('D:/scrollMusic/lib/screens/lyrics/lyrics_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
