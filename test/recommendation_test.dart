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
      final score = scoringEngine.scoreSong(song, []);
      expect(score, 0.0);
    });

    test('Test 2 - Artist preference increases score', () {
      profileManager.recordArtistInteraction('Artist A', 5.0);
      
      final songA = Song(id: '1', title: 'A', artist: 'Artist A', artwork: '', source: 'youtube');
      final songB = Song(id: '2', title: 'B', artist: 'Artist B', artwork: '', source: 'youtube');
      
      expect(scoringEngine.scoreSong(songA, []), greaterThan(0));
      expect(scoringEngine.scoreSong(songB, []), equals(0.0));
    });

    test('Test 6 - Recent repetition applies penalty', () {
      profileManager.recordArtistInteraction('Artist A', 5.0);
      final song = Song(id: '1', title: 'A', artist: 'Artist A', artwork: '', source: 'youtube');
      
      final initialScore = scoringEngine.scoreSong(song, []);
      
      // Add to recent history (recent history is [latest, older, ...])
      final history = [song];
      final penalizedScore = scoringEngine.scoreSong(song, history);
      
      expect(penalizedScore, lessThan(initialScore));
    });
  });
}
