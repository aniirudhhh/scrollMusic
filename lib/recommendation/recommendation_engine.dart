import '../../models/song.dart';
import '../../extraction/extraction_service.dart';
import 'profile/user_profile_manager.dart';
import 'candidate/candidate_generator.dart';
import 'scoring/scoring_engine.dart';

class RecommendationEngine {
  final UserProfileManager profileManager;
  final CandidateGenerator candidateGenerator;
  final ScoringEngine scoringEngine;
  final ExtractionService extractionService;

  final List<Song> _recentHistory = [];

  RecommendationEngine({
    required this.profileManager,
    required this.extractionService,
  }) : candidateGenerator = CandidateGenerator(
         extractionService: extractionService,
         profileManager: profileManager,
       ),
       scoringEngine = ScoringEngine(profileManager: profileManager);

  Song? currentSeedTrack;
  int consecutiveAutoPlays = 0; // Tracks engine-picked continuations

  // Tracking Events
  // Add an optional parameter to distinguish user actions from auto-advances
  void recordSongStarted(Song song, {bool isUserInitiated = true}) {
    currentSeedTrack = song;

    if (isUserInitiated) {
      consecutiveAutoPlays = 0;
    } else {
      consecutiveAutoPlays++;
    }

    _recentHistory.insert(0, song);
    if (_recentHistory.length > 50) {
      _recentHistory.removeLast();
    }
  }

  void recordSongCompleted(Song song) {
    profileManager.recordArtistInteraction(song.artist, 4.0);
  }

  void recordSongSkipped(Song song, double completionRatio) {
    if (completionRatio < 0.1) {
      profileManager.recordArtistInteraction(song.artist, -3.0);
    } else if (completionRatio > 0.8) {
      profileManager.recordArtistInteraction(song.artist, 3.0);
    } else {
      profileManager.recordArtistInteraction(song.artist, 1.0);
    }
  }

  void recordSongLiked(Song song) {
    profileManager.recordArtistInteraction(song.artist, 6.0);
  }

  Future<List<Song>> getRecommendedFeed({
    int limit = 10,
    Song? overrideSeedTrack,
    int? overrideConsecutiveAutoPlays,
  }) async {
    try {
      final activeSeed = overrideSeedTrack ?? currentSeedTrack;
      final activeAutoPlays = overrideConsecutiveAutoPlays ?? consecutiveAutoPlays;

      // Pass the active session seed to fetch contextually relevant tracks
      final candidateContext = await candidateGenerator.generateCandidates(
        activeSeed,
      );

      if (candidateContext.allCandidates.isEmpty) {
        // Cold start / Fallback
        return await extractionService.fetchDiscoveryFeed();
      }

      List<Song> finalFeed = [];
      String? lastArtist;
      int consecutiveCount = 0;

      // Mutable pool of candidates to select from iteratively
      List<Song> pool = List.from(candidateContext.allCandidates);

      // Iteratively pick the best song for each queue position
      for (int i = 0; i < limit; i++) {
        if (pool.isEmpty) break;

        int queuePosition = i + 1; // 1-indexed

        Song? bestCandidate;
        double bestScore = double.negativeInfinity;

        for (final candidate in pool) {
          // Diversification check
          bool skipForDiversification = false;
          if (candidate.artist == lastArtist && consecutiveCount >= 2) {
            // Relax the 2-consecutive-artist limit if we are early in the queue
            // AND the artist matches the seed artist (let them hear a streak of the seed artist).
            if (queuePosition > 3 ||
                currentSeedTrack?.artist != candidate.artist) {
              skipForDiversification = true;
            }
          }
          if (skipForDiversification) continue;

          // Score for this specific queue position
          double score = scoringEngine.scoreSong(
            song: candidate,
            recentHistory: _recentHistory,
            seedTrack: activeSeed,
            seedRelatedRanks: candidateContext.seedRelatedRanks,
            queuePosition: queuePosition,
            consecutiveAutoPlays: activeAutoPlays,
          );

          if (score > bestScore) {
            bestScore = score;
            bestCandidate = candidate;
          }
        }

        // If diversification filtered out literally everything, just take the raw highest-scoring remaining
        if (bestCandidate == null) {
          bestCandidate = pool.first;
          for (final candidate in pool) {
            double score = scoringEngine.scoreSong(
              song: candidate,
              recentHistory: _recentHistory,
              seedTrack: activeSeed,
              seedRelatedRanks: candidateContext.seedRelatedRanks,
              queuePosition: queuePosition,
              consecutiveAutoPlays: activeAutoPlays,
            );
            if (score > bestScore) {
              bestScore = score;
              bestCandidate = candidate;
            }
          }
        }

        // Add winner to feed and remove from pool
        finalFeed.add(bestCandidate!);
        pool.remove(bestCandidate);

        // Update diversification state
        if (bestCandidate.artist == lastArtist) {
          consecutiveCount++;
        } else {
          lastArtist = bestCandidate.artist;
          consecutiveCount = 1;
        }
      }

      return finalFeed;
    } catch (e) {
      // Safe fallback
      return await extractionService.fetchDiscoveryFeed();
    }
  }
}

/*
 * CONCRETE TEST CASE VALIDATION
 * 
 * Scenario: User has strong historical affinity for artist X (pop).
 * User searches and plays a bhakti song by artist Y (zero prior history).
 * 
 * Flow:
 * 1. recordSongStarted sets currentSeedTrack = artist Y.
 * 2. candidateGenerator fetches related tracks for artist Y, saving their ranks.
 * 3. Loop iterations 1-3 (queuePosition <= 3):
 *    - seedWeight is 0.8, personalizationWeight is 0.2.
 *    - Artist X candidates get their high personalization score * 0.2.
 *    - Artist Y adjacent candidates get (up to 100 rank bonus + 30 same-artist bonus) * 0.8.
 *    - Result: Artist Y adjacent songs massively outscore Artist X songs.
 *    - Diversification explicitly allows >2 Artist Y songs here because queuePosition <= 3.
 * 4. Loop iterations 4-8:
 *    - seedWeight interpolates down (0.68 -> 0.56 -> 0.44 -> 0.32 -> 0.20).
 *    - Personalization weight goes up (0.32 -> 0.44 -> 0.56 -> 0.68 -> 0.80).
 *    - Artist X's high affinity score begins to overtake the decaying seed score.
 *    - The queue seamlessly transitions from Bhakti to Pop.
 */
