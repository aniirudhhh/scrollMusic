import 'dart:async';
import '../models/song.dart';
import '../models/playback_state.dart';
import '../core/errors/app_error.dart';
import 'playback_manager.dart';

/// Mock playback manager for Phase 1 development.
/// Simulates state transitions without any native audio engine.
/// Replace with [NativePlaybackManager] once the Android bridge is wired up.
class MockPlaybackManager implements PlaybackManager {
  MockPlaybackManager() {
    _stateController = StreamController<PlaybackState>.broadcast();
    _positionController = StreamController<Duration>.broadcast();
    _endedController = StreamController<void>.broadcast();
  }

  late final StreamController<PlaybackState> _stateController;
  late final StreamController<Duration> _positionController;
  late final StreamController<void> _endedController;

  PlaybackState _state = PlaybackState.idle;
  Timer? _positionTimer;
  Duration _position = Duration.zero;
  Duration? _duration;
  AppError? _lastError;

  // Simulated track duration.
  static const _fakeDuration = Duration(minutes: 3, seconds: 30);

  @override
  PlaybackState get state => _state;

  @override
  Stream<PlaybackState> get stateStream => _stateController.stream;

  @override
  Stream<void> get endedStream => _endedController.stream;

  @override
  Stream<void> get skipNextStream => const Stream.empty();

  @override
  Stream<void> get skipPrevStream => const Stream.empty();

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Duration? get duration => _duration;

  @override
  Stream<Duration?> get durationStream => const Stream.empty();

  @override
  AppError? get lastError => _lastError;

  @override
  Future<void> playSong(Song song, String streamUrl) async {
    _stopPositionTimer();
    _position = Duration.zero;
    _duration = null;
    _setState(PlaybackState.loading);

    // Simulate buffering delay.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    _duration = _fakeDuration;
    _setState(PlaybackState.playing);
    _startPositionTimer();
  }

  @override
  void pause() {
    if (_state != PlaybackState.playing) return;
    _stopPositionTimer();
    _setState(PlaybackState.paused);
  }

  @override
  void resume() {
    if (_state != PlaybackState.paused && _state != PlaybackState.ready) return;
    _setState(PlaybackState.playing);
    _startPositionTimer();
  }

  @override
  Future<void> seek(Duration position) async {
    _position = position;
    _positionController.add(_position);
  }

  @override
  Future<void> stop() async {
    _stopPositionTimer();
    _position = Duration.zero;
    _duration = null;
    _setState(PlaybackState.idle);
  }

  @override
  void setVolume(double volume) {
    // No-op in mock.
  }

  @override
  Future<void> dispose() async {
    _stopPositionTimer();
    await _stateController.close();
    await _positionController.close();
    await _endedController.close();
  }

  void _setState(PlaybackState s) {
    _state = s;
    _stateController.add(s);
  }

  void _startPositionTimer() {
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_state != PlaybackState.playing) return;
      _position += const Duration(milliseconds: 500);
      if (_duration != null && _position >= _duration!) {
        _position = _duration!;
        _stopPositionTimer();
        _setState(PlaybackState.idle);
      } else {
        _positionController.add(_position);
      }
    });
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }
}
