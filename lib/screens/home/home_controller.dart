import 'package:flutter/material.dart';
import '../../core/errors/app_error.dart';
import '../../core/utils/debouncer.dart';
import '../../data/song_repository.dart';
import '../../data/library_manager.dart';
import '../../extraction/extraction_service.dart';
import '../../models/playback_state.dart';
import '../../models/song.dart';
import '../../playback/playback_manager.dart';

/// The single source of truth for:
///   - which song is current
///   - the current index in the catalog
///   - playback state
///   - any active error
///
/// The vertical PageView and all playback controls read from this controller.
class HomeController extends ChangeNotifier {
  HomeController({
    required PlaybackManager playbackManager,
    required ExtractionService extractionService,
    required SongRepository repository,
    required LibraryManager libraryManager,
  })  : _player = playbackManager,
        _extractor = extractionService,
        _repo = repository,
        _libraryManager = libraryManager {
    _subscribeToPlayer();
  }

  final PlaybackManager _player;
  final ExtractionService _extractor;
  final SongRepository _repo;
  final LibraryManager _libraryManager;

  // ─── State ────────────────────────────────────────────────────────────────

  List<Song> _songs = [];
  int _currentIndex = 0;
  PlaybackState _playbackState = PlaybackState.idle;
  AppError? _error;
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration?> durationNotifier = ValueNotifier(null);
  bool _initialized = false;
  bool _forceJump = false;
  bool _programmaticNav = false;

  // Cache for extracted audio stream URLs
  final Map<String, CachedStream> _streamCache = {};

  final Debouncer _preloadDebouncer =
      Debouncer(duration: const Duration(milliseconds: 200));

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<Song> get songs => _songs;
  int get currentIndex => _currentIndex;
  Song? get currentSong =>
      _songs.isNotEmpty && _currentIndex < _songs.length ? _songs[_currentIndex] : null;
  PlaybackState get playbackState => _playbackState;
  AppError? get error => _error;
  Duration? get duration => _player.duration;
  bool get isInitialized => _initialized;
  bool get isLoadingMore => _repo.isLoading;
  bool get forceJump => _forceJump;
  bool get programmaticNav => _programmaticNav;

  void consumeForceJump() {
    _forceJump = false;
  }

  void consumeProgrammaticNav() {
    _programmaticNav = false;
  }

  // ─── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    // Initial fetch
    await _repo.fetchMore();
    _songs = _repo.getSongs();
    _initialized = true;
    notifyListeners();

    if (_songs.isNotEmpty) {
      _prefetchAround(_currentIndex);
      // Automatically load a second batch in background so fast swiping never hits a wall
      _checkAndFetchMore();
      // Auto-play the first song on startup to override any lingering background stream
      play();
    }
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  Future<void> onPageChanged(int newIndex) async {
    if (newIndex == _currentIndex) return;

    // Update state synchronously to prevent scroll stutter
    _currentIndex = newIndex;
    _error = null;
    positionNotifier.value = Duration.zero;
    durationNotifier.value = null;
    _playbackState = PlaybackState.idle;
    _programmaticNav = false; // User swipe, don't trigger animateToPage
    notifyListeners();

    await _player.stop();

    // Trigger more songs fetch well in advance (within 6 songs from end)
    _checkAndFetchMore();

    // Preload neighbors
    _preloadDebouncer.call(() => _prefetchAround(newIndex));

    // Always auto-play on swipe
    await play();
  }

  void _checkAndFetchMore() {
    if (_currentIndex >= _songs.length - 6 && !_repo.isLoading) {
      if (_songs.isNotEmpty) {
        final lastSong = _songs.last;
        _repo.fetchMoreRelated(lastSong).then((added) {
          if (added) {
            _songs = _repo.getSongs();
            notifyListeners();
          } else {
            // Fallback if recommendations fail
            _repo.fetchMore().then((fallbackAdded) {
              if (fallbackAdded) {
                _songs = _repo.getSongs();
                notifyListeners();
              }
            });
          }
        });
      } else {
        _repo.fetchMore().then((added) {
          if (added) {
            _songs = _repo.getSongs();
            notifyListeners();
          }
        });
      }
    }
  }

