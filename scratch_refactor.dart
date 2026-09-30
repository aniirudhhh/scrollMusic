import 'dart:io';

void main() {
  final file = File('lib/screens/home/home_controller.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll('_repo.loadCache()', '_queue.loadCache()');
  
  // Replace _repo.fetchMore(isColdBootRefresh: true).then((added) {
  content = content.replaceAll('_repo.fetchMore(isColdBootRefresh: true).then((added) {', '_repo.fetchMore().then((newSongs) {');
  
  // Fix the block in _init:
  content = content.replaceAll('''
      _repo.fetchMore(isColdBootRefresh: true).then((added) {
        if (added) {

          notifyListeners();
''', '''
      _repo.fetchMore().then((newSongs) {
        if (newSongs.isNotEmpty) {
          for (var s in newSongs) _queue.addSongLast(s);
          notifyListeners();
''');
  
  // Fix _repo.fetchMore().then((added) { in _handleReconnection
  content = content.replaceAll('''
      _repo.fetchMoreRelated(current).then((added) {
        if (added) {

          notifyListeners();
''', '''
      _repo.fetchMoreRelated(current).then((newSongs) {
        if (newSongs.isNotEmpty) {
          for (var s in newSongs) _queue.addSongLast(s);
          notifyListeners();
''');

  content = content.replaceAll('''
          _repo.fetchMore().then((added) {
            if (added) {

              notifyListeners();
''', '''
          _repo.fetchMore().then((fallbackSongs) {
            if (fallbackSongs.isNotEmpty) {
              for (var s in fallbackSongs) _queue.addSongLast(s);
              notifyListeners();
''');

  content = content.replaceAll('''
        _repo.fetchMore().then((added) {
          if (added) {

            notifyListeners();
''', '''
        _repo.fetchMore().then((fallbackSongs) {
          if (fallbackSongs.isNotEmpty) {
            for (var s in fallbackSongs) _queue.addSongLast(s);
            notifyListeners();
''');

  content = content.replaceAll('''
      _repo.fetchMore().then((added) {
        if (added) {

          notifyListeners();
''', '''
      _repo.fetchMore().then((newSongs) {
        if (newSongs.isNotEmpty) {
          for (var s in newSongs) _queue.addSongLast(s);
          notifyListeners();
''');

  // Also replace `await _repo.fetchMore();`
  content = content.replaceAll('''
      try {
        await _repo.fetchMore();
      } catch (e) {
''', '''
      try {
        final newSongs = await _repo.fetchMore();
        for (var s in newSongs) _queue.addSongLast(s);
      } catch (e) {
''');

  file.writeAsStringSync(content);
  print('Replaced fetchMore callbacks.');
}
