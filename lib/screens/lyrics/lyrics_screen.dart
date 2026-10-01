import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../data/lyrics_service.dart';
import '../../models/lyric_line.dart';
import '../../models/song.dart';
import '../../widgets/dynamic_single_color_background.dart';
import '../home/home_controller.dart';
import '../../models/playback_state.dart';
import '../../widgets/apple_progress_bar.dart';
import '../../widgets/bounce_button.dart';

class LyricsScreen extends StatefulWidget {
  final Song song;

  const LyricsScreen({super.key, required this.song});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  final _lyricsService = LyricsService();
  final ScrollController _scrollController = ScrollController();
  
  List<LyricLine>? _lyrics;
  bool _isLoading = true;
  String _error = '';
  
  bool _isSynced = true;
  int _activeIndex = -1;
  List<GlobalKey> _lineKeys = [];
  
  late String _currentSongId;
  late Song _currentSong;
  HomeController? _homeController;

  @override
  void initState() {
    super.initState();
    _currentSong = widget.song;
    _currentSongId = widget.song.id;
    _fetchLyrics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.watch<HomeController>();
    
    if (_homeController != controller) {
      if (_homeController != null) {
        _homeController!.positionNotifier.removeListener(_onPositionChanged);
      }
      _homeController = controller;
      _homeController!.positionNotifier.addListener(_onPositionChanged);
    }
    
    final newSong = controller.currentSong;
    if (newSong != null && newSong.id != _currentSongId) {
      _currentSongId = newSong.id;
      _currentSong = newSong;
      _fetchLyrics();
    }
  }

  @override
  void dispose() {
    if (_homeController != null) {
      _homeController!.positionNotifier.removeListener(_onPositionChanged);
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LyricsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id && widget.song.id != _currentSongId) {
      _currentSongId = widget.song.id;
      _currentSong = widget.song;
      _fetchLyrics();
    }
  }
  
  Future<void> _fetchLyrics() async {
    final targetSong = _currentSong;
    setState(() {
      _isLoading = true;
      _error = '';
    });
    
    try {
      final controller = context.read<HomeController>();
      final duration = controller.duration ?? const Duration(seconds: 200);
      final lines = await _lyricsService.fetchLyrics(
        targetSong.title,
        targetSong.artist,
        duration.inSeconds,
      );
      
      if (mounted) {
        if (targetSong.id != _currentSongId) return; // Discard if song changed

        setState(() {
          _lyrics = lines;
          _lineKeys = List.generate(lines?.length ?? 0, (index) => GlobalKey());
          _isLoading = false;
          if (_lyrics == null || _lyrics!.isEmpty) {
            _error = 'No lyrics found';
          } else {
            final hasTimestamps = _lyrics!.any((l) => l.timeMs > 0);
            _isSynced = hasTimestamps;
            if (_isSynced) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onPositionChanged();
              });
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load lyrics';
        });
      }
    }
  }

  void _onPositionChanged() {
    if (!mounted || !_isSynced || _lyrics == null || _lyrics!.isEmpty || _homeController == null) return;
    
    final position = _homeController!.positionNotifier.value.inMilliseconds + 400;
    int newIndex = -1;
    
    for (int i = 0; i < _lyrics!.length; i++) {
      if (position >= _lyrics![i].timeMs) {
        newIndex = i;
      } else {
        break;
      }
    }
    
    if (newIndex != _activeIndex && newIndex != -1) {
      setState(() {
        _activeIndex = newIndex;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActive();
      });
    }
  }

  void _scrollToActive() {
    if (!_scrollController.hasClients || _activeIndex < 0 || _activeIndex >= _lineKeys.length || !_isSynced) return;
    
    final key = _lineKeys[_activeIndex];
    final currentContext = key.currentContext;
    if (currentContext != null) {
      Scrollable.ensureVisible(
        currentContext,
        alignment: 0.4, // Slightly above absolute center so it's visually pleasing above the playback controls
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DynamicSingleColorBackground(),
          ),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(150),
                              shape: BoxShape.circle,
                            ),
                            child: const HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowLeft01,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Lyrics',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isSynced = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _isSynced ? Colors.white.withAlpha(220) : Colors.black.withAlpha(80),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  'Synced',
                                  style: TextStyle(
                                    color: _isSynced ? Colors.black : Colors.white54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isSynced = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_isSynced ? Colors.white.withAlpha(220) : Colors.black.withAlpha(80),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  'Static',
                                  style: TextStyle(
                                    color: !_isSynced ? Colors.black : Colors.white54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildLyricsContent(),
                  ),
                ],
              ),
            ),
            ),
            Positioned(
              bottom: 32,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<Color?>(
                    valueListenable: DynamicSingleColorBackground.dominantColorNotifier,
                    builder: (context, dominantColor, _) {
                      final themeColor = dominantColor ?? Colors.black;
                      
                      // Dynamically generate subtle pastel color from the artwork theme!
                      final pastelColor = HSLColor.fromColor(themeColor).withLightness(0.85).withSaturation(0.4).toColor();
                      // Derive a dark, solid color for the pill matching the theme palette
                      final darkSolidBg = Color.lerp(themeColor, Colors.black, 0.75)!.withValues(alpha: 1.0);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: BounceButton(
                              onTap: () => controller.togglePlayPause(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: pastelColor, // Dynamically generated subtle pastel!
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                                          child: AppleProgressBar(
                                            value: duration != null && duration.inMilliseconds > 0 
                                              ? position.inMilliseconds / duration.inMilliseconds 
                                              : 0.0,
                                            onChangeEnd: (val) {
                                              if (duration != null) {
                                                controller.seek(Duration(milliseconds: (val * duration.inMilliseconds).toInt()));
                                              }
                                            },
                                            activeColor: pastelColor,
                                            inactiveColor: Colors.white.withValues(alpha: 0.2),
                                            isPaused: controller.playbackState != PlaybackState.playing,
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
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildLyricsContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    
    if (_error.isNotEmpty || _lyrics == null || _lyrics!.isEmpty) {
      return Container(
        alignment: const Alignment(0, -0.3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              "Meow... no lyrics found for this song",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(160),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    
    // Safety sync for Hot Reloads where state is preserved but new variables aren't
    if (_lineKeys.length != _lyrics!.length) {
      _lineKeys = List.generate(_lyrics!.length, (_) => GlobalKey());
    }
    
    return ShaderMask(
      shaderCallback: (Rect rect) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black,
            Colors.black,
            Colors.transparent,
          ],
          stops: [0.0, 0.15, 0.85, 1.0], // Fade out top 15% and bottom 15%
        ).createShader(rect);
      },
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.only(left: 24, right: 24, top: MediaQuery.of(context).size.height * 0.4, bottom: MediaQuery.of(context).size.height * 0.5),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(_lyrics!.length, (index) {
            final line = _lyrics![index];
            final isActive = _isSynced && index == _activeIndex;
            
            return GestureDetector(
              key: _lineKeys[index],
              onTap: () {
                if (_isSynced && line.timeMs >= 0) {
                  context.read<HomeController>().seek(Duration(milliseconds: line.timeMs));
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  line.text.isEmpty ? '• • •' : line.text,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: isActive ? 24 : 22,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive ? Colors.white : Colors.white.withAlpha(120),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return minutes + ":" + seconds;
  }
}
