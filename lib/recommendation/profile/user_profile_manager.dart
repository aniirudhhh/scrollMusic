import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileManager {
  final SharedPreferences _prefs;
  static const String _kArtistScoresKey = 'rec_artist_scores';

  Map<String, double> _artistScores = {};

  UserProfileManager(this._prefs) {
    _load();
  }

  void _load() {
    final jsonStr = _prefs.getString(_kArtistScoresKey);
    if (jsonStr != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        _artistScores = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      } catch (e) {
        _artistScores = {};
      }
    }
  }

  Future<void> _save() async {
    final scoresCopy = Map<String, double>.from(_artistScores);
    final encoded = await Future.microtask(() => jsonEncode(scoresCopy));
    await _prefs.setString(_kArtistScoresKey, encoded);
  }

  void recordArtistInteraction(String artist, double weight) {
    if (artist.isEmpty || artist == 'Unknown Artist') return;
    
    // Global decay: slowly fade out old preferences to let new tastes take over
    final keys = _artistScores.keys.toList();
    for (final k in keys) {
      _artistScores[k] = _artistScores[k]! * 0.98; // 2% decay on every interaction
    }
    
    // Add weight to the played artist
    double currentScore = _artistScores[artist] ?? 0.0;
    currentScore += weight;
    
    // Clamp to prevent infinite growth
    if (currentScore > 100.0) currentScore = 100.0;
    if (currentScore < -50.0) currentScore = -50.0;

    _artistScores[artist] = currentScore;
    _save();
  }

  double getArtistScore(String artist) {
    return _artistScores[artist] ?? 0.0;
  }

  List<String> getTopArtists(int limit) {
    final entries = _artistScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).map((e) => e.key).toList();
  }
}
