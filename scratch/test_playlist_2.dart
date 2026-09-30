import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final id = 'PL4fGSI1pDJn6puJdseH2Rt9sMvt9E2M4i'; 
  try {
    print('Fetching videos with timeout...');
    final stream = yt.playlists.getVideos(id);
    
    // Test the iterator
    final iter = stream.iterator;
    print('getting first element...');
    bool hasNext = await iter.moveNext().timeout(Duration(seconds: 5));
    if (hasNext) {
      print('Got: ${iter.current.title}');
    } else {
      print('Stream empty');
    }
    print('Done.');
  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
