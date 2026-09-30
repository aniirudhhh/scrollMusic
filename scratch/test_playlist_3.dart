import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final id = 'PL4fGSI1pDJn6puJdseH2Rt9sMvt9E2M4i'; 
  try {
    print('Fetching videos...');
    final stream = yt.playlists.getVideos(id);
    
    await for (var video in stream) {
      print(video.title);
      break; // just get one
    }
    
    print('Done.');
  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
