import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../extraction/extraction_service.dart';
import '../recommendation/recommendation_engine.dart';

/// Loads and provides the song catalog dynamically.
/// Prevents duplicates and maintains a smooth infinite stream.
class SongRepository {
  SongRepository({
    required this.extractionService,
    required this.recommendationEngine,
    required this.prefs,
  });

  final ExtractionService extractionService;
  final RecommendationEngine recommendationEngine;
  final SharedPreferences prefs;

  List<Song> _songs = [];
  final Set<String> _seenIds = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void loadCache() {
    final cache = prefs.getString('cached_feed');
    if (cache != null && cache.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(cache);
        _songs = decoded.map((e) => Song.fromJson(e as Map<String, dynamic>)).toList();
        for (final s in _songs) {
          _seenIds.add(s.id);
        }
      } catch (e) {
        _songs.clear();
        _seenIds.clear();
      }
    }
  }

  void saveUpcomingCache(int currentIndex) {
    try {
      final startIndex = (currentIndex + 1).clamp(0, _songs.length);
      final upcoming = _songs.sublist(startIndex).take(15).toList();
      // If the user reached the very end, save the last song just so we have something on boot
      if (upcoming.isEmpty && _songs.isNotEmpty) {
        upcoming.add(_songs.last);
      }
      if (upcoming.isNotEmpty) {
        final encoded = jsonEncode(upcoming.map((e) => e.toJson()).toList());
        prefs.setString('cached_feed', encoded);
      }
    } catch (_) {}
  }

  /// Returns the full current song catalog.
  List<Song> getSongs() => _songs;
  
  /// Manually injects a song into the playlist (e.g. from search).
  void insertSong(int index, Song song) {
    _songs.insert(index, song);
    _seenIds.add(song.id);
  }

  void addSongLast(Song song) {
    if (_seenIds.add(song.id)) {
      _songs.add(song);
    }
  }

  /// Replaces all songs after [index] with [newSongs].
  void replaceQueueAfter(int index, List<Song> newSongs) {
    if (index + 1 < _songs.length) {
      final removed = _songs.sublist(index + 1);
      for (final s in removed) {
        _seenIds.remove(s.id);
      }
      _songs.removeRange(index + 1, _songs.length);
    }
    
    for (final s in newSongs) {
      if (_seenIds.add(s.id)) {
        _songs.add(s);
      } else {
        _songs.add(s);
      }
    }
  }

  /// Clears the entire queue and replaces it with [newSongs].
  void replaceEntireQueue(List<Song> newSongs) {
    _songs.clear();
    _seenIds.clear();
    
    for (final s in newSongs) {
      if (_seenIds.add(s.id)) {
        _songs.add(s);
      }
    }
  }

  /// Reorders a song within the queue.
  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _songs.length) return;
    if (newIndex < 0 || newIndex > _songs.length) return;
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final item = _songs.removeAt(oldIndex);
    _songs.insert(newIndex, item);
  }
  
  void removeFromQueue(int index) {
    if (index >= 0 && index < _songs.length) {
      final removed = _songs.removeAt(index);
      _seenIds.remove(removed.id);
    }
  }

  Future<bool> fetchMore({bool isColdBootRefresh = false}) async {
    if (_isLoading) return false;
    _isLoading = true;
    try {
      final newSongs = await recommendationEngine.getRecommendedFeed(limit: 10);
      var addedCount = 0;
      
      if (isColdBootRefresh && newSongs.isNotEmpty && _songs.isNotEmpty) {
        // Keep only the first song (currently playing), replace the rest with fresh feed
        final firstSong = _songs.first;
        _songs.clear();
        _seenIds.clear();
        _songs.add(firstSong);
        _seenIds.add(firstSong.id);
      }

      for (final s in newSongs) {
        if (_seenIds.add(s.id)) {
          _songs.add(s);
          addedCount++;
        }
      }
      return addedCount > 0;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
    }
  }

  Future<bool> fetchMoreRelated(Song song) async {
    if (_isLoading) return false;
    _isLoading = true;
    try {
      final newSongs = await recommendationEngine.getRecommendedFeed(
        limit: 10,
        overrideSeedTrack: song,
      );
      var addedCount = 0;
      for (final s in newSongs) {
        if (_seenIds.add(s.id)) {
          _songs.add(s);
          addedCount++;
        }
      }
      return addedCount > 0;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
    }
  }
}
