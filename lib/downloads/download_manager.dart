import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/song.dart';
import '../extraction/extraction_service.dart';
import 'download_status.dart';
import 'downloaded_song.dart';
import 'download_repository.dart';
import 'download_storage.dart';

class DownloadTask {
  final Song song;
  DownloadStatus status;
  final ValueNotifier<double> progress;
  CancelToken? cancelToken;
  int retryCount;
  String? errorMessage;
  int receivedBytes;
  int? totalBytes;

  DownloadTask({
    required this.song,
    this.status = DownloadStatus.queued,
    this.retryCount = 0,
    this.receivedBytes = 0,
  }) : progress = ValueNotifier<double>(0.0);
}

class DownloadManager extends ChangeNotifier {
  final DownloadRepository _repository;
  final DownloadStorage _storage;
  final ExtractionService _extractor;
  final Dio _dio = Dio();

  bool _isInitialized = false;

  final Map<String, DownloadTask> _active = {};
  final List<String> _waiting = [];
  final Map<String, DownloadedSong> _downloaded = {};

  final int _maxConcurrent = 2;

  DownloadManager(this._repository, this._storage, this._extractor);

  Future<void> init() async {
    if (_isInitialized) return;
    await _storage.init();

    // Load from repo
    final loaded = await _repository.load();
    _downloaded.addAll(loaded);

    // Run reconciliation (Phase 5)
    await _reconcile();

    // Clean stale temp files
    await _storage.cleanTemp();

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _reconcile() async {
    final toRemove = <String>[];
    for (final entry in _downloaded.entries) {
      final song = entry.value;
      final file = File(
        _storage.finalFile(song.id, p.extension(song.fileName)),
      );
      if (!await file.exists()) {
        toRemove.add(song.id);
      } else {
        final length = await file.length();
        if (length != song.fileSizeBytes) {
          toRemove.add(song.id);
        }
      }
    }

    for (final id in toRemove) {
      _downloaded.remove(id);
      await _repository.remove(id);
    }
  }

  List<DownloadedSong> get downloads => _downloaded.values.toList();

  bool isDownloaded(String id) => _downloaded.containsKey(id);

  DownloadTask? taskFor(String id) => _active[id];

  String? localPathIfValid(String id) {
    if (!_downloaded.containsKey(id)) return null;
    final song = _downloaded[id]!;
    final file = File(_storage.finalFile(song.id, p.extension(song.fileName)));
    if (file.existsSync() && file.lengthSync() == song.fileSizeBytes) {
      return file.path;
    }
    return null;
  }

  void enqueue(Song song) {
    if (isDownloaded(song.id) || _active.containsKey(song.id)) return;

    _active[song.id] = DownloadTask(song: song);
    _waiting.add(song.id);
    notifyListeners();

    _pumpQueue();
  }

  void cancel(String id) {
    if (!_active.containsKey(id)) return;

    final task = _active[id]!;
    task.status = DownloadStatus.canceled;
    task.cancelToken?.cancel('User canceled');

    _active.remove(id);
    _waiting.remove(id);

    // Cleanup temp
    final tempPath = _storage.tempFile(id);
    final tempFile = File(tempPath);
    if (tempFile.existsSync()) tempFile.deleteSync();

    notifyListeners();
    _pumpQueue();
  }

  Future<void> delete(String id) async {
    if (isDownloaded(id)) {
      final song = _downloaded[id]!;
      _downloaded.remove(id);
      await _repository.remove(id);
      await _storage.deleteFor(song);
      notifyListeners();
    }
  }

  Future<void> markCorrupt(String id) async {
    await delete(id);
  }

  void _pumpQueue() {
    final running = _active.values
        .where(
          (t) =>
              t.status == DownloadStatus.extracting ||
              t.status == DownloadStatus.downloading,
        )
        .length;

    if (running >= _maxConcurrent) return;

    if (_waiting.isNotEmpty) {
      final id = _waiting.removeAt(0);
      _startDownload(id);
    }
  }

  Future<void> _startDownload(String id) async {
    final task = _active[id];
    if (task == null || task.status == DownloadStatus.canceled) return;

    try {
      task.status = DownloadStatus.extracting;
      notifyListeners();

      // Extract URL
      final stream = await _extractor.extractStream(task.song);
      final streamUrl = stream.streamUrl;
      if (streamUrl.isEmpty) throw Exception("Failed to extract stream URL");

      // Preflight size? We'll just trust Dio to get Content-Length during download for now.

      task.status = DownloadStatus.downloading;
      task.cancelToken = CancelToken();
      notifyListeners();

      final tempPath = _storage.tempFile(id);

      // We assume it's mp4 (m4a) for now since NewPipe extractor gives m4a mostly for YT Music
      final ext = '.m4a';
      final mimeType = 'audio/mp4';

      await _dio.download(
        streamUrl,
        tempPath,
        cancelToken: task.cancelToken,
        options: Options(
          headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
        ),
        onReceiveProgress: (received, total) {
          task.receivedBytes = received;
          if (total > 0) {
            task.totalBytes = total;
            task.progress.value = received / total;
          }
        },
      );

      // Verify and commit
      final tempFile = File(tempPath);
      if (!await tempFile.exists()) throw Exception("Temp file not created");
      final length = await tempFile.length();
      if (length < 50000) throw Exception("File too small");

      final finalPath = _storage.finalFile(id, ext);
      await _storage.commit(tempPath, finalPath);

      final fileName = '$id$ext';
      final downloadedRecord = DownloadedSong(
        id: task.song.id,
        title: task.song.title,
        artist: task.song.artist,
        artworkUrl: task.song.artwork,
        fileName: fileName,
        mimeType: mimeType,
        fileSizeBytes: length,
        downloadedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _repository.upsert(downloadedRecord);
      _downloaded[id] = downloadedRecord;

      task.status = DownloadStatus.completed;
      _active.remove(id);
      notifyListeners();
    } catch (e) {
      if (task.status == DownloadStatus.canceled) return;

      final tempPath = _storage.tempFile(id);
      final tempFile = File(tempPath);
      if (tempFile.existsSync()) tempFile.deleteSync();

      task.errorMessage = e.toString();

      if (task.retryCount < 2 &&
          !(e is DioException && e.type == DioExceptionType.cancel)) {
        task.retryCount++;
        // Re-add to waiting to try again
        _waiting.add(id);
        task.status = DownloadStatus.queued;
      } else {
        task.status = DownloadStatus.failed;
        _active.remove(id);
      }
      notifyListeners();
    } finally {
      _pumpQueue();
    }
  }
}
