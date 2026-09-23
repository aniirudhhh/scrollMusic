import '../models/song.dart';
import 'extraction_service.dart';

/// Mock extraction service used in Phase 1 (before native Android bridge is ready).
/// Returns a public domain audio stream URL so the player has something to play.
/// Replace this with [NativeExtractionService] in Phase 2.
class MockExtractionService implements ExtractionService {
  // A short, freely-licensed audio clip (Wikimedia Commons).
  static const _testStreamUrl =
      'https://upload.wikimedia.org/wikipedia/commons/transcoded/6/6e/'
      'Grieg_-_In_the_Hall_of_the_Mountain_King.ogg/'
      'Grieg_-_In_the_Hall_of_the_Mountain_King.ogg.mp3';

  @override
  Future<List<Song>> fetchDiscoveryFeed() async {
    return [];
  }

  @override
  Future<List<Song>> search(String query) async {
    return [];
  }

  @override
  Future<List<Song>> fetchRecommendations(String videoId) async {
    return [];
  }

  @override
  Future<CachedStream> extractStream(Song song) async {
    // Simulate extraction latency.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return CachedStream(
      songId: song.id,
      streamUrl: _testStreamUrl,
      fetchedAt: DateTime.now(),
    );
  }

  @override
  void cancelExtraction(String songId) {
    // No-op for mock.
  }

  @override
  void dispose() {
    // No-op for mock.
  }
}
