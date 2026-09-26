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
    await _prefs.setString(_kArtistScoresKey, jsonEncode(_artistScores));
  }

  void recordArtistInteraction(String artist, double weight) {
    if (artist.isEmpty || artist == 'Unknown Artist') return;
    
    // Apply decay to existing score to prevent dominance
    double currentScore = _artistScores[artist] ?? 0.0;
    
    // Smooth update: newScore = oldScore * decay + weight
    currentScore = (currentScore * 0.95) + weight;
    
    // Clamp to prevent infinite growth or negativity
    if (currentScore > 100.0) currentScore = 100.0;
    if (currentScore < -50.0) currentScore = -50.0;

    _artistScores[artist] = currentScore;
    _save();
  }

  double getArtistScore(String artist) {
    return _artistScores[artist] ?? 0.0;
  }
}
