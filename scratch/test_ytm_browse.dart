import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://music.youtube.com/youtubei/v1/browse?prettyPrint=false');
  final body = jsonEncode({
    'context': {
      'client': {
        'clientName': 'WEB_REMIX',
        'clientVersion': '1.20230522.01.00',
      }
    },
    'browseId': 'VLPL4fGSI1pDJn6puJdseH2Rt9sMvt9E2M4i'
  });
  
  final res = await http.post(url, body: body, headers: {'Content-Type': 'application/json'});
  final json = jsonDecode(res.body);
  
  final contents = json['contents'];
  if (contents != null) {
      final renderer = contents['twoColumnBrowseResultsRenderer'];
      if (renderer != null) {
          final secondaryContents = renderer['secondaryContents'];
          final sectionList = secondaryContents['sectionListRenderer'];
          final items = sectionList['contents'];
          final playlistRenderer = items[0]['musicPlaylistShelfRenderer'];
          final songs = playlistRenderer['contents'];
          print('Found ' + songs.length.toString() + ' songs!');
          final firstSong = songs[0]['musicResponsiveListItemRenderer'];
          
          try {
              final cols = firstSong['flexColumns'];
              final titleText = cols[0]['musicResponsiveListItemFlexColumnRenderer']['text']['runs'][0]['text'];
              final videoId = firstSong['playlistItemData']['videoId'];
              print('Song 1: ' + titleText + ' (' + videoId + ')');
          } catch(e) {
              print(e);
          }
      }
  }
}
