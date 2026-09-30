import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'downloaded_song.dart';

class DownloadStorage {
  late final Directory _docsDir;
  late final Directory _finalDir;
  late final Directory _tempDir;
  late final Directory _artDir;

  bool _initialized = false;
  Future<void>? _initFuture;

  Future<void> init() async {
    if (_initialized) return;
    if (_initFuture != null) return _initFuture;

    _initFuture = _doInit();
    await _initFuture;
    _initialized = true;
    _initFuture = null;
  }

  Future<void> _doInit() async {
    _docsDir = await getApplicationDocumentsDirectory();
    _finalDir = Directory(p.join(_docsDir.path, 'downloads'));
    _tempDir = Directory(p.join(_docsDir.path, 'downloads', 'tmp'));
    _artDir = Directory(p.join(_docsDir.path, 'downloads', 'artwork'));

    await _finalDir.create(recursive: true);
    await _tempDir.create(recursive: true);
    await _artDir.create(recursive: true);
  }

  String finalFile(String id, String ext) {
    return p.join(_finalDir.path, '$id$ext');
  }

  String tempFile(String id) {
    return p.join(_tempDir.path, '$id.part');
  }

  String artFile(String id) {
    return p.join(_artDir.path, '$id.jpg');
  }

  Future<File> commit(String tempPath, String finalPath) async {
    final tempFile = File(tempPath);
    if (!await tempFile.exists()) {
      throw FileSystemException("Temp file not found", tempPath);
    }
    return tempFile.rename(finalPath);
  }

  Future<void> deleteFor(DownloadedSong song) async {
    final audioFile = File(p.join(_finalDir.path, song.fileName));
    if (await audioFile.exists()) {
      await audioFile.delete();
    }

    if (song.artworkFileName != null) {
      final artFile = File(p.join(_artDir.path, song.artworkFileName!));
      if (await artFile.exists()) {
        await artFile.delete();
      }
    }
  }

  Future<void> cleanTemp() async {
    if (!await _tempDir.exists()) return;
    final entities = _tempDir.listSync();
    for (var entity in entities) {
      if (entity is File && entity.path.endsWith('.part')) {
        await entity.delete();
      }
    }
  }

  Future<bool> hasFreeSpace(int requiredBytes) async {
    // A proper implementation would use a native channel or a package
    // to check free disk space. For v1, we assume true and catch errors on write.
    return true;
  }
}
