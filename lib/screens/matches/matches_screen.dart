import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/match.dart';
import '../../models/user_profile.dart';
import '../../services/supabase_service.dart';
import '../../providers/auth_provider.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<Match> _matches = [];
  Map<String, UserProfile> _profiles = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final matches = await SupabaseService.getUserMatches(authProvider.user!.id);
      
      final profileFutures = matches.map((match) async {
        final otherUserId = match.getOtherUserId(authProvider.user!.id);
        return await SupabaseService.getUserProfile(otherUserId);
      });
      
      final profiles = await Future.wait(profileFutures);
      final profileMap = <String, UserProfile>{};
      
      for (int i = 0; i < matches.length; i++) {
        if (profiles[i] != null) {
          profileMap[matches[i].getOtherUserId(authProvider.user!.id)] = profiles[i]!;
        }
      }
      
      setState(() {
        _matches = matches;
        _profiles = profileMap;
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
        title: const Text('Matches'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _matches.isEmpty
              ? _buildEmptyState()
              : _buildMatchesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No matches yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Start swiping to find your matches!'),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/swipe'),
            child: const Text('Start Swiping'),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesList() {
    return ListView.builder(
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final match = _matches[index];
        final authProvider = context.read<AuthProvider>();
        final otherUserId = match.getOtherUserId(authProvider.user!.id);
        final profile = _profiles[otherUserId];
        
        if (profile == null) return const SizedBox.shrink();
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: profile.profilePhotoUrl != null
                  ? NetworkImage(profile.profilePhotoUrl!)
                  : null,
              child: profile.profilePhotoUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text('${profile.firstName} ${profile.lastName}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Age: ${profile.age}'),
                if (match.isExpired)
                  const Text(
                    'Expired',
                    style: TextStyle(color: Colors.red),
                  )
                else
                  Text(
                    'Expires: ${_formatExpiryDate(match.expiresAt)}',
                    style: const TextStyle(color: Colors.orange),
                  ),
              ],
            ),
            trailing: match.isExpired
                ? const Icon(Icons.access_time, color: Colors.red)
                : const Icon(Icons.chat, color: Colors.pink),
            onTap: match.isExpired
                ? null
                : () => context.go('/chat/${match.id}'),
          ),
        );
      },
    );
  }

  String _formatExpiryDate(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes';
    } else {
      return 'Soon';
    }
  }
}