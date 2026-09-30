import 'package:flutter/foundation.dart';

enum SearchFilter {
  songs,
  videos,
  artists,
  albums,
  featuredPlaylists,
  communityPlaylists,
}

sealed class SearchItem {
  final String id;
  final String title;
  final String thumbnailUrl;

  const SearchItem({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
  });

  String get subtitle;
}

class SongItem extends SearchItem {
  final String artist;
  final String? album;
  final String? duration;

  const SongItem({
    required super.id,
    required super.title,
    required super.thumbnailUrl,
    required this.artist,
    this.album,
    this.duration,
  });

  @override
  String get subtitle => 'Song • $artist';
}

class VideoItem extends SearchItem {
  final String channel;
  final String? views;
  final String? duration;

  const VideoItem({
    required super.id,
    required super.title,
    required super.thumbnailUrl,
    required this.channel,
    this.views,
    this.duration,
  });

  @override
  String get subtitle => 'Video • $channel';
}

class ArtistItem extends SearchItem {
  final String? subscribers;

  const ArtistItem({
    required super.id,
    required super.title,
    required super.thumbnailUrl,
    this.subscribers,
  });

  @override
  String get subtitle =>
      subscribers != null ? 'Artist • $subscribers' : 'Artist';
}

class AlbumItem extends SearchItem {
  final String artist;
  final String? year;

  const AlbumItem({
    required super.id,
    required super.title,
    required super.thumbnailUrl,
    required this.artist,
    this.year,
  });

  @override
  String get subtitle =>
      year != null ? 'Album • $artist • $year' : 'Album • $artist';
}

class PlaylistItem extends SearchItem {
  final String owner;
  final int? songCount;

  const PlaylistItem({
    required super.id,
    required super.title,
    required super.thumbnailUrl,
    required this.owner,
    this.songCount,
  });

  @override
  String get subtitle => 'Playlist • $owner';
}

class EpisodeItem extends SearchItem {
  final String date;

  const EpisodeItem({
    required super.id,
    required super.title,
    required super.thumbnailUrl,
    required this.date,
  });

  @override
  String get subtitle => 'Episode • $date';
}

class SearchPage {
  final List<SearchItem> items;
  final SearchItem? topResult;
  final String? continuation;

  const SearchPage({required this.items, this.topResult, this.continuation});
}
