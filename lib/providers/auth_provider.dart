import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_profile.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _user = SupabaseService.currentUser;
    _loadUserProfile();
    
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      if (_user != null) {
        _loadUserProfile();
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile() async {
    if (_user != null) {
      try {
        _userProfile = await SupabaseService.getUserProfile(_user!.id);
      } catch (e) {
        _userProfile = null;
      }
      notifyListeners();
    }
  }

  Future<bool> signUp(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final response = await SupabaseService.signUpWithEmail(email, password);
      return response.user != null;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final response = await SupabaseService.signInWithEmail(email, password);
      return response.user != null;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      return await SupabaseService.signInWithGoogle();
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await SupabaseService.signOut();
    _user = null;
    _userProfile = null;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    try {
      await SupabaseService.resetPassword(email);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createProfile(UserProfile profile) async {
    try {
      _userProfile = await SupabaseService.createProfile(profile);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfile(UserProfile profile) async {
    try {
      _userProfile = await SupabaseService.updateProfile(profile);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}