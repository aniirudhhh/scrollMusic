import '../models/song.dart';
import '../extraction/extraction_service.dart';
import '../recommendation/recommendation_engine.dart';

/// Loads and provides the song catalog dynamically.
/// Prevents duplicates and maintains a smooth infinite stream.
class SongRepository {
  SongRepository({
    required this.extractionService,
    required this.recommendationEngine,
  });

  final ExtractionService extractionService;
  final RecommendationEngine recommendationEngine;

  final List<Song> _songs = [];
  final Set<String> _seenIds = {};
  bool _isLoading = false;

  /// Returns the full current song catalog.
  List<Song> getSongs() => _songs;
  
  /// Manually injects a song into the playlist (e.g. from search).
  void insertSong(int index, Song song) {
    _songs.insert(index, song);
    _seenIds.add(song.id);
  }

  /// Replaces all songs after [index] with [newSongs].
  void replaceQueueAfter(int index, List<Song> newSongs) {
    // Remove all songs after index
    if (index + 1 < _songs.length) {
      final removed = _songs.sublist(index + 1);
      for (final s in removed) {
        _seenIds.remove(s.id); // allow them to be re-added later if they show up in another feed
      }
      _songs.removeRange(index + 1, _songs.length);
    }
    
    // Add new ones
    for (final s in newSongs) {
      if (_seenIds.add(s.id)) {
        _songs.add(s);
      } else {
        _songs.add(s); // duplicates allowed in playlist flow, but seenIds tracks it?
        // Wait, if we allow duplicates, seenIds is just for the discovery feed to prevent dupes.
        // Actually, let's just add it and not worry about _seenIds rejecting it.
        // If it's a dupe, that's fine for up next.
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

  /// Removes a song from the queue.
  void removeFromQueue(int index) {
    if (index < 0 || index >= _songs.length) return;
    final item = _songs.removeAt(index);
    // Don't remove from _seenIds, otherwise it could be re-added later, which is fine, 
    // but the user explicitly removed it. Let's just leave it in seenIds.
  }

  /// Adds a song to the very end of the queue.
  void addSongLast(Song song) {
    _songs.add(song);
    // Don't worry about seenIds here for manual queuing
  }

  bool get isLoading => _isLoading;

  /// Appends more songs by fetching a new discovery feed.
  Future<bool> fetchMore() async {
    if (_isLoading) return false;
    _isLoading = true;
    try {
      final newSongs = await recommendationEngine.getRecommendedFeed(limit: 10);
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

  /// Appends more songs by fetching recommendations (related songs) to [song].
  Future<bool> fetchMoreRelated(Song song) async {
    if (_isLoading) return false;
    _isLoading = true;
    try {
      // In a recommendation engine world, related fetches are still useful, 
      // but let's route them through the engine as well if we want diversification,
      // or just keep native related for immediate "Up Next" cohesion.
      // We will stick to the engine for now so scoring applies.
      final newSongs = await recommendationEngine.getRecommendedFeed(limit: 10);
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

  /// Returns the song at [index], or null if out of range.
  Song? songAt(int index) {
    if (index < 0 || index >= _songs.length) return null;
    return _songs[index];
  }

  int get length => _songs.length;
}
