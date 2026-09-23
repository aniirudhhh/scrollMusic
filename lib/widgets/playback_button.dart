import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/playback_state.dart';

/// Animated play/pause/loading/error button.
/// Shows a circular progress ring when loading or buffering so the user
/// always knows a song is being prepared in the background.
class PlaybackButton extends StatelessWidget {
  const PlaybackButton({
    super.key,
    required this.state,
    required this.onTap,
    this.size = 72,
  });

  final PlaybackState state;
  final VoidCallback onTap;
  final double size;

  bool get _isLoading =>
      state == PlaybackState.loading || state == PlaybackState.buffering;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Spinning ring shown during loading / buffering ──────────────
            if (_isLoading)
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat())
               .rotate(duration: const Duration(milliseconds: 900)),

            // ── Filled circle button ────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: _isLoading ? size - 12 : size,
              height: _isLoading ? size - 12 : size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _buttonColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(child: _buildIcon()),
            )
                .animate(key: ValueKey(state))
                .scaleXY(
                  begin: 0.85,
                  end: 1.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: const Duration(milliseconds: 200)),
          ],
        ),
      ),
    );
  }

  Color get _buttonColor => switch (state) {
        PlaybackState.error => const Color(0xFFE53935),
        _ => Colors.white,
      };

  Widget _buildIcon() => switch (state) {
        PlaybackState.loading || PlaybackState.buffering => Icon(
            Icons.music_note_rounded,
            size: 28,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        PlaybackState.playing => const Icon(
            Icons.pause_rounded,
            size: 36,
            color: Colors.black,
          ),
        PlaybackState.error => const Icon(
            Icons.refresh_rounded,
            size: 32,
            color: Colors.white,
          ),
        _ => const Icon(
            Icons.play_arrow_rounded,
            size: 38,
            color: Colors.black,
          ),
      };
}
