import '../models/song.dart';

/// Holds a temporarily cached stream URL for a song.
/// Stream URLs from YouTube expire (typically within 6 hours).
/// Never persist this to disk — only keep in memory during a session.
class CachedStream {
  const CachedStream({
    required this.songId,
    required this.streamUrl,
    required this.fetchedAt,
    this.expiresAt,
  });

  final String songId;
  final String streamUrl;
  final DateTime fetchedAt;

  /// Optional expiry from the extraction result. If null, assume 6-hour TTL.
  final DateTime? expiresAt;

  bool get isExpired {
    final expiry = expiresAt ?? fetchedAt.add(const Duration(hours: 6));
    return DateTime.now().isAfter(expiry);
  }
}

/// Abstract extraction interface.
/// Swap implementations without touching callers.
abstract class ExtractionService {
  /// Fetches a dynamic list of songs based on discovery algorithms.
  Future<List<Song>> fetchDiscoveryFeed();

  /// Searches YouTube Music for a given query.
  Future<List<Song>> search(String query);

  /// Fetches an auto-play 'Up Next' queue of recommended songs based on a videoId.
  Future<List<Song>> fetchRecommendations(String videoId);

  /// Extract a direct audio stream URL for [song].
  /// Returns a [CachedStream] on success, throws on failure.
  Future<CachedStream> extractStream(Song song);

  /// Cancel any in-progress extraction for [songId].
  void cancelExtraction(String songId);

  /// Release all resources.
  void dispose();
}
