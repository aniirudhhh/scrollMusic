import 'package:flutter/services.dart';
import '../core/errors/app_error.dart';
import '../models/song.dart';
import 'extraction_service.dart';

/// Real extraction implementation backed by NewPipeExtractor via MethodChannel.
/// Replaces [MockExtractionService] in Phase 2.
class NativeExtractionService implements ExtractionService {
  static const MethodChannel _channel = MethodChannel('com.scrollmusic/extraction');

  // Generation counter per song — lets us discard stale results from fast swipes.
  final Map<String, int> _generations = {};

  @override
  Future<List<Song>> fetchDiscoveryFeed() async {
    try {
      final result = await _channel.invokeListMethod<Map<dynamic, dynamic>>('fetchDiscoveryFeed');
      if (result == null) return [];

      return result.map((item) {
        return Song(
          id: item['id'] as String,
          title: item['title'] as String,
          artist: item['artist'] as String,
          artwork: item['artwork'] as String,
          fallbackArtwork: item['artworkFallback'] as String?,
          source: 'youtube', // we use youtube for NewPipe
        );
      }).toList();
    } on PlatformException catch (e) {
      throw ExtractionError('Failed to fetch discovery feed: ${e.message}');
    }
  }

  @override
  Future<List<Song>> search(String query) async {
    try {
      final result = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
        'search',
        {'query': query},
      );
      if (result == null) return [];

      return result.map((item) {
        return Song(
          id: item['id'] as String,
          title: item['title'] as String,
          artist: item['artist'] as String,
          artwork: item['artwork'] as String,
          fallbackArtwork: item['artworkFallback'] as String?,
          source: 'youtube',
        );
      }).toList();
    } on PlatformException catch (e) {
      throw ExtractionError('Failed to search: ${e.message}');
    }
  }

  @override
  Future<List<Song>> fetchRecommendations(String videoId) async {
    try {
      final result = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
        'fetchRecommendations',
        {'videoId': videoId},
      );
      if (result == null) return [];

      return result.map((item) {
        return Song(
          id: item['id'] as String,
          title: item['title'] as String,
          artist: item['artist'] as String,
          artwork: item['artwork'] as String,
          fallbackArtwork: item['artworkFallback'] as String?,
          source: 'youtube',
        );
      }).toList();
    } on PlatformException catch (e) {
      throw ExtractionError('Failed to fetch recommendations: ${e.message}');
    }
  }

  Future<String> getStreamUrl(String videoId) async {
    try {
      final String? url = await _channel.invokeMethod('getStreamUrl', {'videoId': videoId});
      return url ?? '';
    } on PlatformException catch (e) {
      throw ExtractionError('Failed to get stream URL: ${e.message}');
    }
  }

  @override
  Future<CachedStream> extractStream(Song song) async {
    final generation = (_generations[song.id] ?? 0) + 1;
    _generations[song.id] = generation;

    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'extractStream',
        {'videoId': song.id},
      );

      if (result == null) throw const ExtractionError('Empty response from native');

      // Discard if a newer extraction was started for this song while we waited.
      if (_generations[song.id] != generation) {
        throw const ExtractionError('Extraction superseded by newer request');
      }

      final streamUrl = result['url'] as String?;
      if (streamUrl == null || streamUrl.isEmpty) {
        throw const ExtractionError('Stream URL is empty');
      }

      final fetchedAtMs = result['fetchedAtMs'] as int?;

      return CachedStream(
        songId: song.id,
        streamUrl: streamUrl,
        fetchedAt: fetchedAtMs != null
            ? DateTime.fromMillisecondsSinceEpoch(fetchedAtMs)
            : DateTime.now(),
        // Conservative expiry: 5.5 hours (YouTube URLs last ~6h)
        expiresAt: DateTime.now().add(const Duration(hours: 5, minutes: 30)),
      );
    } on PlatformException catch (e) {
      throw ExtractionError(e.message ?? 'Extraction failed (${e.code})');
    }
  }

  @override
  void cancelExtraction(String songId) {
    // Bump generation so any in-flight result is discarded on return.
    _generations[songId] = (_generations[songId] ?? 0) + 1;
  }

  @override
  void dispose() {
    _generations.clear();
  }
}
