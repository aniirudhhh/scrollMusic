import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'dart:async';

enum _PlaybackButtonType { none, previous, playPause, next }

class _WeightVector {
  final double prev;
  final double play;
  final double next;

  const _WeightVector(this.prev, this.play, this.next);

  factory _WeightVector.normal(double base) => _WeightVector(base, base, base);
  factory _WeightVector.expandedPrev(double expand, double compress) => _WeightVector(expand, compress, compress);
  factory _WeightVector.expandedPlay(double expand, double compress) => _WeightVector(compress, expand, compress);
  factory _WeightVector.expandedNext(double expand, double compress) => _WeightVector(compress, compress, expand);

  static _WeightVector lerp(_WeightVector a, _WeightVector b, double t) {
    return _WeightVector(
      a.prev + (b.prev - a.prev) * t,
      a.play + (b.play - a.play) * t,
      a.next + (b.next - a.next) * t,
    );
  }
}

class AnimatedPlaybackControls extends StatefulWidget {
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
    this.playPauseIconSize = 36.0,
    this.iconSize = 32.0,
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
  State<AnimatedPlaybackControls> createState() => _AnimatedPlaybackControlsState();
}

class _AnimatedPlaybackControlsState extends State<AnimatedPlaybackControls> with SingleTickerProviderStateMixin {
  late AnimationController _springController;

  _PlaybackButtonType _lastClicked = _PlaybackButtonType.none;
  int _clickToken = 0;

  late bool _visualPlayingState;
  bool? _pendingPlayPauseState;

  final double _baseWeight = 1.0;
  final double _expandedWeight = 1.1;
  final double _compressedWeight = 0.65;

  late _WeightVector _currentWeights;
  late _WeightVector _startWeights;
  late _WeightVector _targetWeights;

  late Widget _prevIcon;
  late Widget _nextIcon;

