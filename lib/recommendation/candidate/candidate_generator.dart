import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/song.dart';
import '../../extraction/extraction_service.dart';
import '../profile/user_profile_manager.dart';

class CandidateContext {
  final List<Song> allCandidates;
  final Map<String, int> seedRelatedRanks;

  CandidateContext(this.allCandidates, this.seedRelatedRanks);
}

class CandidateGenerator {
  final ExtractionService extractionService;
  final UserProfileManager profileManager;
  final Random _random = Random();

  // TUNABLE CONSTANTS: Reduce unnecessary network calls
  static const int _minCandidatesBeforeDiscovery = 15;
  static const int _discoveryRefreshInterval = 3;

  int _generationCount = 0;

  CandidateGenerator({
    required this.extractionService,
    required this.profileManager,
  });

  Future<CandidateContext> generateCandidates(Song? seedTrack) async {
    List<Song> candidates = [];
    Map<String, int> seedRelatedRanks = {};
    _generationCount++;

    if (seedTrack != null) {
      bool gotRelated = false;
      try {
        final related = await extractionService.fetchRecommendations(
          seedTrack.id,
        );
        debugPrint('CANDIDATES: Fetched ${related.length} related tracks from YT Music for seed ${seedTrack.title}');
        
        if (related.isNotEmpty) {
          gotRelated = true;
          for (int i = 0; i < related.length; i++) {
            final song = related[i];
            candidates.add(song);
            seedRelatedRanks[song.id] = i; // Store its rank (0 is highest)
          }
        }
      } catch (e) {
        debugPrint('CANDIDATES: Error fetching related: $e');
      }

      // IF YT MUSIC FAILED TO RETURN RELATED TRACKS (OR THREW ERROR), FALLBACK TO SEARCHING
      if (!gotRelated) {
        // Searching for Title + Artist usually makes YT Music's search algorithm 
        // return the song itself AND a list of very similar songs (same genre/vibe)
        final fallbackQuery = '${seedTrack.title} ${seedTrack.artist}';
        debugPrint('CANDIDATES: Fallback to searching: $fallbackQuery');
        try {
          final searchResults = await extractionService.search(fallbackQuery);
          for (int i = 0; i < searchResults.length; i++) {
            final song = searchResults[i];
            candidates.add(song);
            seedRelatedRanks[song.id] = i + 5; // Rank them highly as pseudo-related
          }
        } catch (e) {
          debugPrint('CANDIDATES: Fallback search also failed: $e');
        }
      }
    }

    // 2. Add exploration/discovery candidates conditionally
    // Only fetch if cold start, not enough related tracks, or it's time for a periodic refresh
    bool needsDiscovery =
        seedTrack == null ||
        candidates.length < _minCandidatesBeforeDiscovery ||
        (_generationCount % _discoveryRefreshInterval == 0);

    debugPrint('CANDIDATES: Needs discovery? $needsDiscovery (Current count: ${candidates.length})');

    if (needsDiscovery) {
      try {
        final explore = await extractionService.fetchDiscoveryFeed();
        debugPrint('CANDIDATES: Fetched ${explore.length} discovery tracks');
        candidates.addAll(explore);
      } catch (e) {
        debugPrint('CANDIDATES: Error fetching discovery: $e');
      }
    }

    // Deduplicate
    final seen = <String>{};
    final uniqueCandidates = candidates.where((s) => seen.add(s.id)).toList();
    
    debugPrint('CANDIDATES: Total unique candidates: ${uniqueCandidates.length}');

    return CandidateContext(uniqueCandidates, seedRelatedRanks);
  }
}
