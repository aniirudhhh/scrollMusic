import 'package:flutter/material.dart';
import '../models/lyric_line.dart';
import '../data/lyrics_service.dart';

class SingleLineLyricsView extends StatefulWidget {
  const SingleLineLyricsView({
    super.key,
    required this.title,
    required this.artist,
    required this.durationNotifier,
    required this.positionNotifier,
    required this.isCurrent,
    required this.onTap,
  });

  final String title;
  final String artist;
  final ValueNotifier<Duration?> durationNotifier;
  final ValueNotifier<Duration> positionNotifier;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  State<SingleLineLyricsView> createState() => _SingleLineLyricsViewState();
}

class _SingleLineLyricsViewState extends State<SingleLineLyricsView> {
  final _lyricsService = LyricsService();
  List<LyricLine>? _lyrics;
  bool _isLoading = true;
  int _activeIndex = -1;

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
  void didUpdateWidget(SingleLineLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.positionNotifier != widget.positionNotifier) {
      oldWidget.positionNotifier.removeListener(_onPositionChanged);
      widget.positionNotifier.addListener(_onPositionChanged);
    }
    
    if (oldWidget.title != widget.title || oldWidget.artist != widget.artist) {
      _fetchLyrics();
    } else if (_lyrics != null) {
      _updateActiveIndex();
    }
  }

  @override
  void dispose() {
    widget.positionNotifier.removeListener(_onPositionChanged);
    super.dispose();
  }

  Future<void> _fetchLyrics() async {
    setState(() {
      _isLoading = true;
      _lyrics = null;
      _activeIndex = -1;
    });

    try {
      final duration = widget.durationNotifier.value;
      final seconds = duration?.inSeconds ?? 0;
      final result = await _lyricsService.fetchLyrics(widget.title, widget.artist, seconds);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _lyrics = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateActiveIndex() {
    if (_lyrics == null || _lyrics!.isEmpty) return;
    
    final ms = widget.positionNotifier.value.inMilliseconds + 400;
    
    int newIndex = -1;
    for (int i = 0; i < _lyrics!.length; i++) {
      if (_lyrics![i].timeMs <= ms) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _activeIndex) {
      setState(() => _activeIndex = newIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 24); // Keep space while loading
    }

    String displayText;
    if (_lyrics == null || _lyrics!.isEmpty) {
      displayText = 'Lyrics not available';
    } else {
      final activeText = _activeIndex >= 0 && _activeIndex < _lyrics!.length 
          ? _lyrics![_activeIndex].text 
          : '...';
      // If the active lyric is empty (e.g. instrumental gap), use a music note
      displayText = activeText.trim().isEmpty ? '♪' : activeText;
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.zero,
        color: Colors.transparent, // Expand hit area
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.centerLeft,
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            final isEntering = child.key == ValueKey<String>(displayText);
            final offsetAnimation = Tween<Offset>(
              begin: isEntering ? const Offset(0, -0.5) : const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: offsetAnimation,
                child: child,
              ),
            );
          },
          child: Text(
            displayText,
            key: ValueKey<String>(displayText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
      ),
    );
  }
}
