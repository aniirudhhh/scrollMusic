import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../extraction/extraction_service.dart';

class DownloadedSong {
  final Song song;
  final String localAudioPath;
  final String? localArtworkPath;

  DownloadedSong({
    required this.song,
    required this.localAudioPath,
    this.localArtworkPath,
  });

  Map<String, dynamic> toJson() => {
        'song': song.toJson(),
        'localAudioPath': localAudioPath,
        'localArtworkPath': localArtworkPath,
      };

  factory DownloadedSong.fromJson(Map<String, dynamic> json) => DownloadedSong(
        song: Song.fromJson(json['song']),
        localAudioPath: json['localAudioPath'] as String,
        localArtworkPath: json['localArtworkPath'] as String?,
      );
}

class DownloadManager extends ChangeNotifier {
  DownloadManager(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;
  final Dio _dio = Dio();
  static const String _kDownloadedSongsKey = 'downloaded_songs';

  final Map<String, DownloadedSong> _downloadedSongs = {};
  final Map<String, CancelToken> _activeDownloads = {};
  final Map<String, double> _downloadProgress = {};

  List<DownloadedSong> get downloadedSongs => _downloadedSongs.values.toList();
  Map<String, double> get downloadProgress => _downloadProgress;

  void _load() {
    final jsonList = _prefs.getStringList(_kDownloadedSongsKey) ?? [];
    for (final str in jsonList) {
      try {
        final dl = DownloadedSong.fromJson(jsonDecode(str));
        _downloadedSongs[dl.song.id] = dl;
      } catch (e) {
        debugPrint('Error loading downloaded song: $e');
      }
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final list = _downloadedSongs.values.map((s) => jsonEncode(s.toJson())).toList();
    await _prefs.setStringList(_kDownloadedSongsKey, list);
    notifyListeners();
  }

  bool isDownloaded(String songId) => _downloadedSongs.containsKey(songId);
  bool isDownloading(String songId) => _activeDownloads.containsKey(songId);

  Future<void> startDownload(Song song, ExtractionService extractionService) async {
    if (isDownloaded(song.id) || isDownloading(song.id)) return;

    final cancelToken = CancelToken();
    _activeDownloads[song.id] = cancelToken;
    _downloadProgress[song.id] = 0.0;
    notifyListeners();

    try {
      final stream = await extractionService.extractStream(song);
      final streamUrl = stream.streamUrl;

      final dir = await getApplicationDocumentsDirectory();
      final safeId = song.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final audioFileName = 'song_$safeId.m4a';
      final artworkFileName = 'art_$safeId.jpg';
      final audioSavePath = '${dir.path}/$audioFileName';
      final artworkSavePath = '${dir.path}/$artworkFileName';

      // Chunked download to bypass YouTube throttling
      final file = File(audioSavePath);
      final raf = file.openSync(mode: FileMode.write);
      try {
        int totalLength = -1;
        try {
          final res = await _dio.get(
            streamUrl,
            options: Options(headers: {'Range': 'bytes=0-0'}),
          );
          final contentRange = res.headers.value(HttpHeaders.contentRangeHeader);
          if (contentRange != null && contentRange.contains('/')) {
            totalLength = int.tryParse(contentRange.split('/').last) ?? -1;
          }
        } catch (e) {
          debugPrint('Failed to get content length via range: $e');
        }

        if (totalLength <= 0) {
          // Fallback to normal download if Content-Length is missing
          await _dio.download(
            streamUrl,
            audioSavePath,
            cancelToken: cancelToken,
            onReceiveProgress: (count, total) {
              if (total > 0) {
                _downloadProgress[song.id] = count / total;
                notifyListeners();
              }
            },
          );
        } else {
          int downloaded = 0;
          final chunkSize = 1024 * 1024; // 1MB chunks bypasses throttle well
          for (int start = 0; start < totalLength; start += chunkSize) {
            if (cancelToken.isCancelled) throw Exception('User cancelled');
            int end = start + chunkSize - 1;
            if (end >= totalLength) end = totalLength - 1;

            final res = await _dio.get<ResponseBody>(
              streamUrl,
              options: Options(
                headers: {'Range': 'bytes=$start-$end'},
                responseType: ResponseType.stream,
              ),
              cancelToken: cancelToken,
            );

            await for (final chunk in res.data!.stream) {
              if (cancelToken.isCancelled) throw Exception('User cancelled');
              raf.writeFromSync(chunk);
              downloaded += chunk.length;
              _downloadProgress[song.id] = downloaded / totalLength;
              notifyListeners();
            }
          }
        }
      } finally {
        raf.closeSync();
        if (cancelToken.isCancelled && await file.exists()) {
          await file.delete();
        }
      }

      // Download Artwork if possible
      String? localArtPath;
      if (song.artwork.isNotEmpty) {
        try {
          await _dio.download(song.artwork, artworkSavePath, cancelToken: cancelToken);
          localArtPath = artworkSavePath;
        } catch (e) {
          debugPrint('Failed to download artwork for ${song.title}: $e');
        }
      }

      if (cancelToken.isCancelled) {
        if (await File(audioSavePath).exists()) {
          await File(audioSavePath).delete();
        }
        return;
      }

      final downloadedSong = DownloadedSong(
        song: song,
        localAudioPath: audioSavePath,
        localArtworkPath: localArtPath,
      );

      _downloadedSongs[song.id] = downloadedSong;
      _activeDownloads.remove(song.id);
      _downloadProgress.remove(song.id);
      await _save();
    } catch (e) {
      debugPrint('Download failed for ${song.id}: $e');
      try {
        final dir = await getApplicationDocumentsDirectory();
        final safeId = song.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final audioSavePath = '${dir.path}/song_$safeId.m4a';
        if (await File(audioSavePath).exists()) {
          await File(audioSavePath).delete();
        }
      } catch (_) {}
      _activeDownloads.remove(song.id);
      _downloadProgress.remove(song.id);
      notifyListeners();
    }
  }

  void cancelDownload(String songId) {
    if (_activeDownloads.containsKey(songId)) {
      _activeDownloads[songId]?.cancel('User cancelled');
      _activeDownloads.remove(songId);
      _downloadProgress.remove(songId);
      notifyListeners();
    }
  }

  Future<void> removeDownload(String songId) async {
    final dl = _downloadedSongs.remove(songId);
    if (dl != null) {
      try {
        final audioFile = File(dl.localAudioPath);
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
        if (dl.localArtworkPath != null) {
          final artFile = File(dl.localArtworkPath!);
          if (await artFile.exists()) {
            await artFile.delete();
          }
        }
      } catch (e) {
        debugPrint('Error deleting files for $songId: $e');
      }
      await _save();
    }
  }

  DownloadedSong? getDownload(String songId) => _downloadedSongs[songId];
}