  // ─── Playback commands ────────────────────────────────────────────────────

  Future<void> play() async {
    final song = currentSong;
    if (song == null) return;

    _setPlaybackState(PlaybackState.loading);

    try {
      final stream = await _getStream(song);
      await _player.playSong(song, stream.streamUrl);
      
      // Track history
      _libraryManager.addToHistory(song);
    } on AppError catch (e) {
      await _handleError(e);
    } catch (e) {
      await _handleError(UnknownError(e));
    }
  }

  /// Inserts a song after the current index and plays it IMMEDIATELY.
  Future<void> playSongNext(Song song) async {
    _repo.insertSong(_currentIndex + 1, song);
    _songs = _repo.getSongs();
    _forceJump = true;
    notifyListeners();
    await skipToNext();
    
    // In the background, fetch recommendations for this song to build a seamless radio
    _fetchAndInjectRecommendations(song.id);
  }

  /// Inserts a song after the current index (Top of Queue) without interrupting playback.
  void addToQueueNext(Song song) {
    _repo.insertSong(_currentIndex + 1, song);
    _songs = _repo.getSongs();
    notifyListeners();
    
    // In the background, fetch recommendations for this song to build a seamless radio
    _fetchAndInjectRecommendations(song.id);
  }

  /// Adds a song to the very end of the queue.
  void addToQueueLast(Song song) {
    _repo.addSongLast(song);
    _songs = _repo.getSongs();
    notifyListeners();
  }

  /// Replaces the entire queue with a new list of songs and plays the first one.
  Future<void> playNewQueue(List<Song> newSongs) async {
    if (newSongs.isEmpty) return;
    
    await _player.stop();
    _repo.replaceEntireQueue(newSongs);
    _songs = _repo.getSongs();
    _currentIndex = 0;
    _error = null;
    positionNotifier.value = Duration.zero;
    durationNotifier.value = null;
    _playbackState = PlaybackState.idle;
    _forceJump = true;
    _programmaticNav = true;
    notifyListeners();
    
    _preloadDebouncer.call(() => _prefetchAround(0));
    await play();
  }

  Future<void> _fetchAndInjectRecommendations(String videoId) async {
    try {
      final recommendations = await _extractor.fetchRecommendations(videoId);
      if (recommendations.isNotEmpty) {
        // Replace the upcoming queue with these new recommendations
        _repo.replaceQueueAfter(_currentIndex, recommendations);
        _songs = _repo.getSongs();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Failed to fetch recommendations for radio: $e");
    }
  }

  void reorderQueue(int oldIndex, int newIndex) {
    _repo.reorderQueue(oldIndex, newIndex);
    _songs = _repo.getSongs();
    notifyListeners();
  }

  void removeFromQueue(int index) {
    _repo.removeFromQueue(index);
    _songs = _repo.getSongs();
    
    // If we removed the currently playing song... wait, usually you can't remove the currently playing song from the queue view easily, but if they do, we should handle it.
    // For now, if index <= _currentIndex, we need to adjust _currentIndex.
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      // If they removed the current song, just skip to next
      skipToNext();
    }
    
    notifyListeners();
  }

  void pause() => _player.pause();
  void resume() => _player.resume();

