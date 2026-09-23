import 'dart:async';
import 'package:flutter/services.dart';
import '../core/errors/app_error.dart';
import '../models/song.dart';
import '../models/playback_state.dart';
import 'playback_manager.dart';

/// Real playback manager backed by Media3/ExoPlayer via MethodChannel + EventChannel.
/// Replaces [MockPlaybackManager] in Phase 2.
class NativePlaybackManager implements PlaybackManager {
  static const _playbackChannel = MethodChannel('com.scrollmusic/playback');
  static const _eventChannel = EventChannel('com.scrollmusic/playback_events');

  NativePlaybackManager() {
    _subscribeToEvents();
  }

  final StreamController<PlaybackState> _stateController =
      StreamController<PlaybackState>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<void> _endedController =
      StreamController<void>.broadcast();
  final StreamController<void> _skipNextController =
      StreamController<void>.broadcast();
  final StreamController<void> _skipPrevController =
      StreamController<void>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();

  PlaybackState _state = PlaybackState.idle;
  Duration? _duration;
  AppError? _lastError;
  StreamSubscription<dynamic>? _eventSubscription;

  // ─── PlaybackManager interface ────────────────────────────────────────────

  @override
  PlaybackState get state => _state;

  @override
  Stream<PlaybackState> get stateStream => _stateController.stream;

  @override
  Stream<void> get endedStream => _endedController.stream;

  @override
  Stream<void> get skipNextStream => _skipNextController.stream;

  @override
  Stream<void> get skipPrevStream => _skipPrevController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Duration? get duration => _duration;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  AppError? get lastError => _lastError;

  @override
  Future<void> playSong(Song song, String streamUrl) async {
    _setState(PlaybackState.loading);
    try {
      await _playbackChannel.invokeMethod('playSong', {
        'url': streamUrl,
        'title': song.title,
        'artist': song.artist,
        'artwork': song.artwork,
      });
    } on PlatformException catch (e) {
      _lastError = PlaybackError(e.message ?? e.code);
      _setState(PlaybackState.error);
    }
  }

  @override
  void pause() {
    _playbackChannel.invokeMethod<void>('pause');
  }

  @override
  void resume() {
    _playbackChannel.invokeMethod<void>('resume');
  }

  @override
  Future<void> seek(Duration position) async {
    await _playbackChannel.invokeMethod('seek', {
      'positionMs': position.inMilliseconds,
    });
  }

  @override
  Future<void> stop() async {
    await _playbackChannel.invokeMethod<void>('stop');
    _duration = null;
    _durationController.add(null);
    _setState(PlaybackState.idle);
  }

  @override
  void setVolume(double volume) {
    _playbackChannel.invokeMethod<void>('setVolume', {'volume': volume});
  }

  @override
  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    await _stateController.close();
    await _positionController.close();
    await _endedController.close();
    await _skipNextController.close();
    await _skipPrevController.close();
    await _durationController.close();
  }

  // ─── Native event handling ────────────────────────────────────────────────

  void _subscribeToEvents() {
    _eventSubscription = _eventChannel
        .receiveBroadcastStream()
        .listen(_handleEvent, onError: _handleStreamError);
  }

  void _handleEvent(dynamic rawEvent) {
    if (rawEvent is! Map) return;
    final event = Map<String, dynamic>.from(rawEvent);
    final type = event['type'] as String?;

    switch (type) {
      case 'stateChange':
        final stateStr = event['state'] as String?;
        final newState = _parseState(stateStr);
        if (newState == PlaybackState.error) {
          _lastError = PlaybackError(event['message'] as String? ?? 'Unknown');
        } else {
          _lastError = null;
        }
        _setState(newState);

      case 'position':
        final posMs = event['positionMs'] as int?;
        final durMs = event['durationMs'] as int?;
        if (posMs != null) {
          _positionController.add(Duration(milliseconds: posMs));
        }
        if (durMs != null && durMs > 0) {
          final newDur = Duration(milliseconds: durMs);
          if (_duration != newDur) {
            _duration = newDur;
            _durationController.add(newDur);
          }
        }

      case 'ended':
        _endedController.add(null);

      case 'skipNext':
        _skipNextController.add(null);

      case 'skipPrev':
        _skipPrevController.add(null);

      case 'error':
        final message = event['message'] as String? ?? 'Playback error';
        _lastError = PlaybackError(message);
        _setState(PlaybackState.error);
    }
  }

  void _handleStreamError(dynamic error) {
    _lastError = PlaybackError(error.toString());
    _setState(PlaybackState.error);
  }

  PlaybackState _parseState(String? raw) => switch (raw) {
        'idle' => PlaybackState.idle,
        'loading' => PlaybackState.loading,
        'ready' => PlaybackState.ready,
        'playing' => PlaybackState.playing,
        'paused' => PlaybackState.paused,
        'buffering' => PlaybackState.buffering,
        'error' => PlaybackState.error,
        _ => PlaybackState.idle,
      };

  void _setState(PlaybackState s) {
    _state = s;
    _stateController.add(s);
  }
}
