/// Immutable data model representing one song in the catalog.
/// Source of truth for all song metadata — UI never builds its own copies.
class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.artwork,
    this.fallbackArtwork,
    required this.source,
  });

  /// YouTube video ID (e.g. "dQw4w9WgXcQ").
  final String id;
  final String title;
  final String artist;

  /// Full URL to artwork image (e.g. YouTube maxresdefault thumbnail 1280x720).
  final String artwork;

  /// Fallback URL (e.g. YouTube hqdefault thumbnail 480x360) if maxres fails.
  final String? fallbackArtwork;

  /// Source type. Currently always "youtube".
  final String source;

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      artwork: json['artwork'] as String,
      fallbackArtwork: json['artworkFallback'] as String?,
      source: (json['source'] as String?) ?? 'youtube',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'artwork': artwork,
        if (fallbackArtwork != null) 'artworkFallback': fallbackArtwork,
        'source': source,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Song && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Song(id: $id, title: $title, artist: $artist)';
}
