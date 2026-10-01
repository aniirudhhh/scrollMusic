import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'animated_playback_controls.dart';
import '../data/library_manager.dart';
import '../screens/home/home_controller.dart';
import '../models/playback_state.dart';
import '../models/song.dart';
import '../screens/lyrics/lyrics_screen.dart';
import 'artwork_widget.dart';
import 'lyrics_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hugeicons/hugeicons.dart';
import '../core/utils/app_toast.dart';
import '../screens/queue/queue_screen.dart';
import 'song_options_sheet.dart';
import 'single_line_lyrics_view.dart';
import 'apple_progress_bar.dart';
import '../models/artist.dart';
import '../screens/artist/artist_screen.dart';
import 'package:palette_generator/palette_generator.dart';

class SongPage extends StatefulWidget {
  const SongPage({
    super.key,
    required this.song,
    required this.index,
  });

  final Song song;
  final int index;

  @override
  State<SongPage> createState() => _SongPageState();
}

class _SongPageState extends State<SongPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _showLyrics = false;
  Color? _primaryColor;
  Color? _onPrimaryColor;
  Color? _secondaryContainer;
  Color? _onSecondaryContainer;

  void _scheduleColorExtraction() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      final scrollable = Scrollable.maybeOf(context);
      if (scrollable != null && scrollable.position.isScrollingNotifier.value) {
        // If still scrolling, check again shortly.
        // This completely prevents GPU readback stalls from interrupting the snap animation.
        _scheduleColorExtraction();
      } else {
        _extractColor();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _scheduleColorExtraction();
  }

  @override
  void didUpdateWidget(SongPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.artwork != widget.song.artwork) {
      _showLyrics = false;
      _primaryColor = null;
      _onPrimaryColor = null;
      _secondaryContainer = null;
      _onSecondaryContainer = null; // reset to white instantly
      _scheduleColorExtraction();
    }
  }

  Future<void> _extractColor() async {
    if (!mounted) return;
    try {
      final imageProvider = ResizeImage(
        CachedNetworkImageProvider(
          widget.song.artwork,
          maxWidth: 800,
          errorListener: (err) => debugPrint('Palette image error ignored'),
        ),
        width: 12, // Force decode to 12px for lightning fast extraction!
      );

      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 5,
        size: const Size(12, 12),
      );
      if (mounted) {
        setState(() {
          final baseColor =
              palette.dominantColor?.color ?? palette.vibrantColor?.color;
          if (baseColor != null) {
            final hct = Hct.fromInt(baseColor.value);
            final hue = hct.hue;
            final chroma = math.max(hct.chroma, 30.0);
            
            _primaryColor = Color(Hct.from(hue, chroma, 80.0).toInt());
            _onPrimaryColor = Color(Hct.from(hue, chroma, 20.0).toInt());
            _secondaryContainer = Color(Hct.from(hue, chroma * 0.5, 35.0).toInt());
            _onSecondaryContainer = Color(Hct.from(hue, chroma * 0.5, 90.0).toInt());
          } else {
            _primaryColor = Colors.white;
            _onPrimaryColor = Colors.black;
            _secondaryContainer = Colors.white.withValues(alpha: 0.1);
            _onSecondaryContainer = Colors.white;
          }
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [


        
        // Removed duplicate local blurred background.
        // Handled globally by DynamicGlobalBackground.

        // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Main UI Overlay ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
        // Full bleed artwork background
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.width * 1.15,
          child: RepaintBoundary(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _showLyrics ? 0.0 : 1.0,
              child: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black,
                      Colors.black,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.7, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: Selector<HomeController, int>(
                  selector: (c, controller) => controller.programmaticNavCount,
                  builder: (context, navCount, _) => ArtworkWidget(
                    artworkUrl: widget.song.artwork,
                    fallbackUrl: widget.song.fallbackArtwork,
                    songId: widget.song.id,
                    navCount: navCount,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Main UI Overlay
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxHeight < 500;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Lyrics or empty space to push controls down
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AnimatedOpacity(
                              opacity: _showLyrics ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: IgnorePointer(
                                ignoring: _showLyrics,
                                child: const SizedBox.expand(key: ValueKey('artwork')),
                              ),
                            ),
                            AnimatedOpacity(
                              opacity: _showLyrics ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: IgnorePointer(
                                ignoring: !_showLyrics,
                                child: Selector<HomeController, bool>(
                                  selector: (_, c) => c.currentIndex == widget.index,
                                  builder: (context, isActive, _) => GestureDetector(
                                    key: const ValueKey('lyrics'),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      setState(() {
                                        _showLyrics = false;
                                      });
                                    },
                                    child: Container(
                                      color: Colors.transparent,
                                      child: LyricsView(
                                        title: widget.song.title,
                                        artist: widget.song.artist,
                                        durationNotifier: context.read<HomeController>().durationNotifier,
                                        positionNotifier: context.read<HomeController>().positionNotifier,
                                        isCurrent: isActive,
                                        onTap: () {
                                          setState(() {
                                            _showLyrics = false;
                                          });
                                        },
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

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) => SizeTransition(
                        sizeFactor: animation,
                        axisAlignment: -1.0,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: _showLyrics
                          ? const SizedBox.shrink(key: ValueKey('hidden_info'))
                          : Column(
                              key: const ValueKey('info_row'),
                              children: [
                                SizedBox(height: isSmallScreen ? 8 : 24),
                                // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Info Row (Title, Artist, Like) ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.song.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 20, // Reduced from 24
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 2,
                                          ), // Reduced from 4
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children: widget.song.artist
                                                  .split(
                                                    RegExp(r'(?:,\s*|\s+&\s+)'),
                                                  )
                                                  .where(
                                                    (a) => a.trim().isNotEmpty,
                                                  )
                                                  .map(
                                                    (artistName) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 8.0,
                                                          ),
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          final dummyArtist =
                                                              Artist(
                                                                id: artistName
                                                                    .trim(),
                                                                name: artistName
                                                                    .trim(),
                                                                imageUrl: widget
                                                                    .song
                                                                    .artwork,
                                                              );
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (_) =>
                                                                  ArtistScreen(
                                                                    artist:
                                                                        dummyArtist,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                        child: Text(
                                                          artistName.trim(),
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                            color: Colors.white
                                                                .withOpacity(
                                                                  0.7,
                                                                ),
                                                            decoration:
                                                                TextDecoration
                                                                    .underline,
                                                            decorationColor:
                                                                Colors.white
                                                                    .withOpacity(
                                                                      0.3,
                                                                    ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _LikeButton(song: widget.song),
                                    IconButton(
                                      icon: const HugeIcon(
                                        icon: HugeIcons.strokeRoundedMoreVertical,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      onPressed: () {
                                        SongOptionsBottomSheet.show(context, widget.song, showSleepTimer: true);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),

                    SizedBox(
                      height: isSmallScreen ? 2 : 6,
                    ), // Gap between artist name and lyrics
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showLyrics
                          ? Container(
                                height: isSmallScreen ? 24 : 48,
                                alignment: Alignment.center,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.fullscreen_rounded, color: Colors.white70, size: 28),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => LyricsScreen(song: widget.song)));
                                  },
                                ),
                              )
                          : Selector<HomeController, bool>(
                              selector: (_, c) => c.currentIndex == widget.index,
                              builder: (_, isCurrent, __) => SingleLineLyricsView(
                                title: widget.song.title,
                                artist: widget.song.artist,
                                durationNotifier: context.read<HomeController>().durationNotifier,
                                positionNotifier: context.read<HomeController>().positionNotifier,
                                isCurrent: isCurrent,
                                onTap: () {
                                  setState(() { _showLyrics = true; });
                                },
                              ),
                            ),
                    ),

                    // Gap removed to stack lyrics closer to progress bar

                    // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Progress Bar ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
                    Selector<HomeController, ({bool active, PlaybackState state})>(
                        selector: (_, c) => (active: c.currentIndex == widget.index, state: c.playbackState),
                        builder: (context, val, _) {
                          final effectiveState = val.active ? val.state : PlaybackState.idle;
                          return _ProgressBar(
                            positionNotifier: context.read<HomeController>().positionNotifier,
                            isCurrent: val.active,
                            durationNotifier: context.read<HomeController>().durationNotifier,
                            onSeek: context.read<HomeController>().seek,
                            isPaused:
                                effectiveState != PlaybackState.playing &&
                                effectiveState != PlaybackState.loading,
                            activeColor: _primaryColor ?? Colors.white,
                          );
                        },
                      ),

                    SizedBox(height: isSmallScreen ? 2 : 8),

                    // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Playback Controls Row ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Selector<HomeController, ({bool active, PlaybackState state})>(
                              selector: (_, c) => (active: c.currentIndex == widget.index, state: c.playbackState),
                              builder: (context, val, _) {
                                final effectiveState = val.active ? val.state : PlaybackState.idle;
                                final bool isPlaying =
                                    effectiveState == PlaybackState.playing ||
                                    effectiveState == PlaybackState.buffering;

                                return AnimatedPlaybackControls(
                                  isPlaying: isPlaying,
                                  height: isSmallScreen ? 56.0 : 72.0,
                                  playPauseIconSize: isSmallScreen
                                      ? 28.0
                                      : 36.0,
                                  iconSize: isSmallScreen ? 24.0 : 32.0,
                                  colorPlayPause: _primaryColor ?? Colors.white,
                                  tintPlayPauseIcon:
                                      _onPrimaryColor ?? Colors.black,
                                  colorPreviousButton:
                                      _secondaryContainer ??
                                      Colors.white.withValues(alpha: 0.1),
                                  colorNextButton:
                                      _secondaryContainer ??
                                      Colors.white.withValues(alpha: 0.1),
                                  tintPreviousIcon:
                                      _onSecondaryContainer ?? Colors.white,
                                  tintNextIcon:
                                      _onSecondaryContainer ?? Colors.white,
                                  onPrevious: () => context.read<HomeController>().skipToPrev(),
                                  onPlayPause: () =>
                                      context.read<HomeController>().togglePlayPause(),
                                  onNext: () => context.read<HomeController>().skipToNext(),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isSmallScreen ? 8 : 16),

                    // ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Footer Row ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedPlaylist01,
                            size: 24.0,
                            color: Colors.white70,
                            strokeWidth: 1.5,
                          ),
                          onPressed: () {
                            final library = context.read<LibraryManager>();
                            _showAddToPlaylistModal(
                              context,
                              library,
                              widget.song,
                            );
                          },
                        ),
                        Selector<HomeController, bool>(
                          selector: (context, controller) => controller.isShuffled,
                          builder: (context, isShuffled, child) {
                            return IconButton(
                              icon: HugeIcon(
                                icon: HugeIcons.strokeRoundedShuffle,
                                size: 24.0,
                                color: isShuffled
                                    ? Colors.greenAccent
                                    : Colors.white70,
                                strokeWidth: 1.5,
                              ),
                              onPressed: () {
                                context.read<HomeController>().toggleShuffle();
                              },
                            );
                          },
                        ),
                        Selector<HomeController, bool>(
                          selector: (context, controller) => controller.isLoopOne,
                          builder: (context, isLoopOne, child) {
                            return IconButton(
                              icon: HugeIcon(
                                icon: HugeIcons.strokeRoundedArrowReloadHorizontal,
                                size: 24.0,
                                color: isLoopOne
                                    ? Colors.greenAccent
                                    : Colors.white70,
                                strokeWidth: 1.5,
                              ),
                              onPressed: () {
                                context.read<HomeController>().toggleLoop();
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedList,
                            size: 24.0,
                            color: Colors.white70,
                            strokeWidth: 1.5,
                          ),
                          onPressed: () => QueueScreen.show(context),
                        ),
                      ],
                    ),

                    SizedBox(
                      height: isSmallScreen ? 32 : 110,
                    ), // Reduced padding for floating navbar on small screens
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ));
  }

  void _showAddToPlaylistModal(
    BuildContext context,
    LibraryManager library,
    Song song,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add to Playlist',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (library.customPlaylists.isEmpty)
                Text(
                  "You don't have any playlists yet. Go to your Profile to create one!",
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                )
              else
                ...library.customPlaylists.map((playlist) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const HugeIcon(
                      icon: HugeIcons.strokeRoundedPlaylist01,
                      size: 24.0,
                      color: Colors.white70,
                      strokeWidth: 1.5,
                    ),
                    title: Text(
                      playlist.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      library.addSongToPlaylist(playlist.id, song);
                      Navigator.pop(context);
                      AppToast.show(
                        context,
                        'Added to ${playlist.name}',
                        icon: HugeIcons.strokeRoundedPlaylist01,
                      );
                    },
                  );
                }),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Like Button ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
class _LikeButton extends StatelessWidget {
  const _LikeButton({required this.song});
  final Song song;

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryManager>(
      builder: (context, library, _) {
        final isLiked = library.isLiked(song.id);
        return IconButton(
              icon: isLiked
                  ? const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 28,
                    )
                  : const HugeIcon(
                      icon: HugeIcons.strokeRoundedFavourite,
                      color: Colors.white70,
                      size: 28.0,
                      strokeWidth: 1.5,
                    ),
              onPressed: () {
                library.toggleLike(song);
                AppToast.show(
                  context,
                  !isLiked
                      ? 'Added to Liked Songs'
                      : 'Removed from Liked Songs',
                  icon: HugeIcons.strokeRoundedFavourite,
                );
              },
            )
            .animate(key: ValueKey(isLiked))
            .scaleXY(
              begin: 0.5,
              end: 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
            );
      },
    );
  }
}

// ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Progress bar ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.positionNotifier,
    required this.isCurrent,
    required this.durationNotifier,
    required this.onSeek,
    this.isPaused = false,
    this.activeColor = Colors.white,
  });

  final ValueNotifier<Duration> positionNotifier;
  final bool isCurrent;
  final ValueNotifier<Duration?> durationNotifier;
  final ValueChanged<Duration> onSeek;
  final bool isPaused;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration?>(
      valueListenable: durationNotifier,
      builder: (context, duration, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: positionNotifier,
          builder: (context, rawPosition, child) {
            final position = isCurrent ? rawPosition : Duration.zero;
            final total = duration?.inMilliseconds.toDouble() ?? 1.0;
            final current = position.inMilliseconds.toDouble().clamp(
              0.0,
              total,
            );
            final progress = total > 0 ? current / total : 0.0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppleProgressBar(
                  value: progress.clamp(0.0, 1.0),
                  isPaused: isPaused,
                  activeColor: activeColor,
                  onChangeEnd: duration != null
                      ? (v) {
                          final ms = (v * (duration.inMilliseconds)).round();
                          onSeek(Duration(milliseconds: ms));
                        }
                      : null,
                ),
                // Transform to reduce the padding inherently added by the slider widget
                Transform.translate(
                  offset: const Offset(
                    0,
                    -2,
                  ), // Adjusted for AppleProgressBar height
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _format(position),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        duration != null ? _format(duration) : '--:--',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ Bouncing Play Button ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬ÃƒÂ¢Ã¢â‚¬ÂÃ¢â€šÂ¬
class _BouncingPlayButton extends StatefulWidget {
  const _BouncingPlayButton({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_BouncingPlayButton> createState() => _BouncingPlayButtonState();
}

class _BouncingPlayButtonState extends State<_BouncingPlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuad,
        reverseCurve:
            Curves.easeOutBack, // Gives that premium bouncy spring on release
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}






