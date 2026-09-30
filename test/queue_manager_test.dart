import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scroll_music/models/song.dart';
import 'package:scroll_music/screens/home/queue_manager.dart';

void main() {
  late QueueManager queueManager;

  final song1 = Song(id: '1', title: 'Title 1', artist: 'Artist 1', artwork: '', source: 'youtube');
  final song2 = Song(id: '2', title: 'Title 2', artist: 'Artist 2', artwork: '', source: 'youtube');
  final song3 = Song(id: '3', title: 'Title 3', artist: 'Artist 3', artwork: '', source: 'youtube');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    queueManager = QueueManager(prefs: prefs);
  });

  group('QueueManager', () {
    test('initializes empty', () {
      expect(queueManager.isEmpty, isTrue);
      expect(queueManager.length, 0);
      expect(queueManager.currentSong, isNull);
    });

    test('addSongLast adds unique songs only', () {
      final added1 = queueManager.addSongLast(song1);
      expect(added1, isTrue);
      expect(queueManager.length, 1);

      final added2 = queueManager.addSongLast(song1); // Duplicate
      expect(added2, isFalse);
      expect(queueManager.length, 1);

      final added3 = queueManager.addSongLast(song2);
      expect(added3, isTrue);
      expect(queueManager.length, 2);
    });

    test('insertSong adds song at specific index', () {
      queueManager.addSongLast(song1);
      queueManager.addSongLast(song3);
      
      queueManager.insertSong(1, song2);
      
      expect(queueManager.length, 3);
      expect(queueManager.get(1)?.id, '2');
    });

    test('replaceEntireQueue clears old queue and deduplicates new songs', () {
      queueManager.addSongLast(song1);
      
      queueManager.replaceEntireQueue([song2, song3, song2]);
      
      expect(queueManager.length, 2); // 2 unique songs
      expect(queueManager.get(0)?.id, '2');
      expect(queueManager.get(1)?.id, '3');
    });

    test('reorderQueue moves song correctly', () {
      queueManager.replaceEntireQueue([song1, song2, song3]);
      
      queueManager.reorderQueue(0, 2); // Move song1 after song2
      
      expect(queueManager.get(0)?.id, '2');
      expect(queueManager.get(1)?.id, '1');
      expect(queueManager.get(2)?.id, '3');
    });
    
    test('reorderQueue moving backwards', () {
      queueManager.replaceEntireQueue([song1, song2, song3]);
      
      queueManager.reorderQueue(2, 0); // Move song3 to start
      
      expect(queueManager.get(0)?.id, '3');
      expect(queueManager.get(1)?.id, '1');
      expect(queueManager.get(2)?.id, '2');
    });

    test('saveUpcomingCache and loadCache', () async {
      queueManager.replaceEntireQueue([song1, song2, song3]);
      queueManager.currentIndex = 0;
      
      queueManager.saveUpcomingCache(); // Will save song2 and song3

      // Create new QueueManager to simulate app restart
      final prefs = await SharedPreferences.getInstance();
      final newManager = QueueManager(prefs: prefs);
      newManager.loadCache();
      
      expect(newManager.length, 2);
      expect(newManager.get(0)?.id, '2');
      expect(newManager.get(1)?.id, '3');
    });
  });
}
