import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit profile screen
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final profile = authProvider.userProfile;
          
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Photo
                CircleAvatar(
                  radius: 60,
                  backgroundImage: profile.profilePhotoUrl != null
                      ? NetworkImage(profile.profilePhotoUrl!)
                      : null,
                  child: profile.profilePhotoUrl == null
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
                const SizedBox(height: 16),
                
                // Name and Age
                Text(
                  '${profile.firstName} ${profile.lastName}, ${profile.age}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Bio
                if (profile.bio != null) ...[
                  Text(
                    profile.bio!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Interests
                if (profile.interests.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Interests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.interests.map((interest) {
                      return Chip(
                        label: Text(interest),
                        backgroundColor: Colors.pink[100],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Profile Stats
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStatRow('Gender', profile.gender),
                        const Divider(),
                        _buildStatRow('Member since', _formatDate(profile.createdAt)),
                        const Divider(),
                        _buildStatRow('Last active', _formatLastActive(profile.lastActive)),
                        const Divider(),
                        _buildStatRow('Verified', profile.isVerified ? 'Yes' : 'No'),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to settings
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showSignOutDialog(context, authProvider),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(value),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatLastActive(DateTime? lastActive) {
    if (lastActive == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(lastActive);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _showSignOutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}