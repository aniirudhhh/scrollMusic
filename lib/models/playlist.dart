import 'song.dart';

class Playlist {
  Playlist({
    required this.id,
    required this.name,
    required this.songs,
    this.description,
    this.imagePath,
  });

  final String id;
  final String name;
  final String? description;
  final String? imagePath;
  final List<Song> songs;

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imagePath: json['imagePath'] as String?,
      songs: (json['songs'] as List<dynamic>)
          .map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'imagePath': imagePath,
        'songs': songs.map((s) => s.toJson()).toList(),
      };
      
  Playlist copyWith({
    String? name,
    String? description,
    String? imagePath,
    List<Song>? songs,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      songs: songs ?? this.songs,
    );
  }
}
