import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final query = 'Arijit Singh';
  final url = Uri.parse('https://suggestqueries-clients6.youtube.com/complete/search?client=firefox&ds=yt&q=$query');
  final res = await http.get(url);
  print(res.body);
}
