import 'package:flutter/services.dart';
import '../models/search_models.dart';
import '../models/song.dart';
import '../extraction/native_extraction_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

abstract class SearchRepository {
  Future<List<String>> suggestions(String query);
  Future<SearchPage> search(
    String query, {
    SearchFilter? filter,
    String? continuation,
  });
}

class YoutubeSearchRepository implements SearchRepository {
  static const MethodChannel _channel = MethodChannel(
    'com.scrollmusic/extraction',
  );

  @override
  Future<List<String>> suggestions(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final url = Uri.parse(
        'https://suggestqueries-clients6.youtube.com/complete/search?client=firefox&ds=yt&q=${Uri.encodeComponent(query)}',
      );
      final res = await http.get(url);
      final json = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      if (json.length > 1 && json[1] is List) {
        return (json[1] as List).map((e) => e.toString()).toList();
      }
    } catch (e) {
      // Fallback on error
    }
    return [query.toLowerCase(), '$query lyrics', '$query live'];
  }

  @override
  Future<SearchPage> search(
    String query, {
    SearchFilter? filter,
    String? continuation,
  }) async {
    // 1. Pass the filter down to the native channel.
    // If the native side hasn't implemented 'filter' yet, it usually ignores extra map keys.
    final String? filterString = filter?.name;

    final result = await _channel.invokeListMethod<Map<dynamic, dynamic>>(
      'search',
      {'query': query, 'filter': filterString},
    );

    if (result == null) {
      return const SearchPage(items: []);
    }

    // 2. Parse the items into the correct types based on the applied filter
    // or by inspecting a 'type' field from native if it exists.
    final List<SearchItem> items = result.map((item) {
      final id = item['id'] as String? ?? '';
      final title = item['title'] as String? ?? '';
      final artwork =
          item['artwork'] as String? ?? 'https://via.placeholder.com/150';
      final subtitleText = item['artist'] as String? ?? 'Unknown';

      final String itemType =
          item['type'] as String? ?? filterString ?? 'songs';

      switch (itemType) {
        case 'videos':
        case 'video':
          return VideoItem(
            id: id,
            title: title,
            thumbnailUrl: artwork,
            channel: subtitleText,
          );
        case 'artists':
        case 'artist':
          return ArtistItem(
            id: id,
            title: title,
            thumbnailUrl: artwork,
            subscribers: 'Artist',
          );
        case 'albums':
        case 'album':
          return AlbumItem(
            id: id,
            title: title,
            thumbnailUrl: artwork,
            artist: subtitleText,
          );
        case 'featuredPlaylists':
        case 'communityPlaylists':
        case 'playlists':
        case 'playlist':
          return PlaylistItem(
            id: id,
            title: title,
            thumbnailUrl: artwork,
            owner: subtitleText,
          );
        default:
          return SongItem(
            id: id,
            title: title,
            thumbnailUrl: artwork,
            artist: subtitleText,
          );
      }
    }).toList();

    return SearchPage(
      items: items,
      topResult: items.isNotEmpty && filter == null ? items.first : null,
      continuation: null,
    );
  }
}
