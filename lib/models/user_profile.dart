class UserProfile {
  final String id;
  final String name;
  final int age;
  final DateTime birthDate;
  final String? bio;
  final String? avatarUrl;
  final List<String>? interests;
  final Map<String, dynamic>? preferences;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.birthDate,
    this.bio,
    this.avatarUrl,
    this.interests,
    this.preferences,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      birthDate: DateTime.parse(json['birth_date']),
      bio: json['bio'],
      avatarUrl: json['avatar_url'],
      interests: json['interests'] != null 
          ? List<String>.from(json['interests']) 
          : null,
      preferences: json['preferences'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'birth_date': birthDate.toIso8601String(),
      'bio': bio,
      'avatar_url': avatarUrl,
      'interests': interests,
      'preferences': preferences,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}