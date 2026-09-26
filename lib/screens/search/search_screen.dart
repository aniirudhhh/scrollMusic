import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/debouncer.dart';
import '../../extraction/extraction_service.dart';
import '../../models/song.dart';
import '../home/home_controller.dart';
import '../main_screen.dart';
import '../../widgets/liquid_glass_surface.dart';
import '../../widgets/song_options_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class BrowseCategory {
  final String title;
  final String query;
  final List<Color> gradient;
  
  const BrowseCategory(this.title, this.query, this.gradient);
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(duration: const Duration(milliseconds: 500));
  
  List<Song> _results = [];
  bool _isLoading = false;
  String _error = '';
  
  List<String> _recentSearches = [];
  static const String _prefsKey = 'recent_searches';
  
  final List<BrowseCategory> _browseCategories = [
    BrowseCategory('Bollywood Hits', 'Latest Bollywood Hits', const [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
    BrowseCategory('Viral 50', 'Viral 50 Global', const [Color(0xFFFF416C), Color(0xFFFF4B2B)]),
    BrowseCategory('Lofi Beats', 'Lofi Chill Beats', const [Color(0xFF141E30), Color(0xFF243B55)]),
    BrowseCategory('Punjabi Top', 'Trending Punjabi', const [Color(0xFFDA4453), Color(0xFF89216B)]),
    BrowseCategory('Pop Anthems', 'Top Pop Hits', const [Color(0xFF00B4DB), Color(0xFF0083B0)]),
    BrowseCategory('Devotional', 'Best Devotional Songs', const [Color(0xFFF5515F), Color(0xFFA1051D)]),
    BrowseCategory('Workout', 'Workout Motivation Music', const [Color(0xFF0F2027), Color(0xFF203A43)]),
    BrowseCategory('Chill Vibes', 'Chill Acoustic Vibe', const [Color(0xFF1D976C), Color(0xFF2F80ED)]),
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList(_prefsKey) ?? [];
    });
  }
  
  Future<void> _addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    
    _recentSearches.remove(trimmed);
    _recentSearches.insert(0, trimmed);
    
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _recentSearches);
    
    if (mounted) setState(() {});
  }
  
  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    setState(() {
      _recentSearches.clear();
    });
  }
  
  void _onChipTapped(String query) {
    _searchController.text = query;
    _onSearchChanged(query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = '';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    _debouncer.call(() => _performSearch(query.trim()));
  }

  Future<void> _performSearch(String query) async {
    try {
      final extractor = context.read<ExtractionService>();
      final results = await extractor.search(query);
      
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to search: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _playSong(Song song) {
    if (_searchController.text.trim().isNotEmpty) {
      _addRecentSearch(_searchController.text.trim());
    }
    
    // Hide keyboard to prevent it from squashing the full screen player (SongPage)
    FocusScope.of(context).unfocus();
    
    // Add to the front of the queue and play
    context.read<HomeController>().playSongNext(song);
    
    // Switch to Home tab
    mainScreenKey.currentState?.switchToTab(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ──────────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.only(left: 20.0, top: 16.0, bottom: 12.0),
              child: Text(
                'Search',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // ─── Modern Search Bar ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: LiquidGlassSurface(
                blurBehind: false,
                tintColor: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                shadowElevation: 0, // Flat look like Apple Music
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  onSubmitted: (query) {
                    if (query.trim().isNotEmpty) {
                      _addRecentSearch(query);
                    }
                  },
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Songs, Artists, Albums...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 12),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 20.0,
                        strokeWidth: 2.0,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedCancel01,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: 20.0,
                              strokeWidth: 2.0,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // ─── Results Area ────────────────────────────────────────────────
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_searchController.text.trim().isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
        children: [
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Searches',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: _clearRecentSearches,
                  child: Text(
                    'Clear',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _recentSearches.map((query) {
                return Material(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: () => _onChipTapped(query),
                    borderRadius: BorderRadius.circular(24),
                    splashColor: Colors.white.withValues(alpha: 0.1),
                    highlightColor: Colors.white.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedClock01,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            query,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
          
          // Removed Browse Categories
        ],
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final song = _results[index];
        return Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _playSong(song),
                onLongPress: () => SongOptionsBottomSheet.show(context, song),
                splashColor: Colors.white.withValues(alpha: 0.1),
                highlightColor: Colors.white.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      // Square Artwork
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6), // Subtle Apple-style border radius
                        child: CachedNetworkImage(
                          imageUrl: song.artwork,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.white.withValues(alpha: 0.1),
                            child: const Icon(Icons.music_note, color: Colors.white54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w400, // Apple uses regular weight for titles
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Song • ${song.artist}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Removed 3-dot menu, replaced with long press on InkWell
                    ],
                  ),
                ),
              ),
            ),
            // Subtle Divider, inset to align with text
            Padding(
              padding: const EdgeInsets.only(left: 64.0),
              child: Divider(
                height: 1,
                thickness: 0.5,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ],
        );
      },
    );
  }
}