  Future<void> togglePlayPause() async {
    switch (_playbackState) {
      case PlaybackState.playing:
      case PlaybackState.buffering:
        pause();
      case PlaybackState.paused:
      case PlaybackState.ready:
        resume();
      case PlaybackState.idle:
      case PlaybackState.loading:
      case PlaybackState.error:
        await play();
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> retry() async {
    final song = currentSong;
    if (song == null) return;
    _streamCache.remove(song.id);
    _error = null;
    notifyListeners();
    await play();
  }

  Future<void> skipToNext() async {
    if (_currentIndex < _songs.length - 1) {
      final nextIndex = _currentIndex + 1;
      _currentIndex = nextIndex;
      _error = null;
      positionNotifier.value = Duration.zero;
      durationNotifier.value = null;
      _playbackState = PlaybackState.idle;
      _programmaticNav = true;
      notifyListeners();
      
      await _player.stop();
      _preloadDebouncer.call(() => _prefetchAround(nextIndex));
      _checkAndFetchMore();
      await play();
    }
  }

  Future<void> skipToPrev() async {
    if (_currentIndex > 0) {
      final prevIndex = _currentIndex - 1;
      _currentIndex = prevIndex;
      _error = null;
      positionNotifier.value = Duration.zero;
      durationNotifier.value = null;
      _playbackState = PlaybackState.idle;
      _programmaticNav = true;
      notifyListeners();
      
      await _player.stop();
      _preloadDebouncer.call(() => _prefetchAround(prevIndex));
      await play();
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  Future<CachedStream> _getStream(Song song) async {
    final cached = _streamCache[song.id];
    if (cached != null && !cached.isExpired) return cached;

    try {
      final stream = await _extractor.extractStream(song);
      _streamCache[song.id] = stream;
      return stream;
    } catch (e) {
      if (e is AppError) rethrow;
      throw ExtractionError(e.toString());
    }
  }

  /// Preload next 3 songs in the background. Previous is kept in cache.
  void _prefetchAround(int index) {
    for (int i = 1; i <= 3; i++) {
      final nextIndex = index + i;
      if (nextIndex < _songs.length) {
        final nextSong = _songs[nextIndex];

        // Image precaching
        final imageProvider = NetworkImage(nextSong.artwork);
        imageProvider.resolve(const ImageConfiguration());

        // Audio stream pre-extraction
        final cached = _streamCache[nextSong.id];
        if (cached == null || cached.isExpired) {
          _extractor.extractStream(nextSong).then((stream) {
            _streamCache[nextSong.id] = stream;
          }).catchError((_) {
            // Ignored
          });
        }
      }
    }

    _evictDistantCache(index);
  }

  void _evictDistantCache(int currentIndex) {
    final toKeep = {
      if (currentIndex > 0) _songs[currentIndex - 1].id,
      _songs[currentIndex].id,
      if (currentIndex + 1 < _songs.length) _songs[currentIndex + 1].id,
      if (currentIndex + 2 < _songs.length) _songs[currentIndex + 2].id,
      if (currentIndex + 3 < _songs.length) _songs[currentIndex + 3].id,
    };
    _streamCache.removeWhere((id, _) => !toKeep.contains(id));
  }

  Future<void> _handleError(AppError error) async {
    if (error is ExtractionError || error is StreamExpiredError) {
      final song = currentSong;
      if (song != null) {
        _streamCache.remove(song.id);
        try {
          final stream = await _extractor.extractStream(song);
          _streamCache[song.id] = stream;
          await _player.playSong(song, stream.streamUrl);
          return;
        } catch (_) {}
      }
    }

    print('ERROR IN PLAYBACK: $error');
    _error = error;
    _setPlaybackState(PlaybackState.error);
  }

  void _subscribeToPlayer() {
    _player.stateStream.listen((state) {
      print('PLAYBACK STATE CHANGED: $state');
      _playbackState = state;
      if (state != PlaybackState.error) _error = null;
      if (state == PlaybackState.error) {
         print('EXOPLAYER NATIVE ERROR: ${_player.lastError}');
         _error = _player.lastError;
      }
      notifyListeners();
    });

    _player.positionStream.listen((pos) {
      positionNotifier.value = pos;
    });

    _player.durationStream.listen((dur) {
      durationNotifier.value = dur;
    });

    _player.endedStream.listen((_) {
      skipToNext();
    });

    _player.skipNextStream.listen((_) {
      skipToNext();
    });

    _player.skipPrevStream.listen((_) {
      skipToPrev();
    });
  }

  void _setPlaybackState(PlaybackState state) {
    _playbackState = state;
    notifyListeners();
  }

  @override
  void dispose() {
    positionNotifier.dispose();
    _preloadDebouncer.dispose();
    _player.dispose();
    _extractor.dispose();
    super.dispose();
  }
}
