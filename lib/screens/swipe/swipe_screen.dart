import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../services/supabase_service.dart';
import '../../providers/auth_provider.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  final CardSwiperController _controller = CardSwiperController();
  List<UserProfile> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final profiles = await SupabaseService.getSwipeableUsers(
        authProvider.user!.id,
        10,
      );
      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profiles.isEmpty
              ? _buildEmptyState()
              : _buildSwipeCards(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No more profiles to show',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Check back later for new people!'),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _loadProfiles,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeCards() {
    return Column(
      children: [
        Expanded(
          child: CardSwiper(
            controller: _controller,
            cardsCount: _profiles.length,
            onSwipe: _onSwipe,
            cardBuilder: (context, index, horizontalThreshold, verticalThreshold) {
              return _buildProfileCard(_profiles[index]);
            },
          ),
        ),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildProfileCard(UserProfile profile) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Profile image
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: profile.profilePhotoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: profile.profilePhotoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.person, size: 64),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 64),
                    ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            // Profile info
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${profile.firstName}, ${profile.age}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (profile.bio != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      profile.bio!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (profile.interests.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: profile.interests.take(3).map((interest) {
                        return Chip(
                          label: Text(
                            interest,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          labelStyle: const TextStyle(color: Colors.white),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            onPressed: () => _controller.swipe(CardSwiperDirection.left),
            backgroundColor: Colors.grey,
            child: const Icon(Icons.close, color: Colors.white),
          ),
          FloatingActionButton(
            onPressed: () => _controller.swipe(CardSwiperDirection.right),
            backgroundColor: Colors.pink,
            child: const Icon(Icons.favorite, color: Colors.white),
          ),
        ],
      ),
    );
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    final profile = _profiles[previousIndex];
    final authProvider = context.read<AuthProvider>();
    
    SupabaseService.swipe(
      authProvider.user!.id,
      profile.userId,
      direction == CardSwiperDirection.right ? 'right' : 'left',
      null,
    );

    if (direction == CardSwiperDirection.right) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You liked ${profile.firstName}!'),
          duration: const Duration(seconds: 1),
        ),
      );
    }

    // Load more profiles when running low
    if (currentIndex != null && currentIndex >= _profiles.length - 2) {
      _loadProfiles();
    }

    return true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}