import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skip_the_chase/models/venue.dart';
import 'package:skip_the_chase/models/check_in.dart';

class LocationProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  Position? _currentPosition;
  List<Venue> _nearbyVenues = [];
  List<CheckIn> _activeCheckIns = [];
  bool _isLoading = false;

  Position? get currentPosition => _currentPosition;
  List<Venue> get nearbyVenues => _nearbyVenues;
  List<CheckIn> get activeCheckIns => _activeCheckIns;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    await _determinePosition();
    if (_currentPosition != null) {
      await fetchNearbyVenues();
      await fetchActiveCheckIns();
    }
  }

  Future<void> _determinePosition() async {
    _isLoading = true;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      _currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNearbyVenues() async {
    if (_currentPosition == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      // In a real app, you would use a PostGIS query or similar to find venues within a radius
      // For simplicity, we'll fetch all venues and filter them client-side
      final response = await _supabase.from('venues').select();
      
      final venues = response.map((venue) => Venue.fromJson(venue)).toList();
      
      // Filter venues within 5km radius
      _nearbyVenues = venues.where((venue) {
        final distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          venue.latitude,
          venue.longitude,
        );
        return distance <= 5000; // 5km in meters
      }).toList();
    } catch (e) {
      debugPrint('Error fetching nearby venues: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchActiveCheckIns() async {
    if (_supabase.auth.currentUser == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser!.id;
      final now = DateTime.now().toIso8601String();
      
      final response = await _supabase
          .from('check_ins')
          .select('*, venues(*)')
          .eq('user_id', userId)
          .gt('expires_at', now);
      
      _activeCheckIns = response.map((checkIn) => CheckIn.fromJson(checkIn)).toList();
    } catch (e) {
      debugPrint('Error fetching active check-ins: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkInToVenue(String venueId, Duration duration) async {
    if (_currentPosition == null || _supabase.auth.currentUser == null) return false;
    
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser!.id;
      
      // Find the venue
      final venueResponse = await _supabase
          .from('venues')
          .select()
          .eq('id', venueId)
          .single();
      
      final venue = Venue.fromJson(venueResponse);
      
      // Verify user is within venue radius
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        venue.latitude,
        venue.longitude,
      );
      
      if (distance > venue.radius) {
        throw Exception('You are not within this venue\'s radius');
      }
      
      // Check if user already has active check-ins
      if (_activeCheckIns.isNotEmpty) {
        // Verify all active check-ins are within proximity
        for (final checkIn in _activeCheckIns) {
          final venueDistance = Geolocator.distanceBetween(
            venue.latitude,
            venue.longitude,
            checkIn.venue.latitude,
            checkIn.venue.longitude,
          );
          
          if (venueDistance > 500) { // 500m max distance between venues
            throw Exception('This venue is too far from your other active check-ins');
          }
        }
      }
      
      // Create check-in
      final now = DateTime.now();
      final expiresAt = now.add(duration);
      
      await _supabase.from('check_ins').insert({
        'user_id': userId,
        'venue_id': venueId,
        'checked_in_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
      });
      
      await fetchActiveCheckIns();
      return true;
    } catch (e) {
      debugPrint('Error checking in: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelCheckIn(String checkInId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase
          .from('check_ins')
          .delete()
          .eq('id', checkInId);
      
      await fetchActiveCheckIns();
      return true;
    } catch (e) {
      debugPrint('Error canceling check-in: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}