import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skip_the_chase/models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  UserProfile? _userProfile;
  bool _isLoading = false;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _fetchUserProfile(user.id);
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      _userProfile = UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  Future<bool> signUpWithEmail(String email, String password, String name, DateTime birthDate) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final userId = response.user!.id;
        
        // Calculate age from birthDate
        final now = DateTime.now();
        final age = now.year - birthDate.year - 
            (now.month > birthDate.month || 
            (now.month == birthDate.month && now.day >= birthDate.day) ? 0 : 1);
        
        // Create user profile
        await _supabase.from('profiles').insert({
          'id': userId,
          'name': name,
          'age': age,
          'birth_date': birthDate.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        });
        
        await _fetchUserProfile(userId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error signing up: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _fetchUserProfile(response.user!.id);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error signing in: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.skipthechase://login-callback/',
      );
      return true;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.auth.signOut();
      _userProfile = null;
    } catch (e) {
      debugPrint('Error signing out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? bio,
    String? avatarUrl,
    List<String>? interests,
    Map<String, dynamic>? preferences,
  }) async {
    if (_userProfile == null) return false;
    
    _isLoading = true;
    notifyListeners();

    try {
      final updates = {
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (interests != null) 'interests': interests,
        if (preferences != null) 'preferences': preferences,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', _userProfile!.id);
      
      await _fetchUserProfile(_userProfile!.id);
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}