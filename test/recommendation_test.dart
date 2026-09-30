import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scroll_music/recommendation/profile/user_profile_manager.dart';
import 'package:scroll_music/recommendation/scoring/scoring_engine.dart';
import 'package:scroll_music/models/song.dart';

void main() {
  group('Recommendation Engine Tests', () {
    late UserProfileManager profileManager;
    late ScoringEngine scoringEngine;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      profileManager = UserProfileManager(prefs);
      scoringEngine = ScoringEngine(profileManager: profileManager);
    });

    test('Test 1 - Empty profile returns 0 score', () {
      final song = Song(id: '1', title: 'A', artist: 'Artist A', artwork: '', source: 'youtube');
      final score = scoringEngine.scoreSong(
        song: song,
        recentHistory: [],
        seedTrack: null,
        seedRelatedRanks: {},
        queuePosition: 1,
      );
      // Base score is ~0.066 due to normalization of 0.0 affinity between [-50, 100]
      expect(score, closeTo(0.0666, 0.001));
    });

    test('Test 2 - Artist preference increases score', () {
      profileManager.recordArtistInteraction('Artist A', 5.0);
      
      final songA = Song(id: '1', title: 'A', artist: 'Artist A', artwork: '', source: 'youtube');
      final songB = Song(id: '2', title: 'B', artist: 'Artist B', artwork: '', source: 'youtube');
      
      expect(scoringEngine.scoreSong(
        song: songA,
        recentHistory: [],
        seedTrack: null,
        seedRelatedRanks: {},
        queuePosition: 1,
      ), greaterThan(0.067));
      expect(scoringEngine.scoreSong(
        song: songB,
        recentHistory: [],
        seedTrack: null,
        seedRelatedRanks: {},
        queuePosition: 1,
      ), closeTo(0.0666, 0.001));
    });

    test('Test 6 - Recent repetition applies penalty', () {
      profileManager.recordArtistInteraction('Artist A', 5.0);
      final song = Song(id: '1', title: 'A', artist: 'Artist A', artwork: '', source: 'youtube');
      
      final initialScore = scoringEngine.scoreSong(
        song: song,
        recentHistory: [],
        seedTrack: null,
        seedRelatedRanks: {},
        queuePosition: 1,
      );
      
      // Add to recent history (recent history is [latest, older, ...])
      final history = [song];
      final penalizedScore = scoringEngine.scoreSong(
        song: song,
        recentHistory: history,
        seedTrack: null,
        seedRelatedRanks: {},
        queuePosition: 2,
      );
      
      expect(penalizedScore, lessThan(initialScore));
    });
  });
}
