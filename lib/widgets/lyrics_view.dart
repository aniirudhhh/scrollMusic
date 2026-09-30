import 'package:flutter/material.dart';
import '../models/lyric_line.dart';
import '../data/lyrics_service.dart';

class LyricsView extends StatefulWidget {
  const LyricsView({
    super.key,
    required this.title,
    required this.artist,
    required this.durationNotifier,
    required this.positionNotifier,
    required this.isCurrent,
    this.onTap,
  });

  final VoidCallback? onTap;

  final String title;
  final String artist;
  final ValueNotifier<Duration?> durationNotifier;
  final ValueNotifier<Duration> positionNotifier;
  final bool isCurrent;

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final _lyricsService = LyricsService();
  final _scrollController = ScrollController();
  
  List<LyricLine>? _lyrics;
  bool _isLoading = true;
  String _error = '';
  
  int _activeIndex = -1;
  bool _isFirstScroll = true;
  int _fetchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
    widget.positionNotifier.addListener(_onPositionChanged);
  }

  void _onPositionChanged() {
    if (widget.isCurrent && mounted) {
      _updateActiveIndex();
    }
  }

  @override
  void didUpdateWidget(LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.positionNotifier != widget.positionNotifier) {
      oldWidget.positionNotifier.removeListener(_onPositionChanged);
      widget.positionNotifier.addListener(_onPositionChanged);
    }
    
    // Fetch again if song changes
    if (oldWidget.title != widget.title || oldWidget.artist != widget.artist) {
      _fetchLyrics();
    } else if (_lyrics != null) {
      _updateActiveIndex();
    }
  }
  
  @override
  void dispose() {
    widget.positionNotifier.removeListener(_onPositionChanged);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchLyrics() async {
    final generation = ++_fetchGeneration;
    setState(() {
      _isLoading = true;
      _error = '';
      _lyrics = null;
    });

    try {
      final duration = widget.durationNotifier.value;
      final seconds = duration?.inSeconds ?? 0;
      final result = await _lyricsService.fetchLyrics(widget.title, widget.artist, seconds);
      
      if (mounted && generation == _fetchGeneration) {
        setState(() {
          _isLoading = false;
          _lyrics = result;
          _isFirstScroll = true;
          if (result == null || result.isEmpty) {
            _error = "Looks like we don't have lyrics for this song yet.";
          }
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && generation == _fetchGeneration) _updateActiveIndex();
        });
      }
    } catch (e) {
      if (mounted && generation == _fetchGeneration) {
        setState(() {
          _isLoading = false;
          _error = "Failed to load lyrics.";
        });
      }
    }
  }

  final Map<int, GlobalKey> _lineKeys = {};

  void _updateActiveIndex() {
    if (_lyrics == null || _lyrics!.isEmpty) return;
    
    final ms = widget.positionNotifier.value.inMilliseconds + 400;
    
    // Find the last line that is <= current time
    int newIndex = -1;
    for (int i = 0; i < _lyrics!.length; i++) {
      if (_lyrics![i].timeMs <= ms) {
        newIndex = i;
      } else {
        break; // Found the first line in the future
      }
    }

    if (newIndex != _activeIndex || _isFirstScroll) {
      if (newIndex != _activeIndex) {
        setState(() => _activeIndex = newIndex);
      }
      
      // Perfectly center the active line by manually animating the inner scroll controller
      if (_activeIndex >= 0) {
        final key = _lineKeys[_activeIndex];
        if (key != null && key.currentContext != null) {
          final box = key.currentContext!.findRenderObject() as RenderBox?;
          final scrollableState = Scrollable.of(key.currentContext!);
          
          if (box != null) {
            final scrollBox = scrollableState.context.findRenderObject() as RenderBox?;
            if (scrollBox != null) {
              final offset = box.localToGlobal(Offset.zero, ancestor: scrollBox);
              
              final currentScroll = _scrollController.offset;
              final targetScroll = currentScroll + offset.dy - (scrollBox.size.height / 2) + (box.size.height / 2);
              final clampedTarget = targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent);
              
              if (_isFirstScroll) {
                _isFirstScroll = false;
                _scrollController.jumpTo(clampedTarget);
              } else {
                _scrollController.animateTo(
                  clampedTarget,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                );
              }
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }
    
    if (_error.isNotEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Text(
                  "Meow... no lyrics found for this song",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withAlpha(160),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Initialize keys if needed
    if (_lineKeys.length != _lyrics!.length) {
      _lineKeys.clear();
      for (int i = 0; i < _lyrics!.length; i++) {
        _lineKeys[i] = GlobalKey();
      }
    }

    return ShaderMask(
      shaderCallback: (rect) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, 0.15, 0.85, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstIn,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap,
        child: SingleChildScrollView(
          controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 180, horizontal: 16),
        child: Column(
          children: List.generate(_lyrics!.length, (index) {
            final line = _lyrics![index];
            if (line.isGap) return SizedBox(key: _lineKeys[index], height: 24);

            final isActive = index == _activeIndex;
            final isPassed = index < _activeIndex;

            return Container(
              key: _lineKeys[index],
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: AnimatedScale(
                scale: isActive ? 1.0 : 0.85,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 400),
                  style: TextStyle(
                    fontSize: 20, // Base layout size (max size)
                    fontWeight: FontWeight.w700, 
                    color: isActive 
                        ? Colors.white 
                        : (isPassed ? Colors.white.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.3)),
                    height: 1.4,
                  ),
                  child: Text(
                    line.text,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }),
          ),
        ),
      ),
    );
  }
}
