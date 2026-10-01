import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class AnimatedPlaybackControls extends StatelessWidget {
  const AnimatedPlaybackControls({
    super.key,
    required this.isPlaying,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
    this.height = 90.0,
    this.colorPreviousButton,
    this.colorPlayPause,
    this.colorNextButton,
    this.tintPreviousIcon,
    this.tintPlayPauseIcon,
    this.tintNextIcon,
    this.playPauseIconSize = 40.0,
    this.iconSize = 28.0,
  });

  final bool isPlaying;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final double height;
  final Color? colorPreviousButton;
  final Color? colorPlayPause;
  final Color? colorNextButton;
  final Color? tintPreviousIcon;
  final Color? tintPlayPauseIcon;
  final Color? tintNextIcon;
  final double playPauseIconSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final cPlay = colorPlayPause ?? colorScheme.primary;
    final cPrev = tintPreviousIcon ?? colorScheme.onSecondaryContainer;
    final cNext = tintNextIcon ?? colorScheme.onSecondaryContainer;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous Button
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            onPrevious();
          },
          icon: Icon(
            CupertinoIcons.backward_fill,
            color: cPrev,
            size: iconSize,
          ),
          constraints: const BoxConstraints(
            minWidth: 48.0,
            minHeight: 48.0,
          ),
          splashRadius: 24.0,
        ),
        
        const SizedBox(width: 32.0),
        
        // Play/Pause Button
        IconButton(
          onPressed: () {
            HapticFeedback.selectionClick();
            onPlayPause();
          },
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Icon(
              isPlaying ? CupertinoIcons.pause_solid : CupertinoIcons.play_arrow_solid,
              key: ValueKey<bool>(isPlaying),
              color: cPlay,
              size: playPauseIconSize,
            ),
          ),
          constraints: const BoxConstraints(
            minWidth: 48.0,
            minHeight: 48.0,
          ),
          splashRadius: 32.0,
        ),
        
        const SizedBox(width: 32.0),
        
        // Next Button
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            onNext();
          },
          icon: Icon(
            CupertinoIcons.forward_fill,
            color: cNext,
            size: iconSize,
          ),
          constraints: const BoxConstraints(
            minWidth: 48.0,
            minHeight: 48.0,
          ),
          splashRadius: 24.0,
        ),
      ],
    );
  }
}
