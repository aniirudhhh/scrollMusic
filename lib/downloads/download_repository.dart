import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'downloaded_song.dart';

abstract class DownloadRepository {
  Future<Map<String, DownloadedSong>> load();
  Future<void> upsert(DownloadedSong record);
  Future<void> remove(String id);
  Future<DownloadedSong?> getById(String id);
  Future<void> saveAll(Map<String, DownloadedSong> records);
}

class SharedPreferencesDownloadRepository implements DownloadRepository {
  static const _kDownloadsKey = 'downloads_index_v1';
  final SharedPreferences _prefs;

  SharedPreferencesDownloadRepository(this._prefs);

  @override
  Future<Map<String, DownloadedSong>> load() async {
    try {
      final String? jsonStr = _prefs.getString(_kDownloadsKey);
      if (jsonStr == null || jsonStr.isEmpty) return {};

      final Map<String, dynamic> map = json.decode(jsonStr);
      final result = <String, DownloadedSong>{};

      map.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          result[key] = DownloadedSong.fromMap(value);
        }
      });
      return result;
    } catch (e) {
      // If parsing fails completely, reset and return empty.
      await _prefs.remove(_kDownloadsKey);
      return {};
    }
  }

  @override
  Future<void> upsert(DownloadedSong record) async {
    final current = await load();
    current[record.id] = record;
    await saveAll(current);
  }

  @override
  Future<void> remove(String id) async {
    final current = await load();
    if (current.containsKey(id)) {
      current.remove(id);
      await saveAll(current);
    }
  }

  @override
  Future<DownloadedSong?> getById(String id) async {
    final current = await load();
    return current[id];
  }

  @override
  Future<void> saveAll(Map<String, DownloadedSong> records) async {
    final map = records.map((key, value) => MapEntry(key, value.toMap()));
    final jsonStr = json.encode(map);
    await _prefs.setString(_kDownloadsKey, jsonStr);
  }
}
