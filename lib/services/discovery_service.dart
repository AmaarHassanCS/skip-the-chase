import 'package:skip_the_chase/models/check_in.dart';
import 'package:skip_the_chase/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DiscoveryService {
  final _supabase = Supabase.instance.client;

  Future<List<UserProfile>> getPotentialMatches({
    required String userId,
    double? latitude,
    double? longitude,
    List<CheckIn>? activeCheckIns,
  }) async {
    try {
      // Get user's preferences
      final userResponse = await _supabase
          .from('profiles')
          .select('preferences')
          .eq('id', userId)
          .single();
      
      final preferences = userResponse['preferences'] as Map<String, dynamic>?;
      
      // Build query based on location and preferences
      var query = _supabase.from('profiles').select();
      
      // Exclude current user
      query = query.neq('id', userId);
      
      // Exclude blocked users
      final blockedResponse = await _supabase
          .from('blocks')
          .select('blocked_user_id')
          .eq('user_id', userId);
      
      final blockedUserIds = blockedResponse.map((block) => block['blocked_user_id'] as String).toList();
      
      if (blockedUserIds.isNotEmpty) {
        query = query.not('id', 'in', blockedUserIds);
      }
      
      // Apply preferences if available
      if (preferences != null) {
        final minAge = preferences['min_age'] as int?;
        final maxAge = preferences['max_age'] as int?;
        
        if (minAge != null) {
          query = query.gte('age', minAge);
        }
        
        if (maxAge != null) {
          query = query.lte('age', maxAge);
        }
      }
      
      // Get potential matches
      final response = await query;
      
      List<UserProfile> potentialMatches = response.map((json) => UserProfile.fromJson(json)).toList();
      
      // If location is provided, prioritize users who are checked in nearby
      if (latitude != null && longitude != null && activeCheckIns != null && activeCheckIns.isNotEmpty) {
        // Get venue IDs where the user is checked in
        final venueIds = activeCheckIns.map((checkIn) => checkIn.venue.id).toList();
        
        // Get users checked in at the same venues
        final checkedInUsersResponse = await _supabase
            .from('check_ins')
            .select('user_id')
            .inFilter('venue_id', venueIds)
            .neq('user_id', userId)
            .gt('expires_at', DateTime.now().toIso8601String());
        
        final checkedInUserIds = checkedInUsersResponse.map((checkIn) => checkIn['user_id'] as String).toList();
        
        // Sort matches to prioritize checked-in users
        potentialMatches.sort((a, b) {
          final aIsCheckedIn = checkedInUserIds.contains(a.id);
          final bIsCheckedIn = checkedInUserIds.contains(b.id);
          
          if (aIsCheckedIn && !bIsCheckedIn) {
            return -1;
          } else if (!aIsCheckedIn && bIsCheckedIn) {
            return 1;
          }
          return 0;
        });
      }
      
      return potentialMatches;
    } catch (e) {
      throw Exception('Failed to get potential matches: $e');
    }
  }
}