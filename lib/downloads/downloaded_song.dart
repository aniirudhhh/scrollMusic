import 'dart:convert';
import '../models/song.dart';

class DownloadedSong {
  final String id;
  final String title;
  final String artist;
  final String artworkUrl;
  final String fileName;
  final String? artworkFileName;
  final String mimeType;
  final int fileSizeBytes;
  final int downloadedAt;
  final int? durationMs;
  final int schemaVersion;

  DownloadedSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    required this.fileName,
    this.artworkFileName,
    required this.mimeType,
    required this.fileSizeBytes,
    required this.downloadedAt,
    this.durationMs,
    this.schemaVersion = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artworkUrl': artworkUrl,
      'fileName': fileName,
      'artworkFileName': artworkFileName,
      'mimeType': mimeType,
      'fileSizeBytes': fileSizeBytes,
      'downloadedAt': downloadedAt,
      'durationMs': durationMs,
      'schemaVersion': schemaVersion,
    };
  }

  factory DownloadedSong.fromMap(Map<String, dynamic> map) {
    return DownloadedSong(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      artworkUrl: map['artworkUrl'] ?? '',
      fileName: map['fileName'] ?? '',
      artworkFileName: map['artworkFileName'],
      mimeType: map['mimeType'] ?? 'audio/mp4',
      fileSizeBytes: map['fileSizeBytes']?.toInt() ?? 0,
      downloadedAt: map['downloadedAt']?.toInt() ?? 0,
      durationMs: map['durationMs']?.toInt(),
      schemaVersion: map['schemaVersion']?.toInt() ?? 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory DownloadedSong.fromJson(String source) =>
      DownloadedSong.fromMap(json.decode(source));

  Song toSong() {
    return Song(
      id: id,
      title: title,
      artist: artist,
      artwork: artworkUrl,
      source: 'youtube', // Assuming all downloads are from youtube currently
    );
  }
}
