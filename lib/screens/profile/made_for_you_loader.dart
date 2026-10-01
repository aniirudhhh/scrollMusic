import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../../recommendation/profile/user_profile_manager.dart';
import '../../extraction/extraction_service.dart';
import '../../models/song.dart';
import '../../data/library_manager.dart';
import 'profile_screen.dart';

class MadeForYouLoader extends StatefulWidget {
  const MadeForYouLoader({super.key});

  @override
  State<MadeForYouLoader> createState() => _MadeForYouLoaderState();
}

class _MadeForYouLoaderState extends State<MadeForYouLoader> {
  static List<Song>? _cachedPlaylist;
  static DateTime? _lastGenerated;

  String _statusMessage = 'Reading your mind... 🔮';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _generatePlaylist();
    });
  }

  Future<void> _generatePlaylist() async {
    // If we have a cached playlist that is less than 6 hours old, use it instantly
    if (_cachedPlaylist != null && _lastGenerated != null) {
      if (DateTime.now().difference(_lastGenerated!).inHours < 6) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PlaylistDetailScreen(
              title: 'Made for You',
              songs: _cachedPlaylist!,
            ),
          ),
        );
        return;
      }
    }

    try {
      final profile = context.read<UserProfileManager>();
      final extraction = context.read<ExtractionService>();
      final library = context.read<LibraryManager>();

      final topArtists = profile.getTopArtists(4);
      final recentSongs = library.recentlyPlayed.take(2).toList();
      
      setState(() {
        _statusMessage = 'Mixing a little bit of magic with your recent favorites... ✨';
      });

      List<Song> curatedSongs = [];
      
      if (topArtists.isEmpty && recentSongs.isEmpty) {
        // Fallback: If brand new user, fetch discovery feed
        setState(() {
          _statusMessage = 'Finding some new bops you\'ll absolutely fall in love with... 💖';
        });
        curatedSongs = await extraction.fetchDiscoveryFeed();
      } else {
        // Fetch recommendations for each top artist
        for (final artist in topArtists) {
          final results = await extraction.search(artist);
          for (final song in results.take(4)) {
             if (!curatedSongs.any((s) => s.id == song.id)) {
               curatedSongs.add(song);
             }
          }
        }
        
        // Fetch "Related Tracks" for the absolute most recently played songs
        for (final song in recentSongs) {
          try {
            final related = await extraction.fetchRecommendations(song.id);
            for (final rSong in related.take(5)) {
               if (!curatedSongs.any((s) => s.id == rSong.id)) {
                 curatedSongs.add(rSong);
               }
            }
          } catch (e) {
             debugPrint('Could not fetch related for ${song.title}: $e');
          }
        }
        
        // Shuffle the curated playlist for variety
        curatedSongs.shuffle(Random());
      }
      
      _cachedPlaylist = curatedSongs;
      _lastGenerated = DateTime.now();

      if (!mounted) return;

      // Replace loader with the actual playlist screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistDetailScreen(
            title: 'Made for You',
            songs: curatedSongs,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error curating playlist: $e')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFFF2D55)),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
