/// Explicit playback states. The UI reacts to each state distinctly.
/// There is one authoritative [PlaybackState] in [HomeController] —
/// the UI never derives its own state from multiple sources.
enum PlaybackState {
  /// Player is ready but no song loaded yet.
  idle,

  /// Song selected, extraction/buffering starting.
  loading,

  /// Stream URL acquired, player prepared, ready to play.
  ready,

  /// Audio is actively playing.
  playing,

  /// Playback intentionally paused by user.
  paused,

  /// Playback stalled waiting for data (network buffering).
  buffering,

  /// Unrecoverable error on this song. UI shows retry/skip.
  error,
}

extension PlaybackStateX on PlaybackState {
  bool get isActive => this == PlaybackState.playing || this == PlaybackState.buffering;
  bool get isLoadingOrBuffering =>
      this == PlaybackState.loading || this == PlaybackState.buffering;
  bool get showPlayButton =>
      this == PlaybackState.paused || this == PlaybackState.ready || this == PlaybackState.idle;
}
