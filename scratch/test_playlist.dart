import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final id = 'PL4fGSI1pDJn6puJdseH2Rt9sMvt9E2M4i'; // Example playlist
  try {
    print('Fetching videos...');
    final stream = yt.playlists.getVideos(id);
    int count = 0;
    await for (final vid in stream) {
      count++;
      print('Got: ${vid.title}');
      if (count > 5) break;
    }
    print('Done.');
  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
