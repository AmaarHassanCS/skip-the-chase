class UserProfile {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String gender;
  final String? bio;
  final List<String> interests;
  final String? profilePhotoUrl;
  final List<String> photoUrls;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActive;
  final bool isVerified;
  final bool isActive;

  UserProfile({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.gender,
    this.bio,
    this.interests = const [],
    this.profilePhotoUrl,
    this.photoUrls = const [],
    required this.createdAt,
    required this.updatedAt,
    this.lastActive,
    this.isVerified = false,
    this.isActive = true,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      userId: json['user_id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      birthDate: DateTime.parse(json['birth_date']),
      gender: json['gender'],
      bio: json['bio'],
      interests: List<String>.from(json['interests'] ?? []),
      profilePhotoUrl: json['profile_photo_url'],
      photoUrls: List<String>.from(json['photo_urls'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      lastActive: json['last_active'] != null ? DateTime.parse(json['last_active']) : null,
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'birth_date': birthDate.toIso8601String().split('T')[0],
      'gender': gender,
      'bio': bio,
      'interests': interests,
      'profile_photo_url': profilePhotoUrl,
      'photo_urls': photoUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_active': lastActive?.toIso8601String(),
      'is_verified': isVerified,
      'is_active': isActive,
    };
  }

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}