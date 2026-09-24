import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../models/artist.dart';
import 'yt_music_sync_service.dart';

const _kLikedSongsKey = 'library_liked_songs';
const _kCustomPlaylistsKey = 'library_custom_playlists';
const _kRecentlyPlayedKey = 'library_recently_played';
const _kFollowedArtistsKey = 'library_followed_artists';

class LibraryManager extends ChangeNotifier {
  LibraryManager(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;

  List<Song> _likedSongs = [];
  List<Playlist> _customPlaylists = [];
  List<Song> _recentlyPlayed = [];
  List<Artist> _followedArtists = [];

  List<Song> get likedSongs => _likedSongs;
  List<Playlist> get customPlaylists => _customPlaylists;
  List<Song> get recentlyPlayed => _recentlyPlayed;
  List<Artist> get followedArtists => _followedArtists;

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

    // Load Followed Artists
    final artistsJson = _prefs.getStringList(_kFollowedArtistsKey) ?? [];
    _followedArtists = artistsJson.map((jsonStr) => Artist.fromJson(jsonDecode(jsonStr))).toList();

    notifyListeners();
  }

  Future<int> syncYTMusic() async {
    try {
      final fetchedSongs = await YTMusicSyncService.fetchLikedSongs();
      int updatedCount = 0;
      
      if (fetchedSongs.isNotEmpty) {
        List<Song> songsToAdd = [];
        
        for (var fetchedSong in fetchedSongs) {
          final index = _likedSongs.indexWhere((s) => s.id == fetchedSong.id);
          if (index != -1) {
            // Update artwork if it changed
            if (_likedSongs[index].artwork != fetchedSong.artwork) {
              _likedSongs[index] = fetchedSong;
              updatedCount++;
            }
          } else {
            songsToAdd.add(fetchedSong);
            updatedCount++;
          }
        }
        
        // Prepend new songs at the top of the list to match YouTube's ordering
        if (songsToAdd.isNotEmpty) {
          _likedSongs = [...songsToAdd, ..._likedSongs];
        }
        await _saveLiked();
      }

      // Sync custom playlists
      final fetchedPlaylists = await YTMusicSyncService.fetchUserPlaylists();
      if (fetchedPlaylists.isNotEmpty) {
        // Simple merge: we can overwrite existing custom playlists if they match, 
        // or just replace the entire list to ensure perfect sync.
        // For custom playlists synced from YouTube, replacing is safest to catch deletes and reorders.
        
        // Let's keep local-only playlists (ones we created here that aren't on YT).
        // A simple way is to identify YT playlists by checking if their ID contains letters (YT IDs are alphanumeric).
        // Local ones were created using timestamp strings like '1701234567890'.
        final localPlaylists = _customPlaylists.where((p) => int.tryParse(p.id) != null).toList();
        
        _customPlaylists = [...fetchedPlaylists, ...localPlaylists];
        await _savePlaylists();
        updatedCount += fetchedPlaylists.length; // Just to show some progress in the toast
      }

      return updatedCount;
    } catch (e) {
      debugPrint('Sync Error: $e');
      rethrow;
    }
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

  Future<void> _saveArtists() async {
    final strList = _followedArtists.map((a) => jsonEncode(a.toJson())).toList();
    await _prefs.setStringList(_kFollowedArtistsKey, strList);
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

  // ─── Followed Artists ──────────────────────────────────────────────────────

  bool isArtistFollowed(String artistId) {
    return _followedArtists.any((a) => a.id == artistId);
  }

  Future<void> toggleFollowArtist(Artist artist) async {
    if (isArtistFollowed(artist.id)) {
      _followedArtists.removeWhere((a) => a.id == artist.id);
    } else {
      _followedArtists.insert(0, artist);
    }
    await _saveArtists();
  }
}
