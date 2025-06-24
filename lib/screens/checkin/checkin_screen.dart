import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/venue.dart';
import '../../models/check_in.dart';
import '../../models/user_profile.dart';
import '../../services/supabase_service.dart';
import '../../providers/auth_provider.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  List<Venue> _nearbyVenues = [];
  List<UserProfile> _nearbyUsers = [];
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isCheckedIn = false;
  CheckIn? _currentCheckIn;
  int _selectedDuration = 60; // minutes

  final List<int> _durationOptions = [30, 60, 120, 180]; // minutes

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      await _loadNearbyVenues();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get location')),
      );
    }
  }

  Future<void> _loadNearbyVenues() async {
    if (_currentPosition == null) return;
    
    try {
      final venues = await SupabaseService.getNearbyVenues(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        1.0, // 1km radius
      );
      
      setState(() {
        _nearbyVenues = venues;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkInToVenue(Venue venue) async {
    if (_currentPosition == null) return;
    
    // Verify user is within 100 meters of venue
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      venue.latitude,
      venue.longitude,
    );
    
    if (distance > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be within 100 meters of the venue')),
      );
      return;
    }
    
    try {
      final authProvider = context.read<AuthProvider>();
      final checkIn = CheckIn(
        id: '',
        userId: authProvider.user!.id,
        venueId: venue.id,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        checkInTime: DateTime.now(),
        expectedDurationMinutes: _selectedDuration,
      );
      
      _currentCheckIn = await SupabaseService.checkIn(checkIn);
      
      setState(() => _isCheckedIn = true);
      
      await _loadNearbyUsers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checked in to ${venue.name}!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to check in')),
      );
    }
  }

  Future<void> _loadNearbyUsers() async {
    if (_currentPosition == null) return;
    
    try {
      final users = await SupabaseService.getNearbyUsers(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        100, // 100 meters
      );
      
      setState(() => _nearbyUsers = users);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _checkOut() async {
    if (_currentCheckIn == null) return;
    
    try {
      await SupabaseService.checkOut(_currentCheckIn!.id);
      setState(() {
        _isCheckedIn = false;
        _currentCheckIn = null;
        _nearbyUsers.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checked out successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to check out')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check In'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isCheckedIn
              ? _buildCheckedInView()
              : _buildVenuesList(),
    );
  }

  Widget _buildVenuesList() {
    if (_nearbyVenues.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No venues nearby',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Try moving to a different location'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('Duration: '),
              DropdownButton<int>(
                value: _selectedDuration,
                items: _durationOptions.map((duration) {
                  return DropdownMenuItem(
                    value: duration,
                    child: Text('${duration ~/ 60}h ${duration % 60}m'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedDuration = value!);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _nearbyVenues.length,
            itemBuilder: (context, index) {
              final venue = _nearbyVenues[index];
              final distance = _currentPosition != null
                  ? Geolocator.distanceBetween(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      venue.latitude,
                      venue.longitude,
                    )
                  : 0.0;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(_getVenueIcon(venue.venueType)),
                  ),
                  title: Text(venue.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(venue.address),
                      Text('${distance.round()}m away'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _checkInToVenue(venue),
                    child: const Text('Check In'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCheckedInView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.green[100],
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 8),
              const Text(
                'You\'re checked in!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_currentCheckIn != null)
                Text(
                  'Until ${_formatTime(_currentCheckIn!.expectedCheckOutTime)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkOut,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Check Out'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _nearbyUsers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No one else is here right now',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Check back later or try a different venue!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _nearbyUsers.length,
                  itemBuilder: (context, index) {
                    final user = _nearbyUsers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.profilePhotoUrl != null
                              ? NetworkImage(user.profilePhotoUrl!)
                              : null,
                          child: user.profilePhotoUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text('${user.firstName}, ${user.age}'),
                        subtitle: user.bio != null ? Text(user.bio!) : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _swipeUser(user, 'left'),
                              icon: const Icon(Icons.close, color: Colors.grey),
                            ),
                            IconButton(
                              onPressed: () => _swipeUser(user, 'right'),
                              icon: const Icon(Icons.favorite, color: Colors.pink),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  IconData _getVenueIcon(String venueType) {
    switch (venueType.toLowerCase()) {
      case 'cafe':
      case 'coffee':
        return Icons.local_cafe;
      case 'restaurant':
        return Icons.restaurant;
      case 'bar':
        return Icons.local_bar;
      case 'shop':
      case 'shopping':
        return Icons.shopping_bag;
      case 'gym':
        return Icons.fitness_center;
      case 'park':
        return Icons.park;
      default:
        return Icons.place;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _swipeUser(UserProfile user, String direction) async {
    final authProvider = context.read<AuthProvider>();
    
    try {
      await SupabaseService.swipe(
        authProvider.user!.id,
        user.userId,
        direction,
        _currentCheckIn?.id,
      );
      
      setState(() {
        _nearbyUsers.remove(user);
      });
      
      if (direction == 'right') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You liked ${user.firstName}!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to swipe')),
      );
    }
  }
}