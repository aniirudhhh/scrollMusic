content = '''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../data/lyrics_service.dart';
import '../../models/lyric_line.dart';
import '../../models/song.dart';
import '../home/home_controller.dart';
import '../../models/playback_state.dart';
import '../../widgets/wavy_progress_bar.dart';
import '../../widgets/playback_button.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.watch<HomeController>();
    controller.positionNotifier.addListener(_onPositionChanged);
  }

  @override
  void didUpdateWidget(LyricsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.id != widget.song.id) {
      _fetchLyrics();
    }
  }
  
  Future<void> _fetchLyrics() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    
    try {
      final controller = context.read<HomeController>();
      final duration = controller.duration ?? const Duration(seconds: 200);
      final lines = await _lyricsService.fetchLyrics(
        widget.song.title,
        widget.song.artist,
        duration.inSeconds,
      );
      
      if (mounted) {
        setState(() {
          _lyrics = lines;
          _isLoading = false;
          if (_lyrics == null || _lyrics!.isEmpty) {
            _error = 'No lyrics found';
          } else {
            final hasTimestamps = _lyrics!.any((l) => l.timeMs > 0);
            _isSynced = hasTimestamps;
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
    if (!mounted || !_isSynced || _lyrics == null || _lyrics!.isEmpty) return;
    
    final position = context.read<HomeController>().positionNotifier.value.inMilliseconds;
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
      _scrollToActive();
    }
  }

  void _scrollToActive() {
    if (!_scrollController.hasClients || _activeIndex < 0) return;
    
    final targetOffset = (_activeIndex * 48.0) - (MediaQuery.of(context).size.height * 0.3);
    
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
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
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(80),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isSynced = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isSynced ? Colors.white.withAlpha(200) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Center(
                                  child: Text(
                                    'Synced',
                                    style: TextStyle(
                                      color: _isSynced ? Colors.black : Colors.white54,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isSynced = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isSynced ? Colors.white.withAlpha(200) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Center(
                                  child: Text(
                                    'Static',
                                    style: TextStyle(
                                      color: !_isSynced ? Colors.black : Colors.white54,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildLyricsContent(),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 32,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricsContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    
    if (_error.isNotEmpty || _lyrics == null || _lyrics!.isEmpty) {
      return Center(
        child: Text(
          _error.isEmpty ? 'No lyrics available' : _error,
          style: const TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 250),
      physics: const BouncingScrollPhysics(),
      itemCount: _lyrics!.length,
      itemBuilder: (context, index) {
        final line = _lyrics![index];
        final isActive = _isSynced && index == _activeIndex;
        
        return Padding(
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
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return minutes + ":" + seconds;
  }
}
'''

with open('D:/scrollMusic/lib/screens/lyrics/lyrics_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
