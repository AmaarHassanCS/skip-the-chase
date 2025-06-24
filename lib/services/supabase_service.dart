import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/venue.dart';
import '../models/check_in.dart';
import '../models/match.dart';
import '../models/message.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  static SupabaseClient get client => _client;
  
  // Auth methods
  static Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }
  
  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }
  
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  static Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(OAuthProvider.google);
  }
  
  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
  
  static User? get currentUser => _client.auth.currentUser;
  
  // Profile methods
  static Future<UserProfile?> getUserProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .single();
    
    return UserProfile.fromJson(response);
  }
  
  static Future<UserProfile> createProfile(UserProfile profile) async {
    final response = await _client
        .from('profiles')
        .insert(profile.toJson())
        .select()
        .single();
    
    return UserProfile.fromJson(response);
  }
  
  static Future<UserProfile> updateProfile(UserProfile profile) async {
    final response = await _client
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id)
        .select()
        .single();
    
    return UserProfile.fromJson(response);
  }
  
  // Venue methods
  static Future<List<Venue>> getNearbyVenues(double lat, double lng, double radiusKm) async {
    final response = await _client.rpc('get_nearby_venues', params: {
      'lat': lat,
      'lng': lng,
      'radius_km': radiusKm,
    });
    
    return (response as List).map((json) => Venue.fromJson(json)).toList();
  }
  
  // Check-in methods
  static Future<CheckIn> checkIn(CheckIn checkIn) async {
    final response = await _client
        .from('check_ins')
        .insert(checkIn.toJson())
        .select()
        .single();
    
    return CheckIn.fromJson(response);
  }
  
  static Future<void> checkOut(String checkInId) async {
    await _client
        .from('check_ins')
        .update({'check_out_time': DateTime.now().toIso8601String(), 'is_active': false})
        .eq('id', checkInId);
  }
  
  static Future<List<UserProfile>> getNearbyUsers(double lat, double lng, double radiusMeters) async {
    final response = await _client.rpc('get_nearby_checked_in_users', params: {
      'lat': lat,
      'lng': lng,
      'radius_meters': radiusMeters,
    });
    
    return (response as List).map((json) => UserProfile.fromJson(json)).toList();
  }
  
  // Swipe methods
  static Future<void> swipe(String swiperId, String swipedId, String direction, String? checkInId) async {
    await _client.from('swipes').insert({
      'swiper_id': swiperId,
      'swiped_id': swipedId,
      'direction': direction,
      'check_in_id': checkInId,
    });
  }
  
  static Future<List<UserProfile>> getSwipeableUsers(String userId, int limit) async {
    final response = await _client.rpc('get_swipeable_users', params: {
      'current_user_id': userId,
      'limit_count': limit,
    });
    
    return (response as List).map((json) => UserProfile.fromJson(json)).toList();
  }
  
  // Match methods
  static Future<List<Match>> getUserMatches(String userId) async {
    final response = await _client
        .from('matches')
        .select()
        .or('user1_id.eq.$userId,user2_id.eq.$userId')
        .eq('is_active', true)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Match.fromJson(json)).toList();
  }
  
  // Message methods
  static Future<List<Message>> getMatchMessages(String matchId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('match_id', matchId)
        .order('created_at', ascending: true);
    
    return (response as List).map((json) => Message.fromJson(json)).toList();
  }
  
  static Future<Message> sendMessage(String matchId, String senderId, String content) async {
    final response = await _client
        .from('messages')
        .insert({
          'match_id': matchId,
          'sender_id': senderId,
          'content': content,
        })
        .select()
        .single();
    
    return Message.fromJson(response);
  }
  
  static Future<void> markMessageAsRead(String messageId) async {
    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('id', messageId);
  }
  
  // Block/Report methods
  static Future<void> blockUser(String blockerId, String blockedId) async {
    await _client.from('blocks').insert({
      'blocker_id': blockerId,
      'blocked_id': blockedId,
    });
  }
  
  static Future<void> reportUser(String reporterId, String reportedId, String reason) async {
    await _client.from('reports').insert({
      'reporter_id': reporterId,
      'reported_id': reportedId,
      'reason': reason,
    });
  }
}