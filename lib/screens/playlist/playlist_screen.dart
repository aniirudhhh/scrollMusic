import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/song.dart';
import '../../screens/home/home_controller.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/song_options_sheet.dart';

class PlaylistScreen extends StatefulWidget {
  final String playlistId;
  final String title;
  final String imageUrl;
  final String owner;

  const PlaylistScreen({
    super.key,
    required this.playlistId,
    required this.title,
    required this.imageUrl,
    required this.owner,
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isScrolled = false;
  List<Song> _songs = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchPlaylist();
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 50 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  Future<void> _fetchPlaylist() async {
    try {
      String safeId = widget.playlistId;
      if (!safeId.startsWith('VL')) {
        safeId = 'VL' + safeId;
      }

      final url = Uri.parse(
        'https://music.youtube.com/youtubei/v1/browse?prettyPrint=false',
      );
      final body = jsonEncode({
        'context': {
          'client': {
            'clientName': 'WEB_REMIX',
            'clientVersion': '1.20230522.01.00',
          },
        },
        'browseId': safeId,
      });

      final res = await http.post(
        url,
        body: body,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      final json = jsonDecode(utf8.decode(res.bodyBytes));

      final contents = json['contents'];
      if (contents == null) throw Exception('No contents found');

      final renderer = contents['twoColumnBrowseResultsRenderer'];
      if (renderer == null) throw Exception('No twoColumn renderer');

      final secondaryContents = renderer['secondaryContents'];
      final sectionList = secondaryContents['sectionListRenderer'];
      final items = sectionList['contents'] as List;
      final playlistRenderer = items[0]['musicPlaylistShelfRenderer'];
      final songsJson = playlistRenderer['contents'] as List;

      final List<Song> mappedSongs = [];
      for (var item in songsJson) {
        final rItem = item['musicResponsiveListItemRenderer'];
        if (rItem == null) continue;

        final videoId = rItem['playlistItemData']?['videoId'];
        if (videoId == null) continue;

        final flexCols = rItem['flexColumns'] as List;
        if (flexCols.isEmpty) continue;

        final titleRuns =
            flexCols[0]['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'];
        final title = titleRuns != null && titleRuns.isNotEmpty
            ? titleRuns[0]['text']
            : 'Unknown Title';

        String artist = 'Unknown Artist';
        if (flexCols.length > 1) {
          final artistRuns =
              flexCols[1]['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']
                  as List?;
          if (artistRuns != null && artistRuns.isNotEmpty) {
            artist = artistRuns.map((r) => r['text']).join('');
          }
        }

        final thumbnails =
            rItem['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']
                as List?;
        String artwork = thumbnails != null && thumbnails.isNotEmpty
            ? thumbnails.last['url']
            : '';
        if (artwork.startsWith('//')) artwork = 'https:' + artwork;
        // Upscale YouTube Music thumbnail
        artwork = artwork.replaceAll(RegExp(r'=w\d+-h\d+.*'), '=w1000-h1000');

        mappedSongs.add(
          Song(
            id: videoId,
            title: title,
            artist: artist,
            artwork: artwork,
            source: 'youtube',
          ),
        );
      }

      if (mounted) {
        setState(() {
          _songs = mappedSongs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load playlist: ' + e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _playAll() {
    if (_songs.isEmpty) return;
    context.read<HomeController>().playNewQueue(_songs);
  }

  void _shufflePlay() {
    if (_songs.isEmpty) return;
    final shuffled = List<Song>.from(_songs)..shuffle();
    context.read<HomeController>().playNewQueue(shuffled);
  }

  void _playSongAndQueue(int index) {
    if (_songs.isEmpty) return;
    // Creates a queue starting from the tapped song, then loops back
    final newQueue = [..._songs.sublist(index), ..._songs.sublist(0, index)];
    context.read<HomeController>().playNewQueue(newQueue);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = context.watch<HomeController>().currentSong != null
        ? MediaQuery.of(context).padding.bottom + 24.0 + 80.0
        : MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: Stack(
        children: [
          // Background Gradient Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: Colors.white10),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black54, Color(0xFF0F0F13)],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),

          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: _isScrolled
                    ? const Color(0xFF1B1B1F)
                    : Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: _isScrolled
                    ? Text(
                        widget.title,
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildActionButton(
                            Icons.play_arrow,
                            'Play',
                            _playAll,
                            isPrimary: true,
                          ),
                          const SizedBox(width: 16),
                          _buildActionButton(
                            Icons.shuffle,
                            'Shuffle',
                            _shufflePlay,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Tracks List
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final song = _songs[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: CachedNetworkImage(
                          imageUrl: song.artwork,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.white10,
                            width: 48,
                            height: 48,
                          ),
                        ),
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          SongOptionsBottomSheet.show(context, song);
                        },
                      ),
                      onTap: () => _playSongAndQueue(index),
                    );
                  }, childCount: _songs.length),
                ),

              SliverToBoxAdapter(child: SizedBox(height: bottomPadding + 32)),
            ],
          ),

          // Mini Player alignment
          if (context.watch<HomeController>().currentSong != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 24.0,
              child: const MiniPlayer(),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: isPrimary ? Colors.black : Colors.white),
      label: Text(
        label,
        style: TextStyle(
          color: isPrimary ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? Colors.white : Colors.white10,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
      ),
    );
  }
}
