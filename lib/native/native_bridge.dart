import 'package:flutter/services.dart';

/// Stub for the Flutter ↔ Kotlin MethodChannel bridge.
/// Phase 1: All methods are no-ops or return mock data.
/// Phase 2: Replace with real channel calls to [ScrollMusicPlugin.kt].
///
/// Channel names must match exactly what the Kotlin side registers.
class NativeBridge {
  NativeBridge._();
  static final NativeBridge instance = NativeBridge._();

  // ignore: unused_field — channels are stubs in Phase 1; wired in Phase 2.
  static const _extractionChannel =
      MethodChannel('com.scrollmusic/extraction');
  // ignore: unused_field
  static const _playbackChannel =
      MethodChannel('com.scrollmusic/playback');
  // ignore: unused_field
  static const _playbackEventChannel =
      EventChannel('com.scrollmusic/playback_events');

  /// Extract the best audio stream URL for [videoId] via NewPipe.
  /// Returns a map with keys: 'url', 'expiry' (optional epoch millis).
  /// Throws [PlatformException] on failure.
  Future<Map<String, dynamic>> extractStream(String videoId) async {
    // Phase 1: Not yet wired — throw so callers fall back to mock.
    throw UnimplementedError(
      'NativeBridge.extractStream: native channel not yet connected. '
      'This will be wired in Phase 2 (Media3 + NewPipe integration).',
    );
    // Phase 2 implementation:
    // final result = await _extractionChannel.invokeMapMethod<String, dynamic>(
    //   'extractStream',
    //   {'videoId': videoId},
    // );
    // return result!;
  }

  /// Instruct the native player to load [streamUrl] and play.
  Future<void> playSong(String streamUrl) async {
    // Phase 2:
    // await _playbackChannel.invokeMethod('playSong', {'url': streamUrl});
  }

  Future<void> pause() async {
    // await _playbackChannel.invokeMethod('pause');
  }

  Future<void> resume() async {
    // await _playbackChannel.invokeMethod('resume');
  }

  Future<void> stop() async {
    // await _playbackChannel.invokeMethod('stop');
  }

  Future<void> seek(int positionMs) async {
    // await _playbackChannel.invokeMethod('seek', {'positionMs': positionMs});
  }

  /// Stream of playback events from the native side.
  /// Events are maps: { 'type': 'stateChange'|'position', ... }
  Stream<Map<Object?, Object?>> get playbackEvents {
    // Phase 2: return _playbackEventChannel.receiveBroadcastStream();
    return const Stream.empty();
  }
}
