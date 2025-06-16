import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import 'package:skip_the_chase/models/user_profile.dart';
import 'package:skip_the_chase/providers/auth_provider.dart';
import 'package:skip_the_chase/providers/location_provider.dart';
import 'package:skip_the_chase/services/discovery_service.dart';
import 'package:skip_the_chase/widgets/profile_card.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final CardSwiperController _cardController = CardSwiperController();
  List<UserProfile> _potentialMatches = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPotentialMatches();
  }

  Future<void> _loadPotentialMatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // In a real app, you would use a dedicated service for this
      // For now, we'll just simulate it
      final discoveryService = DiscoveryService();
      final locationProvider = Provider.of<LocationProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (locationProvider.currentPosition != null) {
        _potentialMatches = await discoveryService.getPotentialMatches(
          userId: authProvider.userProfile!.id,
          latitude: locationProvider.currentPosition!.latitude,
          longitude: locationProvider.currentPosition!.longitude,
          activeCheckIns: locationProvider.activeCheckIns,
        );
      } else {
        _potentialMatches = await discoveryService.getPotentialMatches(
          userId: authProvider.userProfile!.id,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load potential matches: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _onSwipe(int currentIndex, int? previousIndex, CardSwiperDirection direction) async {
    // Your existing swipe logic here
    print("Swiped card at index $currentIndex to $direction");
    // Return true to allow the swipe, or false to prevent it
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPotentialMatches,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _potentialMatches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No more profiles to show',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadPotentialMatches,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: CardSwiper(
                            controller: _cardController,
                            cardsCount: _potentialMatches.length,
                            onSwipe: _onSwipe,
                            numberOfCardsDisplayed: 3,
                            backCardOffset: const Offset(40, 40),
                            padding: const EdgeInsets.all(24.0),
                            cardBuilder: (
                              context,
                              index,
                              horizontalThresholdPercentage,
                              verticalThresholdPercentage,
                            ) =>
                                ProfileCard(profile: _potentialMatches[index]),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              FloatingActionButton(
                                onPressed: () {
                                  _cardController.swipeLeft();
                                },
                                backgroundColor: Colors.red,
                                child: const Icon(Icons.close),
                              ),
                              FloatingActionButton(
                                onPressed: () {
                                  _cardController.swipeRight();
                                },
                                backgroundColor: Colors.green,
                                child: const Icon(Icons.favorite),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
    );
  }
}