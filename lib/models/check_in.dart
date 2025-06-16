import 'package:skip_the_chase/models/venue.dart';

class CheckIn {
  final String id;
  final String userId;
  final Venue venue;
  final DateTime checkedInAt;
  final DateTime expiresAt;
  final double latitude;
  final double longitude;

  CheckIn({
    required this.id,
    required this.userId,
    required this.venue,
    required this.checkedInAt,
    required this.expiresAt,
    required this.latitude,
    required this.longitude,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      id: json['id'],
      userId: json['user_id'],
      venue: Venue.fromJson(json['venues']),
      checkedInAt: DateTime.parse(json['checked_in_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'venue_id': venue.id,
      'checked_in_at': checkedInAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  Duration get remainingTime => expiresAt.difference(DateTime.now());
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}