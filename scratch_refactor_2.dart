import 'dart:io';

void main() {
  final file = File('lib/screens/home/home_controller.dart');
  var content = file.readAsStringSync();

  content = content.replaceAll(RegExp(r'_repo\.fetchMoreRelated\(current\)\.then\(\(added\) \{\s*if \(added\) \{'), 
    '_repo.fetchMoreRelated(current).then((newSongs) {\n        if (newSongs.isNotEmpty) {\n          for (var s in newSongs) _queue.addSongLast(s);');

  content = content.replaceAll(RegExp(r'_repo\.fetchMore\(\)\.then\(\(added\) \{\s*if \(added\) \{'), 
    '_repo.fetchMore().then((newSongs) {\n        if (newSongs.isNotEmpty) {\n          for (var s in newSongs) _queue.addSongLast(s);');

  // One of them is:
  content = content.replaceAll(RegExp(r'_repo\.fetchMore\(isColdBootRefresh: true\)\.then\(\(added\) \{\s*if \(added\) \{'), 
    '_repo.fetchMore().then((newSongs) {\n        if (newSongs.isNotEmpty) {\n          for (var s in newSongs) _queue.addSongLast(s);');

  file.writeAsStringSync(content);
  print('Done second pass.');
}
