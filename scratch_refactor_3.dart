import 'dart:io';

void main() {
  final file = File('lib/screens/home/home_controller.dart');
  var lines = file.readAsLinesSync();
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('if (added)') && lines[i-1].contains('newSongs')) {
      lines[i] = lines[i].replaceAll('if (added)', 'if (newSongs.isNotEmpty) {\n          for (var s in newSongs) _queue.addSongLast(s);');
    }
  }
  file.writeAsStringSync(lines.join('\n') + '\n');
}