  @override
  void initState() {
    super.initState();
    _visualPlayingState = widget.isPlaying;
    _currentWeights = _WeightVector.normal(_baseWeight);
    _startWeights = _currentWeights;
    _targetWeights = _currentWeights;

    _springController = AnimationController.unbounded(vsync: this);
    _springController.addListener(() {
      setState(() {
        _currentWeights = _WeightVector.lerp(_startWeights, _targetWeights, _springController.value);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateStaticIcons();
  }

  @override
  void didUpdateWidget(covariant AnimatedPlaybackControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.iconSize != widget.iconSize ||
        oldWidget.tintPreviousIcon != widget.tintPreviousIcon ||
        oldWidget.tintNextIcon != widget.tintNextIcon) {
      _updateStaticIcons();
    }

    if (oldWidget.isPlaying != widget.isPlaying) {
      if (_lastClicked != _PlaybackButtonType.none) {
        _pendingPlayPauseState = widget.isPlaying;
      } else {
        setState(() {
          _visualPlayingState = widget.isPlaying;
        });
      }
    }
  }

  void _updateStaticIcons() {
    final colorScheme = Theme.of(context).colorScheme;
    final tPrev = widget.tintPreviousIcon ?? colorScheme.onSecondaryContainer;
    final tNext = widget.tintNextIcon ?? colorScheme.onSecondaryContainer;
    _prevIcon = Icon(Icons.skip_previous_rounded, color: tPrev, size: widget.iconSize);
    _nextIcon = Icon(Icons.skip_next_rounded, color: tNext, size: widget.iconSize);
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _setClickedState(_PlaybackButtonType type) {
    _startWeights = _currentWeights;
    switch (type) {
      case _PlaybackButtonType.none:
        _targetWeights = _WeightVector.normal(_baseWeight);
        break;
      case _PlaybackButtonType.previous:
        _targetWeights = _WeightVector.expandedPrev(_expandedWeight, _compressedWeight);
        break;
      case _PlaybackButtonType.playPause:
        _targetWeights = _WeightVector.expandedPlay(_expandedWeight, _compressedWeight);
        break;
      case _PlaybackButtonType.next:
        _targetWeights = _WeightVector.expandedNext(_expandedWeight, _compressedWeight);
        break;
    }
    _lastClicked = type;

    final spring = SpringDescription(mass: 1, stiffness: 380, damping: 26);
    final simulation = SpringSimulation(spring, 0, 1, _springController.velocity);
    _springController.animateWith(simulation);
  }

  void _applyPendingState() {
    if (_pendingPlayPauseState != null) {
      setState(() {
        _visualPlayingState = _pendingPlayPauseState!;
        _pendingPlayPauseState = null;
      });
    }
  }

  void _handlePrev() {
    final token = ++_clickToken;
    _setClickedState(_PlaybackButtonType.previous);
    
    // The user provided custom timing: wait 180ms before firing callback, hold 600ms total.
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted || _clickToken != token) return;
      widget.onPrevious();
      
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted || _clickToken != token) return;
        _setClickedState(_PlaybackButtonType.none);
        _applyPendingState();
      });
    });
  }

  void _handleNext() {
    final token = ++_clickToken;
    _setClickedState(_PlaybackButtonType.next);
    
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted || _clickToken != token) return;
      widget.onNext();
      
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted || _clickToken != token) return;
        _setClickedState(_PlaybackButtonType.none);
        _applyPendingState();
      });
    });
  }

  void _handlePlayPause() {
    final token = ++_clickToken;
    _setClickedState(_PlaybackButtonType.playPause);
    
    HapticFeedback.selectionClick();
    
    setState(() {
      _visualPlayingState = !_visualPlayingState;
      _pendingPlayPauseState = null;
    });
    
    widget.onPlayPause();
    
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted || _clickToken != token) return;
      _setClickedState(_PlaybackButtonType.none);
      _applyPendingState();
    });
  }

  Widget _buildButton({
    required double width,
    required double height,
    required Color color,
    required ShapeBorder shape,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: color,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cPrev = widget.colorPreviousButton ?? colorScheme.secondaryContainer;
    final cPlay = widget.colorPlayPause ?? colorScheme.primary;
    final cNext = widget.colorNextButton ?? colorScheme.secondaryContainer;
    final tPlay = widget.tintPlayPauseIcon ?? colorScheme.onPrimary;

    final playCornerPlaying = widget.height * 0.85; // Increased for a rounder squircle
    final playCornerPaused = widget.height * 0.45; // Increased for a rounder squircle

    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _springController,
          builder: (context, child) {
            const gap = 6.0;
            final availableWidth = constraints.maxWidth - (gap * 2);
            final totalWeight = _currentWeights.prev + _currentWeights.play + _currentWeights.next;
            
            final wPrev = (availableWidth * (_currentWeights.prev / totalWeight)).clamp(0.0, double.infinity);
            final wPlay = (availableWidth * (_currentWeights.play / totalWeight)).clamp(0.0, double.infinity);
            final wNext = (availableWidth * (_currentWeights.next / totalWeight)).clamp(0.0, double.infinity);

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildButton(
                  width: wPrev,
                  height: widget.height,
                  color: cPrev,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.height / 2)),
                  onTap: _handlePrev,
                  child: _prevIcon,
                ),
                SizedBox(width: gap),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: _visualPlayingState ? playCornerPlaying : playCornerPaused),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.fastOutSlowIn,
                  builder: (context, radius, child) {
                    return _buildButton(
                      width: wPlay,
                      height: widget.height,
                      color: cPlay,
                      shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(radius)),
                      onTap: _handlePlayPause,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeOut,
                        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                        child: Icon(
                          _visualPlayingState ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          key: ValueKey<bool>(_visualPlayingState),
                          color: tPlay,
                          size: widget.playPauseIconSize,
                        ),
                      ),
                    );
                  }
                ),
                SizedBox(width: gap),
                _buildButton(
                  width: wNext,
                  height: widget.height,
                  color: cNext,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.height / 2)),
                  onTap: _handleNext,
                  child: _nextIcon,
                ),
              ],
            );
          }
        );
      }
    );
  }
}

