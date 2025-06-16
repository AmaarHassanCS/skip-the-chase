import 'package:skip_the_chase/models/message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ChatService {
  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<List<Message>> getMessages(String matchId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .eq('match_id', matchId)
          .order('created_at', ascending: false)
          .limit(50);
      
      return response.map<Message>((json) => Message.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    try {
      final messageId = _uuid.v4();
      final now = DateTime.now().toIso8601String();
      
      await _supabase.from('messages').insert({
        'id': messageId,
        'match_id': matchId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'text': text,
        'created_at': now,
        'is_read': false,
      });
      
      // Update the match with the last message timestamp
      await _supabase
          .from('matches')
          .update({'last_message_at': now})
          .eq('id', matchId);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> markMessagesAsRead(String matchId, String userId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('match_id', matchId)
          .eq('receiver_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('id')
          .eq('receiver_id', userId)
          .eq('is_read', false)
          .count(CountOption.exact); // Move .count after filters

      return response.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get unread message count: $e');
    }
  }
}