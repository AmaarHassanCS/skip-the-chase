class Venue {
  final String id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final String? address;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  Venue({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.address,
    this.imageUrl,
    this.metadata,
    required this.createdAt,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      radius: json['radius'].toDouble(),
      address: json['address'],
      imageUrl: json['image_url'],
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'address': address,
      'image_url': imageUrl,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}