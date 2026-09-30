import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class YTMusicSyncService {
  static const String _baseUrl = 'https://music.youtube.com/youtubei/v1';
  
  static const _storage = FlutterSecureStorage();

  static Future<void> _migrateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('yt_auth_cookie')) {
      final cookie = prefs.getString('yt_auth_cookie');
      if (cookie != null) await _storage.write(key: 'yt_auth_cookie', value: cookie);
      await prefs.remove('yt_auth_cookie');
    }
    if (prefs.containsKey('yt_profile_name')) {
      final name = prefs.getString('yt_profile_name');
      if (name != null) await _storage.write(key: 'yt_profile_name', value: name);
      await prefs.remove('yt_profile_name');
    }
    if (prefs.containsKey('yt_profile_email')) {
      final email = prefs.getString('yt_profile_email');
      if (email != null) await _storage.write(key: 'yt_profile_email', value: email);
      await prefs.remove('yt_profile_email');
    }
    if (prefs.containsKey('yt_profile_avatar')) {
      final avatar = prefs.getString('yt_profile_avatar');
      if (avatar != null) await _storage.write(key: 'yt_profile_avatar', value: avatar);
      await prefs.remove('yt_profile_avatar');
    }
  }

  static Future<void> setAuthCookie(String cookie) async {
    await _migrateIfNeeded();
    await _storage.write(key: 'yt_auth_cookie', value: cookie);
  }

  static Future<void> clearAuthCookie() async {
    await _migrateIfNeeded();
    await _storage.delete(key: 'yt_auth_cookie');
  }

  static Future<String?> getCookie() async {
    await _migrateIfNeeded();
    return await _storage.read(key: 'yt_auth_cookie');
  }
  

  static Future<Map<String, String>?> getCachedProfile() async {
    await _migrateIfNeeded();
    final name = await _storage.read(key: 'yt_profile_name');
    final email = await _storage.read(key: 'yt_profile_email');
    final avatar = await _storage.read(key: 'yt_profile_avatar');
    
    if (name != null) {
      return {
        'name': name,
        'email': email ?? '',
        'avatarUrl': avatar ?? '',
      };
    }
    return null;
  }

  static Future<void> clearCachedProfile() async {
    await _migrateIfNeeded();
    await _storage.delete(key: 'yt_profile_name');
    await _storage.delete(key: 'yt_profile_email');
    await _storage.delete(key: 'yt_profile_avatar');
  }

  static bool hasCookie(String? cookie) {
    return cookie != null && cookie.isNotEmpty && 
           (cookie.contains('SAPISID') || cookie.contains('__Secure-3PSID'));
  }

  static String? _getSapisid(String cookie) {
    final match = RegExp(r'SAPISID=([^;]+)').firstMatch(cookie);
    return match?.group(1);
  }

  static String _generateSapisidHash(String sapisid) {
    final time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final sha1Str = sha1.convert(utf8.encode('$time $sapisid https://music.youtube.com')).toString();
    return 'SAPISIDHASH ${time}_$sha1Str';
  }

  static Future<List<Song>> fetchLikedSongs() async {
    final cookie = await getCookie();
    if (!hasCookie(cookie)) {
      throw Exception('Not authenticated. Please sync your account.');
    }

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Cookie': cookie!,
      'Origin': 'https://music.youtube.com',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };

    final sapisid = _getSapisid(cookie);
    if (sapisid != null) {
      headers['Authorization'] = _generateSapisidHash(sapisid);
    }

    final contextPayload = {
      "client": {
        "clientName": "WEB_REMIX", // YT Music Web Client
        "clientVersion": "1.20231214.01.00",
        "hl": "en"
      }
    };

    List<Song> allSongs = [];
    String? continuationToken;

    // Initial Request
    final initialUrl = Uri.parse('$_baseUrl/browse?prettyPrint=false');
    final initialResponse = await http.post(
      initialUrl,
      headers: headers,
      body: jsonEncode({
        "context": contextPayload,
        "browseId": "FEmusic_liked_videos"
      }),
    );

    if (initialResponse.statusCode == 200) {
      final data = jsonDecode(initialResponse.body);
      allSongs.addAll(_parseSongsFromBrowseResponse(data));
      continuationToken = _extractContinuationToken(data);
    }

    // Fetch remaining pages using continuation tokens
    while (continuationToken != null) {
      // YouTube Music continuation endpoint is also /browse
      final contUrl = Uri.parse('$_baseUrl/browse?prettyPrint=false');
      final contResponse = await http.post(
        contUrl,
        headers: headers,
        body: jsonEncode({
          "context": contextPayload,
          "continuation": continuationToken
        }),
      );

      if (contResponse.statusCode == 200) {
        final data = jsonDecode(contResponse.body);
        final newSongs = _parseSongsFromBrowseResponse(data);
        if (newSongs.isEmpty) break; // Safety break
        
        allSongs.addAll(newSongs);
        continuationToken = _extractContinuationToken(data);
      } else {
        break;
      }
    }

    return allSongs;
  }

  static Future<List<Playlist>> fetchUserPlaylists() async {
    final cookie = await getCookie();
    if (!hasCookie(cookie)) return [];

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Cookie': cookie!,
      'Origin': 'https://music.youtube.com',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };
    final sapisid = _getSapisid(cookie);
    if (sapisid != null) headers['Authorization'] = _generateSapisidHash(sapisid);

    final contextPayload = {
      "client": {
        "clientName": "WEB_REMIX",
        "clientVersion": "1.20231214.01.00",
        "hl": "en"
      }
    };

    final url = Uri.parse('$_baseUrl/browse?prettyPrint=false');
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        "context": contextPayload,
        "browseId": "FEmusic_liked_playlists" // The user's playlists tab
      }),
    );

    if (response.statusCode != 200) return [];
    
    final data = jsonDecode(response.body);
    List<Map<String, dynamic>> playlistRenderers = [];
    _findKeys(data, 'musicTwoRowItemRenderer', playlistRenderers);
    
    List<Playlist> userPlaylists = [];
    
    for (var renderer in playlistRenderers) {
      final item = renderer['musicTwoRowItemRenderer'];
      
      // Ignore the "New playlist" button or auto-playlists like "Your Likes" which we already sync separately
      final browseId = item?['navigationEndpoint']?['browseEndpoint']?['browseId'];
      if (browseId == null || browseId == 'FEmusic_liked_videos') continue;

      final titleRuns = item?['title']?['runs'];
      if (titleRuns == null || titleRuns.isEmpty) continue;
      final title = titleRuns[0]['text'] ?? 'Unknown Playlist';

      // Now we have the playlist browseId! We can fetch its songs exactly like we fetch liked songs.
      List<Song> playlistSongs = [];
      String? continuationToken;
      
      final plResponse = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          "context": contextPayload,
          "browseId": browseId
        }),
      );
      
      if (plResponse.statusCode == 200) {
        final plData = jsonDecode(plResponse.body);
        playlistSongs.addAll(_parseSongsFromBrowseResponse(plData));
        continuationToken = _extractContinuationToken(plData);
      }
      
      while (continuationToken != null) {
        final contResponse = await http.post(
          url,
          headers: headers,
          body: jsonEncode({
            "context": contextPayload,
            "continuation": continuationToken
          }),
        );
        if (contResponse.statusCode == 200) {
          final contData = jsonDecode(contResponse.body);
          final newSongs = _parseSongsFromBrowseResponse(contData);
          if (newSongs.isEmpty) break;
          playlistSongs.addAll(newSongs);
          continuationToken = _extractContinuationToken(contData);
        } else {
          break;
        }
      }
      
      // Remove the "VL" prefix from the ID if it exists (YT Music adds VL to playlist IDs)
      final cleanId = browseId.startsWith('VL') ? browseId.substring(2) : browseId;
      
      // Add it to our list
      userPlaylists.add(Playlist(
        id: cleanId,
        name: title,
        songs: playlistSongs,
      ));
    }
    
    return userPlaylists;
  }

  static Future<Map<String, dynamic>?> fetchArtistDetails(String artistName) async {
    final cookie = await getCookie();
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Origin': 'https://music.youtube.com',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };
    
    if (cookie != null && hasCookie(cookie)) {
      headers['Cookie'] = cookie;
      final sapisid = _getSapisid(cookie);
      if (sapisid != null) headers['Authorization'] = _generateSapisidHash(sapisid);
    }

    final contextPayload = {
      "client": {
        "clientName": "WEB_REMIX",
        "clientVersion": "1.20231214.01.00",
        "hl": "en"
      }
    };

    try {
      // 1. Search for the artist
      final searchUrl = Uri.parse('$_baseUrl/search?prettyPrint=false');
      final searchRes = await http.post(
        searchUrl,
        headers: headers,
        body: jsonEncode({
          "context": contextPayload,
          "query": artistName,
          "params": "EgWKAQIgAWoMEA4QChADEAQQCRAF" // Filter for artists
        }),
      );

      if (searchRes.statusCode != 200) return null;
      final searchData = jsonDecode(searchRes.body);
      
      List<Map<String, dynamic>> endpoints = [];
      _findKeys(searchData, 'browseEndpoint', endpoints);
      
      String? browseId;
      for (var ep in endpoints) {
        if (ep['browseEndpoint']?['browseEndpointContextSupportedConfigs']?['browseEndpointContextMusicConfig']?['pageType'] == 'MUSIC_PAGE_TYPE_ARTIST') {
          browseId = ep['browseEndpoint']['browseId'];
          break;
        }
      }
      
      if (browseId == null) return null;

      // 2. Browse the artist page
      final browseUrl = Uri.parse('$_baseUrl/browse?prettyPrint=false');
      final browseRes = await http.post(
        browseUrl,
        headers: headers,
        body: jsonEncode({
          "context": contextPayload,
          "browseId": browseId
        }),
      );

      if (browseRes.statusCode != 200) return null;
      final browseData = jsonDecode(browseRes.body);

      // Extract Header Info
      List<Map<String, dynamic>> headersList = [];
      _findKeys(browseData, 'musicImmersiveHeaderRenderer', headersList);
      
      String name = artistName;
      String imageUrl = '';
      String bio = '';
      
      if (headersList.isNotEmpty) {
        final header = headersList.first['musicImmersiveHeaderRenderer'];
        name = header?['title']?['runs']?[0]?['text'] ?? artistName;
        
        final thumbs = header?['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'];
        if (thumbs != null && thumbs.isNotEmpty) {
          imageUrl = thumbs.last['url'] ?? '';
          if (imageUrl.contains('=w') && imageUrl.contains('-h')) {
            imageUrl = imageUrl.replaceAll(RegExp(r'=w\d+-h\d+'), '=w1200-h1200');
          }
        }
        
        bio = header?['description']?['runs']?[0]?['text'] ?? '';
      }

      // Extract Top Songs
      List<Song> topSongs = _parseSongsFromBrowseResponse(browseData);
      
      // Try to fetch all 100 top songs if a 'See all' endpoint exists
      List<Map<String, dynamic>> shelves = [];
      _findKeys(browseData, 'musicShelfRenderer', shelves);
      
      String? allSongsBrowseId;
      for (var shelf in shelves) {
        final title = shelf['musicShelfRenderer']?['title']?['runs']?[0]?['text'] ?? '';
        if (title.toString().toLowerCase().contains('songs')) {
          final bottomEndpoint = shelf['musicShelfRenderer']?['bottomEndpoint']?['browseEndpoint']?['browseId'];
          if (bottomEndpoint != null) {
            allSongsBrowseId = bottomEndpoint;
            break;
          }
        }
      }

      if (allSongsBrowseId != null) {
        final allSongsRes = await http.post(
          browseUrl,
          headers: headers,
          body: jsonEncode({
            "context": contextPayload,
            "browseId": allSongsBrowseId
          }),
        );
        if (allSongsRes.statusCode == 200) {
          final allSongsData = jsonDecode(allSongsRes.body);
          final extendedSongs = _parseSongsFromBrowseResponse(allSongsData);
          if (extendedSongs.isNotEmpty) {
            topSongs = extendedSongs;
          }
        }
      }
      
      return {
        'id': browseId,
        'name': name,
        'imageUrl': imageUrl,
        'bio': bio,
        'songs': topSongs,
      };

    } catch (e) {
      debugPrint('Error fetching artist details: $e');
      return null;
    }
  }

  static Future<Map<String, String>?> fetchUserProfile() async {
    final cookie = await getCookie();
    if (!hasCookie(cookie)) {
      debugPrint('No cookie found');
      return null;
    }

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Cookie': cookie!,
      'Origin': 'https://music.youtube.com',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    };

    final sapisid = _getSapisid(cookie);
    if (sapisid != null) {
      headers['Authorization'] = _generateSapisidHash(sapisid);
    }

    try {
      final url = Uri.parse('${_baseUrl}/account/account_menu?prettyPrint=false');
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          "context": {
            "client": {
              "clientName": "WEB_REMIX", 
              "clientVersion": "1.20231214.01.00",
            }
          }
        }),
      );

      debugPrint('Profile fetch status: ');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? avatarUrl;
        String? accountName;
        String? accountEmail;
        
        List<Map<String, dynamic>> accountItems = [];
        _findKeys(data, 'accountName', accountItems);
        if (accountItems.isNotEmpty) {
           final item = accountItems.first;
           accountName = item['accountName']?['simpleText'];
           if (accountName == null && item['accountName']?['runs'] != null) {
             accountName = item['accountName']['runs'][0]['text'];
           }
        }
        
        List<Map<String, dynamic>> bylineItems = [];
        _findKeys(data, 'accountByline', bylineItems);
        if (bylineItems.isNotEmpty) {
           final bylineItem = bylineItems.first;
           accountEmail = bylineItem['accountByline']?['simpleText'] ?? bylineItem['accountByline']?['runs']?[0]?['text'];
        }
        
        if (accountEmail == null) {
           List<Map<String, dynamic>> emailItems = [];
           _findKeys(data, 'email', emailItems);
           if (emailItems.isNotEmpty) {
               accountEmail = emailItems.first['email']?['simpleText'] ?? emailItems.first['email']?.toString();
           }
        }
        
        // Final fallback: Use Regex to extract the first email address found in the entire JSON payload!
        if (accountEmail == null) {
            final emailRegExp = RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
            final match = emailRegExp.firstMatch(response.body);
            if (match != null) {
              accountEmail = match.group(0);
            }
        }
           
        List<Map<String, dynamic>> photoItems = [];
        _findKeys(data, 'accountPhoto', photoItems);
        if (photoItems.isNotEmpty) {
           final thumbnails = photoItems.first['accountPhoto']?['thumbnails'];
           if (thumbnails != null && thumbnails.isNotEmpty) {
             avatarUrl = thumbnails.last['url'];
           }
        }
        
        if (accountName != null || accountEmail != null || avatarUrl != null) {
          final profileData = {
            'name': accountName ?? 'YouTube User',
            'email': accountEmail ?? '',
            'avatarUrl': avatarUrl ?? '',
          };
          
          // Save to cache
          await _migrateIfNeeded();
          await _storage.write(key: 'yt_profile_name', value: profileData['name']!);
          await _storage.write(key: 'yt_profile_email', value: profileData['email']!);
          await _storage.write(key: 'yt_profile_avatar', value: profileData['avatarUrl']!);
          
          return profileData;
        }
      }
    } catch (e) {
      debugPrint('Error fetching user profile: ');
    }
    return null;
  }

  static void _findKeys(dynamic data, String targetKey, List<Map<String, dynamic>> results) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey(targetKey)) {
        results.add(data);
      }
      for (var value in data.values) {
        _findKeys(value, targetKey, results);
      }
    } else if (data is List) {
      for (var item in data) {
        _findKeys(item, targetKey, results);
      }
    }
  }

  static List<Song> _parseSongsFromBrowseResponse(Map<String, dynamic> data) {
    final List<Song> songs = [];
    
    try {
      final trackRenderers = _findTrackRenderers(data);
      
      if (trackRenderers.isEmpty) {
        debugPrint('YTMusicSync: Could not find any tracks in the response.');
        return songs;
      }

      for (var trackRenderer in trackRenderers) {

        final flexColumns = trackRenderer['flexColumns'];
        if (flexColumns == null || flexColumns.isEmpty) continue;

        // Title is usually in flexColumn 0
        final titleRun = flexColumns[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0];
        if (titleRun == null) continue;
        
        final title = titleRun['text'] ?? 'Unknown Title';
        final videoId = trackRenderer['playlistItemData']?['videoId'] ?? '';
        
        // Artist and other metadata usually in flexColumn 1
        String artist = 'Unknown Artist';
        if (flexColumns.length > 1) {
          final runs = flexColumns[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'];
          if (runs != null && runs.isNotEmpty) {
             artist = runs[0]['text'] ?? 'Unknown Artist';
          }
        }

        // Thumbnails
        String artwork = '';
        final thumbnails = trackRenderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'];
        if (thumbnails != null && thumbnails.isNotEmpty) {
          artwork = thumbnails.last['url'] ?? '';
          
          // YouTube Music thumbnails usually end with =w120-h120-l90-rj
          // We can force max resolution by replacing the width and height parameters!
          if (artwork.contains('=w') && artwork.contains('-h')) {
            artwork = artwork.replaceAll(RegExp(r'=w\d+-h\d+'), '=w1200-h1200');
          } else if (artwork.contains('?sqp=')) {
            // Some URLs use query params for size
            // We can just strip the query params to get the raw image if it's not a lh3 googleusercontent URL
            // Actually, for YT Music it's safer to keep sqp but it's rare.
          }
        }

        // Only add if we got a valid videoId
        if (videoId.isNotEmpty) {
          songs.add(Song(
            id: videoId,
            title: title,
            artist: artist,
            artwork: artwork,
            source: 'youtube',
          ));
        }
      }
    } catch (e) {
      debugPrint('Error parsing YT Music response: $e');
    }

    return songs;
  }

  // Recursive search to robustly find all track elements regardless of YouTube's layout nesting
  static List<Map<String, dynamic>> _findTrackRenderers(dynamic data) {
    List<Map<String, dynamic>> results = [];
    
    if (data is Map<String, dynamic>) {
      if (data.containsKey('musicResponsiveListItemRenderer')) {
        results.add(data['musicResponsiveListItemRenderer'] as Map<String, dynamic>);
      } else {
        for (var value in data.values) {
          results.addAll(_findTrackRenderers(value));
        }
      }
    } else if (data is List) {
      for (var item in data) {
        results.addAll(_findTrackRenderers(item));
      }
    }
    
    return results;
  }

  // Recursive search to robustly find the continuation token to fetch more pages
  static String? _extractContinuationToken(dynamic data) {
    if (data is Map<String, dynamic>) {
      // Check for standard continuationCommand
      if (data.containsKey('continuationCommand') && data['continuationCommand']['token'] != null) {
        return data['continuationCommand']['token'] as String;
      }
      
      // Check for nextContinuationData (sometimes used in web responses)
      if (data.containsKey('nextContinuationData') && data['nextContinuationData']['continuation'] != null) {
        return data['nextContinuationData']['continuation'] as String;
      }
      
      // Keep searching recursively
      for (var value in data.values) {
        final token = _extractContinuationToken(value);
        if (token != null) return token;
      }
    } else if (data is List) {
      for (var item in data) {
        final token = _extractContinuationToken(item);
        if (token != null) return token;
      }
    }
    
    return null;
  }
}




