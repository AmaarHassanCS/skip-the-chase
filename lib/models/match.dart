import 'package:skip_the_chase/models/message.dart';
import 'package:skip_the_chase/models/user_profile.dart';

class Match {
  final String id;
  final UserProfile matchedUser;
  final DateTime createdAt;
  final Message? lastMessage;

  Match({
    required this.id,
    required this.matchedUser,
    required this.createdAt,
    this.lastMessage,
  });

  factory Match.fromJson(Map<String, dynamic> json, String currentUserId) {
    // Determine which user is the matched user (not the current user)
    final isUser1 = json['user1_id'] == currentUserId;
    final matchedUserId = isUser1 ? json['user2_id'] : json['user1_id'];
    final matchedUserJson = json['profiles'] as Map<String, dynamic>;
    
    return Match(
      id: json['id'],
      matchedUser: UserProfile.fromJson(matchedUserJson),
      createdAt: DateTime.parse(json['created_at']),
      lastMessage: json['last_message'] != null 
          ? Message.fromJson(json['last_message']) 
          : null,
    );
  }
}