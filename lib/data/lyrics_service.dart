import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/lyric_line.dart';

class LyricsService {
  static const String _baseUrl = 'https://lrclib.net/api';
  static const String _agent = 'Loopr (https://github.com/aniirudhhh/Loopr)';
  static final Map<String, List<LyricLine>?> _cache = {};
  static const int _maxCacheSize = 50;

  void _addToCache(String key, List<LyricLine>? value) {
    _cache[key] = value;
    if (_cache.length > _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// Clean noisy YouTube titles (e.g. "(Official Video)", "Lyrical:")
  String _cleanTitle(String title) {
    String cleaned = title.replaceAll(RegExp(r'\|.*$'), ''); // Remove everything after |
    cleaned = cleaned.replaceAll(RegExp(r'\((?:from|feat\.?|official|lyrical|video|audio|remix)[^)]*\)', caseSensitive: false), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\[.*?\]'), ' '); // Remove []
    cleaned = cleaned.replaceAll(RegExp(r'\b(?:official (?:video|audio|music video)|lyrical|full song|4k video)\b', caseSensitive: false), ' ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<List<LyricLine>?> fetchLyrics(String title, String artist, int durationSeconds) async {
    final cleanTitle = _cleanTitle(title);
    final cleanArtist = _cleanTitle(artist);
    final cacheKey = '$cleanTitle|$cleanArtist|$durationSeconds';
    
    if (_cache.containsKey(cacheKey)) {
      // Move to end to mark as recently used
      final cached = _cache.remove(cacheKey);
      _cache[cacheKey] = cached;
      return cached;
    }

    Exception? lastError;
    
    // 1. Try exact match
    try {
      final uri = Uri.parse('$_baseUrl/get').replace(queryParameters: {
        'track_name': cleanTitle,
        'artist_name': cleanArtist,
        'duration': durationSeconds.toString(),
      });

      final response = await http.get(uri, headers: {'User-Agent': _agent}).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final syncedLyrics = data['syncedLyrics'] as String?;
        if (syncedLyrics != null && syncedLyrics.isNotEmpty) {
          final result = _parseLrc(syncedLyrics);
          _addToCache(cacheKey, result);
          return result;
        }
      }
    } catch (e) {
      debugPrint('Error fetching exact lyrics: $e');
      lastError = e is Exception ? e : Exception(e.toString());
    }

    // 2. Try fuzzy search fallback
    try {
      final searchUri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'track_name': cleanTitle,
        'artist_name': cleanArtist,
      });

      final response = await http.get(searchUri, headers: {'User-Agent': _agent}).timeout(const Duration(seconds: 10));
      lastError = null;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // Find best match based on duration (if available)
        Map<String, dynamic>? bestHit;
        double minDiff = double.infinity;

        for (var hit in data) {
          if (hit['syncedLyrics'] == null || hit['syncedLyrics'].toString().trim().isEmpty) continue;
          
          double duration = (hit['duration'] ?? 0).toDouble();
          double diff = (duration - durationSeconds).abs();
          
          if (diff < minDiff) {
            minDiff = diff;
            bestHit = hit;
          }
        }

        if (bestHit != null) {
          final result = _parseLrc(bestHit['syncedLyrics']);
          _addToCache(cacheKey, result);
          return result;
        }
      }
    } catch (e) {
      debugPrint('Error fetching fuzzy lyrics: $e');
      lastError = e is Exception ? e : Exception(e.toString());
    }

    if (lastError != null) {
      throw lastError;
    }

    _addToCache(cacheKey, null);
    return null;
  }

  List<LyricLine> _parseLrc(String lrc) {
    final RegExp stampRegExp = RegExp(r'\[(\d{1,2}):(\d{2})[.:](\d{2,3})\]');
    final RegExp wordStampRegExp = RegExp(r'<(\d{1,3}):(\d{2})[.:](\d{2,3})>');
    final lines = <LyricLine>[];

    for (var line in lrc.split('\n')) {
      final match = stampRegExp.firstMatch(line);
      if (match == null) continue;

      final minutes = int.parse(match.group(1)!);
      final seconds = int.parse(match.group(2)!);
      final fractionStr = match.group(3)!;
      
      int fractionMs = 0;
      if (fractionStr.length == 2) {
        fractionMs = int.parse(fractionStr) * 10;
      } else if (fractionStr.length == 3) {
        fractionMs = int.parse(fractionStr);
      }

      final timeMs = minutes * 60000 + seconds * 1000 + fractionMs;
      
      // Extract text after the timestamp
      var body = line.substring(match.end).trim();
      // Remove word-level stamps if present (Enhanced LRC)
      body = body.replaceAll(wordStampRegExp, '').trim();

      lines.add(LyricLine(timeMs: timeMs, text: body));
    }

    lines.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    
    // LRC files usually skip instrumental intros, so add a blank line at 0
    if (lines.isNotEmpty && lines.first.timeMs > 5000) {
      lines.insert(0, const LyricLine(timeMs: 0, text: ''));
    }

    return lines;
  }
}
