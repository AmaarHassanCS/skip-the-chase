class Message {
  final String id;
  final String matchId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  Message({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      matchId: json['match_id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      text: json['text'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'text': text,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }
}