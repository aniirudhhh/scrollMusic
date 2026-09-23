import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  try {
    print('Fetching manifest for q1uPPBJ2tcI...');
    final manifest = await yt.videos.streamsClient.getManifest('q1uPPBJ2tcI');
    print('Manifest fetched!');
    final audioStream = manifest.audioOnly.withHighestBitrate();
    print('Stream URL: ${audioStream.url}');
  } catch (e) {
    print('Error: $e');
  } finally {
    yt.close();
  }
}
