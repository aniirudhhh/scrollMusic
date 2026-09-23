import 'song.dart';

class Playlist {
  Playlist({
    required this.id,
    required this.name,
    required this.songs,
  });

  final String id;
  final String name;
  final List<Song> songs;

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      songs: (json['songs'] as List<dynamic>)
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'songs': songs.map((s) => s.toJson()).toList(),
      };
}
