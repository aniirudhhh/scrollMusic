import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/song.dart';

class QueueManager {
  final SharedPreferences prefs;

  List<Song> songs = [];
  final Set<String> _seenIds = {};
  int currentIndex = 0;

  QueueManager({required this.prefs});

  bool get isEmpty => songs.isEmpty;
  bool get isNotEmpty => songs.isNotEmpty;
  int get length => songs.length;

  Song? get currentSong => songs.isEmpty ? null : songs[currentIndex];

  Song? get(int index) {
    if (index >= 0 && index < songs.length) return songs[index];
    return null;
  }

  void loadCache() {
    final cache = prefs.getString('cached_feed');
    if (cache != null && cache.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(cache);
        songs = decoded.map((e) => Song.fromJson(e as Map<String, dynamic>)).toList();
        for (final s in songs) {
          _seenIds.add(s.id);
        }
      } catch (e) {
        songs.clear();
        _seenIds.clear();
      }
    }
  }

  void saveUpcomingCache() {
    try {
      final startIndex = (currentIndex + 1).clamp(0, songs.length);
      final upcoming = songs.sublist(startIndex).take(15).toList();
      // If the user reached the very end, save the last song just so we have something on boot
      if (upcoming.isEmpty && songs.isNotEmpty) {
        upcoming.add(songs.last);
      }
      if (upcoming.isNotEmpty) {
        final encoded = jsonEncode(upcoming.map((e) => e.toJson()).toList());
        prefs.setString('cached_feed', encoded);
      }
    } catch (e) {
      debugPrint('QueueManager saveUpcomingCache error: $e');
    }
  }

  void insertSong(int index, Song song) {
    songs.insert(index, song);
    _seenIds.add(song.id);
  }

  bool addSongLast(Song song) {
    if (_seenIds.add(song.id)) {
      songs.add(song);
      return true;
    }
    return false;
  }

  void replaceQueueAfter(int index, List<Song> newSongs) {
    if (index + 1 < songs.length) {
      final removed = songs.sublist(index + 1);
      for (final s in removed) {
        _seenIds.remove(s.id);
      }
      songs.removeRange(index + 1, songs.length);
    }
    
    for (final s in newSongs) {
      if (_seenIds.add(s.id)) {
        songs.add(s);
      } else {
        songs.add(s); // If it's a forced insert, we might want to still add it, but this mirrors old logic
      }
    }
  }

  void replaceEntireQueue(List<Song> newSongs) {
    songs.clear();
    _seenIds.clear();
    
    for (final s in newSongs) {
      if (_seenIds.add(s.id)) {
        songs.add(s);
      }
    }
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= songs.length) return;
    if (newIndex < 0 || newIndex > songs.length) return;
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final item = songs.removeAt(oldIndex);
    songs.insert(newIndex, item);
  }
  
  void removeFromQueue(int index) {
    if (index >= 0 && index < songs.length) {
      final removed = songs.removeAt(index);
      _seenIds.remove(removed.id);
    }
  }
}
