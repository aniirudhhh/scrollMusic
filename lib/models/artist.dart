class Artist {
  final String id; // YouTube channel/browse ID
  final String name;
  final String imageUrl;
  
  const Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
    };
  }
}
