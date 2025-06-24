class Match {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;

  Match({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    required this.expiresAt,
    this.isActive = true,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'],
      user1Id: json['user1_id'],
      user2Id: json['user2_id'],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }
}