import '../../models/song.dart';
import '../profile/user_profile_manager.dart';

class ScoringEngine {
  final UserProfileManager profileManager;

  // TUNABLE CONSTANTS: Normalization bounds
  static const double _personalizationMin = -50.0;
  static const double _personalizationMax = 100.0;
  static const double _seedScoreMax = 130.0;

  // TUNABLE CONSTANTS: Rolling seed drift limits
  static const int _autoPlayDriftThreshold = 15;
  static const double _defaultSeedCeiling = 0.8;
  static const double _driftedSeedCeiling = 0.5;

  ScoringEngine({required this.profileManager});

  double scoreSong({
    required Song song,
    required List<Song> recentHistory,
    required Song? seedTrack,
    required Map<String, int> seedRelatedRanks,
    required int queuePosition, // 1-indexed position in the upcoming queue
    int consecutiveAutoPlays = 0, // Defaults to 0 for backwards compatibility
  }) {
    // 1. Long-term Personalization (Artist Affinity)
    double rawPersonalization = profileManager.getArtistScore(song.artist);
    // Normalize against its known theoretical range (-50 to 100) so blending is stable
    double normPersonalization =
        ((rawPersonalization - _personalizationMin) /
                (_personalizationMax - _personalizationMin))
            .clamp(0.0, 1.0);

    // 2. Session Seed Relevance
    double rawSeedScore = 0.0;
    if (seedTrack != null) {
      if (song.artist == seedTrack.artist) {
        rawSeedScore += 30.0;
      }
      if (seedRelatedRanks.containsKey(song.id)) {
        int rank = seedRelatedRanks[song.id]!;
        rawSeedScore += (100.0 - (rank * 5.0)).clamp(0.0, 100.0);
      }
    }
    // Normalize against its known max (130) so blending is stable
    double normSeed = (rawSeedScore / _seedScoreMax).clamp(0.0, 1.0);

    // 3. Position-dependent Blending
    // Reduce the maximum seed influence if we've drifted far from a user-initiated play
    double currentCeiling = (consecutiveAutoPlays >= _autoPlayDriftThreshold)
        ? _driftedSeedCeiling
        : _defaultSeedCeiling;

    double seedWeight;
    if (queuePosition <= 3) {
      seedWeight = currentCeiling;
    } else if (queuePosition <= 8) {
      // Linearly interpolate from ceiling down to 0.2
      seedWeight =
          currentCeiling -
          ((queuePosition - 3) * ((currentCeiling - 0.2) / 5.0));
    } else {
      seedWeight = 0.1;
    }

    double personalizationWeight = 1.0 - seedWeight;

    // Blend the normalized 0.0-1.0 signals
    double score =
        (normSeed * seedWeight) + (normPersonalization * personalizationWeight);

    // 4. Recent History Penalty (Anti-Repetition)
    // Applied after blending as a hard override; magic numbers kept intact
    int historyIndex = recentHistory.indexWhere((s) => s.id == song.id);
    if (historyIndex != -1) {
      if (historyIndex < 10) {
        score -= 100.0;
      } else {
        score -= 20.0;
      }
    }

    return score;
  }
}
