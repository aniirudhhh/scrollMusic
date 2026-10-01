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
  List<GlobalKey>? _keys;
  bool _isLoading = true;
  String _error = '';
  
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
    _activeIndexNotifier.dispose();
    super.dispose();
  }

  Future<void> _fetchLyrics() async {
    final generation = ++_fetchGeneration;
    setState(() {
      _isLoading = true;
      _error = '';
      _lyrics = null;
      _keys = null;
    });

    try {
      final duration = widget.durationNotifier.value;
      final seconds = duration?.inSeconds ?? 0;
      final result = await _lyricsService.fetchLyrics(widget.title, widget.artist, seconds);
      
      if (mounted && generation == _fetchGeneration) {
        setState(() {
          _isLoading = false;
          _lyrics = result;
          if (result != null) {
            _keys = List.generate(result.length, (i) => GlobalKey());
          }
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

  final ValueNotifier<int> _activeIndexNotifier = ValueNotifier(-1);
  int get _activeIndex => _activeIndexNotifier.value;

  void _updateActiveIndex() {
    if (_lyrics == null || _lyrics!.isEmpty || _keys == null) return;
    
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
        _activeIndexNotifier.value = newIndex;
      }
      
      if (newIndex >= 0 && newIndex < _keys!.length) {
        final key = _keys![newIndex];
        
        void scrollToKey() {
          if (key.currentContext != null) {
            final renderObject = key.currentContext!.findRenderObject();
            if (renderObject != null && _scrollController.hasClients) {
              _scrollController.position.ensureVisible(
                renderObject,
                alignment: 0.5,
                duration: _isFirstScroll ? Duration.zero : const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
              );
              _isFirstScroll = false;
            }
          }
        }
        
        if (key.currentContext != null) {
          scrollToKey();
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) scrollToKey();
          });
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

    if (_lyrics == null || _keys == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final halfHeight = constraints.maxHeight / 2;
        
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
              padding: EdgeInsets.symmetric(vertical: halfHeight, horizontal: 16),
              child: Column(
                children: List.generate(_lyrics!.length, (index) {
                  final line = _lyrics![index];
                  final key = _keys![index];
                  
                  if (line.isGap) return SizedBox(key: key, height: 24);

                  return ValueListenableBuilder<int>(
                    valueListenable: _activeIndexNotifier,
                    builder: (context, activeIdx, child) {
                      final isActive = index == activeIdx;
                      final isPassed = index < activeIdx;

                      return Container(
                        key: key,
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
                    },
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
