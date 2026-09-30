import 'dart:convert';

void main() {
  String text = "Playlist ÃƒÆ’Ã� â€™Ãƒâ€� Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â� M F Photography";
  print('Original: ' + text);
  
  String current = text;
  for (int i = 0; i < 3; i++) {
    try {
      current = utf8.decode(latin1.encode(current));
      print('Fixed ' + (i+1).toString() + ': ' + current);
    } catch (e) {
      print('Failed at ' + (i+1).toString() + ': ' + e.toString());
      break;
    }
  }
}
