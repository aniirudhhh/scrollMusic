import '../models/song.dart';
import '../models/playback_state.dart';
import '../core/errors/app_error.dart';

/// Abstract playback manager interface.
/// The UI only interacts with this — never with ExoPlayer/Media3 directly.
/// Implementations: [MockPlaybackManager] (Phase 1), [NativePlaybackManager] (Phase 2+).
abstract class PlaybackManager {
  /// The current playback state. Listen to [stateStream] for updates.
  PlaybackState get state;

  /// Stream of playback state changes. Use to update UI.
  Stream<PlaybackState> get stateStream;

  /// Fires once when the current track ends naturally (not stopped by user).
  Stream<void> get endedStream;

  /// Fires when the user taps Next in the media notification.
  Stream<void> get skipNextStream;

  /// Fires when the user taps Previous in the media notification.
  Stream<void> get skipPrevStream;

  /// Current playback position. Emits periodically while playing.
  Stream<Duration> get positionStream;

  /// Total duration of the currently loaded media.
  Duration? get duration;

  /// Stream of duration updates (useful for streams where duration loads asynchronously).
  Stream<Duration?> get durationStream;

  /// Load and begin playing [song] from [streamUrl].
  /// Transitions: idle/paused/playing → loading → playing
  Future<void> playSong(Song song, String streamUrl);

  /// Pause current playback.
  void pause();

  /// Resume paused playback.
  void resume();

  /// Seek to [position].
  Future<void> seek(Duration position);

  /// Stop playback and release current media item, returning to idle.
  Future<void> stop();

  /// Set volume (0.0 to 1.0).
  void setVolume(double volume);

  /// Release all native resources. Call when the app is closing.
  Future<void> dispose();

  /// The last error if state is [PlaybackState.error].
  AppError? get lastError;
}
