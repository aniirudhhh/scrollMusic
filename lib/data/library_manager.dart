import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';
import '../models/song.dart';

const _kLikedSongsKey = 'library_liked_songs';
const _kCustomPlaylistsKey = 'library_custom_playlists';
const _kRecentlyPlayedKey = 'library_recently_played';

class LibraryManager extends ChangeNotifier {
  LibraryManager(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;

  List<Song> _likedSongs = [];
  List<Playlist> _customPlaylists = [];
  List<Song> _recentlyPlayed = [];

  List<Song> get likedSongs => _likedSongs;
  List<Playlist> get customPlaylists => _customPlaylists;
  List<Song> get recentlyPlayed => _recentlyPlayed;

  void _load() {
    // Load Liked Songs
    final likedJson = _prefs.getStringList(_kLikedSongsKey) ?? [];
    _likedSongs = likedJson.map((jsonStr) => Song.fromJson(jsonDecode(jsonStr))).toList();

    // Load Custom Playlists
    final playlistsJson = _prefs.getStringList(_kCustomPlaylistsKey) ?? [];
    _customPlaylists = playlistsJson
        .map((jsonStr) => Playlist.fromJson(jsonDecode(jsonStr)))
        .toList();

    // Load Recently Played
    final recentJson = _prefs.getStringList(_kRecentlyPlayedKey) ?? [];
    _recentlyPlayed = recentJson.map((jsonStr) => Song.fromJson(jsonDecode(jsonStr))).toList();

    notifyListeners();
  }

  Future<void> _saveLiked() async {
    final strList = _likedSongs.map((s) => jsonEncode(s.toJson())).toList();
    await _prefs.setStringList(_kLikedSongsKey, strList);
    notifyListeners();
  }

  Future<void> _savePlaylists() async {
    final strList = _customPlaylists.map((p) => jsonEncode(p.toJson())).toList();
    await _prefs.setStringList(_kCustomPlaylistsKey, strList);
    notifyListeners();
  }

  Future<void> _saveRecent() async {
    final strList = _recentlyPlayed.map((s) => jsonEncode(s.toJson())).toList();
    await _prefs.setStringList(_kRecentlyPlayedKey, strList);
    notifyListeners();
  }

  // ─── Recently Played ──────────────────────────────────────────────────────

  Future<void> addToHistory(Song song) async {
    // Remove if already exists to move it to the top
    _recentlyPlayed.removeWhere((s) => s.id == song.id);
    
    // Insert at top
    _recentlyPlayed.insert(0, song);
    
    // Cap at 50 songs
    if (_recentlyPlayed.length > 50) {
      _recentlyPlayed = _recentlyPlayed.sublist(0, 50);
    }
    
    await _saveRecent();
  }

  // ─── Liked Songs ──────────────────────────────────────────────────────────

  bool isLiked(String songId) {
    return _likedSongs.any((s) => s.id == songId);
  }

  Future<void> toggleLike(Song song) async {
    if (isLiked(song.id)) {
      _likedSongs.removeWhere((s) => s.id == song.id);
    } else {
      // Insert at top
      _likedSongs.insert(0, song);
    }
    await _saveLiked();
  }

  // ─── Custom Playlists ─────────────────────────────────────────────────────

  Future<void> createPlaylist(String name) async {
    if (name.trim().isEmpty) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _customPlaylists.add(Playlist(id: id, name: name.trim(), songs: []));
    await _savePlaylists();
  }

  Future<void> deletePlaylist(String id) async {
    _customPlaylists.removeWhere((p) => p.id == id);
    await _savePlaylists();
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    final idx = _customPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final playlist = _customPlaylists[idx];
      if (!playlist.songs.any((s) => s.id == song.id)) {
        playlist.songs.insert(0, song);
        await _savePlaylists();
      }
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final idx = _customPlaylists.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      _customPlaylists[idx].songs.removeWhere((s) => s.id == songId);
      await _savePlaylists();
    }
  }
}
