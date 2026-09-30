import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../extraction/extraction_service.dart';
import '../recommendation/recommendation_engine.dart';

/// Fetches songs for the infinite stream.
class SongRepository {
  SongRepository({
    required this.extractionService,
    required this.recommendationEngine,
  });

  final ExtractionService extractionService;
  final RecommendationEngine recommendationEngine;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<List<Song>> fetchMore() async {
    if (_isLoading) return [];
    _isLoading = true;
    try {
      return await recommendationEngine.getRecommendedFeed(limit: 10);
    } catch (e) {
      debugPrint('SongRepository fetchMore error: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<List<Song>> fetchMoreRelated(Song song) async {
    if (_isLoading) return [];
    _isLoading = true;
    try {
      return await recommendationEngine.getRecommendedFeed(
        limit: 10,
        overrideSeedTrack: song,
      );
    } catch (e) {
      debugPrint('SongRepository fetchMoreRelated error: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }
}
