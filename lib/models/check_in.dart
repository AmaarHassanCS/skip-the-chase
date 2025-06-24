class CheckIn {
  final String id;
  final String userId;
  final String venueId;
  final double latitude;
  final double longitude;
  final DateTime checkInTime;
  final int expectedDurationMinutes;
  final DateTime? checkOutTime;
  final bool isActive;

  CheckIn({
    required this.id,
    required this.userId,
    required this.venueId,
    required this.latitude,
    required this.longitude,
    required this.checkInTime,
    required this.expectedDurationMinutes,
    this.checkOutTime,
    this.isActive = true,
  });

  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      id: json['id'],
      userId: json['user_id'],
      venueId: json['venue_id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      checkInTime: DateTime.parse(json['check_in_time']),
      expectedDurationMinutes: json['expected_duration_minutes'],
      checkOutTime: json['check_out_time'] != null ? DateTime.parse(json['check_out_time']) : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'venue_id': venueId,
      'latitude': latitude,
      'longitude': longitude,
      'check_in_time': checkInTime.toIso8601String(),
      'expected_duration_minutes': expectedDurationMinutes,
      'check_out_time': checkOutTime?.toIso8601String(),
      'is_active': isActive,
    };
  }

  DateTime get expectedCheckOutTime {
    return checkInTime.add(Duration(minutes: expectedDurationMinutes));
  }

  bool get isExpired {
    return DateTime.now().isAfter(expectedCheckOutTime);
  }
}