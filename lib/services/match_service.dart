import 'package:skip_the_chase/models/match.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchService {
  final _supabase = Supabase.instance.client;

  Future<List<Match>> getMatches(String userId) async {
    try {
      final response = await _supabase
          .from('matches')
          .select('''
            *,
            profiles!matches_user2_id_fkey(*),
            last_message:messages(*)
          ''')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .order('created_at', ascending: false);
      
      return response.map<Match>((json) => Match.fromJson(json, userId)).toList();
    } catch (e) {
      throw Exception('Failed to get matches: $e');
    }
  }

  Future<bool> createMatch(String user1Id, String user2Id) async {
    try {
      // Check if match already exists
      final existingMatch = await _supabase
          .from('matches')
          .select()
          .or('and(user1_id.eq.$user1Id,user2_id.eq.$user2Id),and(user1_id.eq.$user2Id,user2_id.eq.$user1Id)')
          .maybeSingle();
      
      if (existingMatch != null) {
        return false; // Match already exists
      }
      
      // Create new match
      await _supabase.from('matches').insert({
        'user1_id': user1Id,
        'user2_id': user2Id,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      throw Exception('Failed to create match: $e');
    }
  }

  Future<void> unmatch(String matchId) async {
    try {
      // Delete all messages first
      await _supabase
          .from('messages')
          .delete()
          .eq('match_id', matchId);
      
      // Then delete the match
      await _supabase
          .from('matches')
          .delete()
          .eq('id', matchId);
    } catch (e) {
      throw Exception('Failed to unmatch: $e');
    }
  }
}