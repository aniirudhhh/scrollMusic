import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  print('Searching for artist...');
  
  // Search in YouTube Music
  final searchResults = await yt.music.search('The Weeknd');
  
  // Filter for artists? Wait, music search returns a list of results.
  for (var result in searchResults) {
    print('Result: ${result.runtimeType} - Title: ${result.name} - ID: ${result.browseId}');
  }
  
  yt.close();
}
